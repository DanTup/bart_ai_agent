import 'dart:async';
import 'dart:convert';

import 'package:bart/api/client.dart';
import 'package:bart/api/types.dart' as api;
import 'package:bart/output_message.dart';
import 'package:bart/tools/tool.dart';
import 'package:bart/tools/tool_context.dart';
import 'package:file/file.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

/// A base class for agents that interact with LLMs and execute tools.
abstract class Agent {
  @protected
  final log = Logger('Agent');

  @protected
  final jsonEncode = const JsonEncoder.withIndent('\t').convert;

  /// A client for accessing an LLM.
  final ApiClient client;

  /// The system message to be included when accessing the LLM.
  final String? systemMessage;

  /// The available tools that can be used by the LLM.
  final List<Tool> tools;

  /// The filesystem to use for file operations.
  final FileSystem fileSystem;

  /// Marks that the agent is working.
  ///
  /// This may show some kind of progress indicator/spinner to the user.
  void startWorking(String reason);

  /// Marks that the agent is no longer working.
  void stopWorking();

  /// Directories that are allowed to be read/modified.
  Set<Directory> get allowedDirectories;

  /// Shows output to the user.
  ///
  /// Different kinds of output may be rendered differently (for example
  /// assistant messages will be expanded but tool calls may be collapsed).
  void showOutput(OutputMessage message);

  /// Waits for an input message from the user.
  FutureOr<String?> getUserMessage();

  Agent({
    required this.client,
    this.systemMessage,
    required this.tools,
    required this.fileSystem,
  });

  /// Runs the main agent loop, handling user input, LLM responses and tool
  /// execution.
  Future<void> run({String? initialUserMessage}) async {
    // TODO(dantup): Implement slash-commands and replace this hard-coded text
    //  (and the corresponding implemnetation).
    showOutput(
      SystemOutput('Agent started. Type your messages. Type "/exit" to quit.'),
    );

    final messages = <api.Message>[
      if (systemMessage != null) api.Message(role: 'system', content: systemMessage),
      if (initialUserMessage != null) api.Message(role: 'user', content: initialUserMessage),
    ];

    final toolDefinitions = tools.map((tool) => tool.definition).toList();

    // User input loop.
    while (true) {
      final input = await getUserMessage();
      if (input == null || input.isEmpty || input.trim().toLowerCase() == '/exit') {
        break;
      }
      messages.add(api.Message(role: 'user', content: input));

      // Agent tool loop.
      while (true) {
        startWorking('Working');
        final response = await client.callAPI(messages, toolDefinitions);
        stopWorking();

        final choice = response.choices[0];
        final assistantMessage = choice.message;

        messages.add(assistantMessage);
        showOutput(AssistantMessage(assistantMessage.content ?? ''));

        final toolCalls = assistantMessage.toolCalls;
        if (toolCalls != null) {
          for (final toolCall in toolCalls) {
            final name = toolCall.function.name;
            final arguments = toolCall.function.arguments ?? {};
            showOutput(ToolCall(name));
            startWorking('Executing tool $name');
            log.fine('Executing tool $name: ${jsonEncode(arguments)}');
            final result = _executeTool(name, arguments);
            log.fine('Tool returned: ${jsonEncode(result)}');
            stopWorking();

            messages.add(
              api.Message(
                role: 'tool',
                toolCallId: toolCall.id,
                content: result.toString(),
              ),
            );
          }

          // Continue the agent loop.
          continue;
        }

        // Break out to the user loop.
        break;
      }
    }
  }

  Object? _executeTool(String name, Map<String, Object?> arguments) {
    final tool = tools.firstWhere(
      (t) => t.name == name,
      orElse: () => throw ToolException('Unknown tool "$name"'),
    );
    try {
      return tool.execute(
        arguments,
        ToolContext(allowedDirectories: allowedDirectories),
      );
    } on Exception catch (e) {
      return e.toString();
    }
  }
}
