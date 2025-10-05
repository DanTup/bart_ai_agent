import 'dart:convert';

import 'package:bart/api/client.dart';
import 'package:bart/api/types.dart';
import 'package:file/file.dart';
import 'package:test_api/src/backend/invoker.dart';

/// A test client that can either record real API responses or replay captured ones.
///
/// When [mode] is [TestMode.useSnapshots], it loads saved responses.
/// When [mode] is [TestMode.useLlm], it uses the real API without saving.
/// When [mode] is [TestMode.recordSnapshots], it uses the real API and saves responses.
class TestApiClient implements ApiClient {
  final ApiClient? realClient;
  final Directory dataDirectory;
  final TestMode mode;
  final String conversationId;

  var _toolCallIndex = 1;
  var _callIndex = 0;

  TestApiClient({
    this.realClient,
    required this.dataDirectory,
    required this.mode,
    String? conversationId,
  }) : conversationId = (conversationId ?? Invoker.current!.liveTest.test.name)
           .toLowerCase()
           .replaceAll(
             RegExp('[^a-z0-9]+'),
             '_',
           );

  @override
  Future<APIResponse> callAPI(
    List<Message> messages,
    List<ToolDefinition> tools,
  ) async {
    if (mode == TestMode.useSnapshots) {
      // Load and validate the conversation
      return _loadAndValidateResponse(messages, _callIndex++);
    } else {
      // Use real API
      final response = await realClient!.callAPI(messages, tools);
      if (mode == TestMode.recordSnapshots) {
        _saveResponse(_callIndex++, messages, response);
      }
      return response;
    }
  }

  APIResponse _normalizeResponse(APIResponse response) {
    return APIResponse(
      choices: response.choices.map((choice) {
        return Choice(
          message: Message(
            role: choice.message.role,
            content: choice.message.content,
            toolCallId: choice.message.toolCallId,
            toolCalls: choice.message.toolCalls?.map((toolCall) {
              return ToolCall(
                id: 'toolCall_${_toolCallIndex++}',
                function: toolCall.function,
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  void _saveResponse(int callIndex, List<Message> messages, APIResponse response) {
    final file = dataDirectory.childFile('$conversationId.json');
    file.parent.createSync(recursive: true);

    // Reset tool call index for deterministic IDs
    _toolCallIndex = 1;

    // Create the full conversation: all input messages + the new response
    final conversation = <Map<String, Object?>>[];

    // Add all input messages
    for (final message in messages) {
      conversation.add(_messageToJson(_normalizeMessage(message)));
    }

    // Add the assistant response
    final normalizedResponse = _normalizeResponse(response);
    conversation.add(_messageToJson(normalizedResponse.choices.first.message));

    final json = {'messages': conversation};
    const encoder = JsonEncoder.withIndent('\t');
    file.writeAsStringSync(encoder.convert(json));
  }

  APIResponse _loadAndValidateResponse(List<Message> incomingMessages, int callIndex) {
    final file = dataDirectory.childFile('$conversationId.json');
    if (!file.existsSync()) {
      throw StateError(
        'No saved conversation found for conversationId: $conversationId in "${file.path}"',
      );
    }
    final json = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
    final storedMessagesJson = json['messages']! as List<Object?>;

    // Reset tool call index for normalization
    _toolCallIndex = 1;

    // Normalize incoming messages for comparison
    final normalizedIncomingMessages = incomingMessages.map(_normalizeMessage).toList();

    if (normalizedIncomingMessages.length > storedMessagesJson.length) {
      throw Exception(
        'Incoming message count (${normalizedIncomingMessages.length}) exceeds stored conversation length (${storedMessagesJson.length}) in "$conversationId"',
      );
    }

    for (var i = 0; i < normalizedIncomingMessages.length; i++) {
      final incomingMessage = normalizedIncomingMessages[i];
      final storedMessageJson = storedMessagesJson[i]! as Map<String, Object?>;
      final storedMessage = _messageFromJson(storedMessageJson);

      if (incomingMessage.role != storedMessage.role) {
        throw Exception(
          'Message role mismatch at position $i in conversation "$conversationId". '
          'Expected: ${storedMessage.role}, Got: ${incomingMessage.role}',
        );
      }

      if (incomingMessage.role == 'user') {
        // For user messages, validate content matches
        if (incomingMessage.content != storedMessage.content) {
          throw Exception(
            'User message content mismatch at position $i in conversation "$conversationId". '
            'Expected: ${storedMessage.content}, Got: ${incomingMessage.content}',
          );
        }
      } else if (incomingMessage.role == 'tool') {
        // For tool messages, validate toolCallId matches but allow content to differ
        // (content may contain dynamic paths or other runtime-specific data)
        if (incomingMessage.toolCallId != storedMessage.toolCallId) {
          throw Exception(
            'Tool message toolCallId mismatch at position $i in conversation "$conversationId". '
            'Expected: ${storedMessage.toolCallId}, Got: ${incomingMessage.toolCallId}',
          );
        }
      }
      // For assistant messages, we don't validate content since that's what we're replaying
    }

    // Find the next assistant message after the incoming messages
    for (var i = normalizedIncomingMessages.length; i < storedMessagesJson.length; i++) {
      final storedMessageJson = storedMessagesJson[i]! as Map<String, Object?>;
      final storedMessage = _messageFromJson(storedMessageJson);
      if (storedMessage.role == 'assistant') {
        return APIResponse(choices: [Choice(message: storedMessage)]);
      }
    }

    throw Exception(
      'No assistant response found after ${normalizedIncomingMessages.length} messages in conversation "$conversationId"',
    );
  }

  Map<String, Object?> _messageToJson(Message message) {
    return {
      'role': message.role,
      'content': message.content,
      'toolCallId': message.toolCallId,
      'toolCalls': message.toolCalls
          ?.map(
            (toolCall) => {
              'id': toolCall.id,
              'function': {
                'name': toolCall.function.name,
                'arguments': toolCall.function.arguments,
              },
            },
          )
          .toList(),
    };
  }

  Message _messageFromJson(Map<String, Object?> json) {
    final toolCallsJson = (json['toolCalls'] as List<Object?>?)?.cast<Map<String, Object?>>();
    return Message(
      role: json['role']! as String,
      content: json['content'] as String?,
      toolCallId: json['toolCallId'] as String?,
      toolCalls: toolCallsJson?.map((toolCallJson) {
        final functionJson = toolCallJson['function']! as Map<String, Object?>;
        return ToolCall(
          id: toolCallJson['id']! as String,
          function: ToolFunctionCall(
            name: functionJson['name']! as String,
            arguments: functionJson['arguments'] as Map<String, Object?>?,
          ),
        );
      }).toList(),
    );
  }

  Message _normalizeMessage(Message message) {
    return Message(
      role: message.role,
      content: message.content,
      toolCallId: message.toolCallId != null ? 'toolCall_${_toolCallIndex++}' : null,
      toolCalls: message.toolCalls?.map((toolCall) {
        return ToolCall(
          id: 'toolCall_${_toolCallIndex++}',
          function: toolCall.function,
        );
      }).toList(),
    );
  }
}

/// Modes for the test client behavior.
enum TestMode {
  /// Use saved snapshots for responses.
  useSnapshots,

  /// Use the real LLM API without saving responses.
  useLlm,

  /// Use the real API and save responses as snapshots for future runs.
  recordSnapshots,
}
