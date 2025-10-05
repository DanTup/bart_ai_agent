import 'package:bart/api/client.dart';
import 'package:bart/api/types.dart';
import 'package:logging/logging.dart';

final _log = Logger('CannedResponseClient');

/// A client that provides canned responses based on simple string matching
///
/// This is used for basic testing without a real LLM.
class CannedResponseClient implements ApiClient {
  final _cannedResponses = [
    // Task operations.
    _CannedResponse(
      RegExp('(create|add).*(todo|task)', caseSensitive: false),
      () => _createTodoResponse('add', 'Sample task'),
    ),
    _CannedResponse(
      RegExp('(complete|finish|done).*(todo|task)', caseSensitive: false),
      () => _createTodoResponse('complete', 'Sample task'),
    ),
    _CannedResponse(
      RegExp('(remove|delete).*(todo|task)', caseSensitive: false),
      () => _createTodoResponse('remove', 'Sample task'),
    ),
    _CannedResponse(
      RegExp('(list|show).*(todo|task)', caseSensitive: false),
      () => _createTodoResponse('list'),
    ),
    _CannedResponse(
      RegExp('clear.*(todo|task)', caseSensitive: false),
      () => _createTodoResponse('clear'),
    ),

    // File operations.
    _CannedResponse(
      RegExp('create.*file', caseSensitive: false),
      () => _createFileResponse('create_file', {
        'file_path': 'sample.txt',
        'content': 'Sample file content created via canned response',
      }),
    ),
    _CannedResponse(
      RegExp('read.*file', caseSensitive: false),
      () => _createFileResponse('read_file', {'file_path': 'sample.txt'}),
    ),
    _CannedResponse(
      RegExp('edit.*file', caseSensitive: false),
      () => _createFileResponse('edit_file', {
        'file_path': 'sample.txt',
        'old_string': 'Sample file content',
        'new_string': 'Modified content via canned response',
      }),
    ),
    _CannedResponse(
      RegExp('delete.*file', caseSensitive: false),
      () => _createFileResponse('delete_file', {'file_path': 'sample.txt'}),
    ),
  ];

  @override
  Future<APIResponse> callAPI(
    List<Message> messages,
    List<ToolDefinition> tools,
  ) async {
    final lastMessage = messages.lastOrNull;

    return switch (lastMessage?.role) {
      'user' => _generateCannedResponse(lastMessage!.content?.toLowerCase() ?? ''),
      'tool' => _handleToolResult(lastMessage!),
      _ => _createFallbackResponse(),
    };
  }

  /// Generates a canned response based on the user input.
  APIResponse _generateCannedResponse(String userInput) {
    for (final canned in _cannedResponses) {
      if (canned.pattern.hasMatch(userInput)) {
        return canned.generator();
      }
    }
    return _createFallbackResponse();
  }

  /// Creates a fallback response when no canned pattern matches.
  static APIResponse _createFallbackResponse() {
    return APIResponse(
      choices: [
        Choice(
          message: Message(
            role: 'assistant',
            content:
                "I'm not a real LLM so I can't do much.\n\n"
                "Try asking me to 'create a todo', 'list todos', 'create a file', 'read a file', etc.",
          ),
        ),
      ],
    );
  }

  /// Creates a response for todo operations.
  static APIResponse _createTodoResponse(String operation, [String? task]) {
    final arguments = {'operation': operation};
    if (task != null) {
      arguments['task'] = task;
    }

    final toolCall = ToolCall(
      id: 'canned_${DateTime.now().millisecondsSinceEpoch}',
      function: ToolFunctionCall(
        name: 'todo',
        arguments: arguments,
      ),
    );

    return APIResponse(
      choices: [
        Choice(
          message: Message(
            role: 'assistant',
            content: '',
            toolCalls: [toolCall],
          ),
        ),
      ],
    );
  }

  /// Creates a response for file operations.
  static APIResponse _createFileResponse(String toolName, Map<String, Object?> arguments) {
    final toolCall = ToolCall(
      id: 'canned_${DateTime.now().millisecondsSinceEpoch}',
      function: ToolFunctionCall(
        name: toolName,
        arguments: arguments,
      ),
    );

    return APIResponse(
      choices: [
        Choice(
          message: Message(
            role: 'assistant',
            content: '',
            toolCalls: [toolCall],
          ),
        ),
      ],
    );
  }

  /// Handles a tool result message and creates a response informing the user.
  static APIResponse _handleToolResult(Message toolMessage) {
    final content = toolMessage.content ?? 'Tool executed successfully.';
    return APIResponse(
      choices: [
        Choice(
          message: Message(
            role: 'assistant',
            content: 'Tool result: $content',
          ),
        ),
      ],
    );
  }
}

/// Represents a canned response pattern and its generator.
class _CannedResponse {
  final RegExp pattern;
  final APIResponse Function() generator;

  _CannedResponse(this.pattern, this.generator);
}
