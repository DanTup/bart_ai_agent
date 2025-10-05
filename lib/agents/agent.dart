import 'dart:async';
import 'dart:convert';

import 'package:bart/api/client.dart';
import 'package:bart/api/types.dart' as api;
import 'package:bart/output_message.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

/// A base class for agents that interact with LLMs.
abstract class Agent {
  @protected
  final log = Logger('Agent');

  @protected
  final jsonEncode = const JsonEncoder.withIndent('    ').convert;

  /// A client for accessing an LLM.
  final ApiClient client;

  /// The system message to be included when accessing the LLM.
  final String? systemMessage;

  /// Marks that the agent is working.
  ///
  /// This may show some kind of progress indicator/spinner to the user.
  void startWorking(String reason);

  /// Marks that the agent is no longer working.
  void stopWorking();

  /// Shows output to the user.
  void showOutput(OutputMessage message);

  /// Waits for an input message from the user.
  FutureOr<String?> getUserMessage();

  Agent({
    required this.client,
    this.systemMessage,
  });

  /// Runs the main agent loop, handling user input and LLM responses.
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

    // User input loop.
    while (true) {
      final input = await getUserMessage();
      if (input == null || input.isEmpty || input.trim().toLowerCase() == '/exit') {
        break;
      }
      messages.add(api.Message(role: 'user', content: input));

      final response = await client.callAPI(messages);

      final choice = response.choices[0];
      final assistantMessage = choice.message;

      messages.add(assistantMessage);
      showOutput(AssistantMessage(assistantMessage.content ?? ''));
    }
  }
}
