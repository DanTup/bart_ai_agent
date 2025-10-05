import 'dart:convert' show JsonEncoder, jsonDecode;

import 'package:bart/api/client.dart';
import 'package:bart/api/types.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

final _log = Logger('OpenAIClient');

/// A client for interacting with an implementation of the OpenAI API.
class OpenAIClient implements ApiClient {
  final String apiUrl, apiKey, model;

  final jsonEncode = const JsonEncoder.withIndent('    ').convert;

  OpenAIClient({
    required this.apiUrl,
    required this.apiKey,
    required this.model,
  });

  @override
  Future<APIResponse> callAPI(
    List<Message> messages,
    List<ToolDefinition> tools,
  ) async {
    _log.info('Calling LLM API');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };
    final body = {
      'model': model,
      'messages': messages.map(_messageToJson).toList(),
      'tools': tools.map(_toolDefinitionToJson).toList(),
    };

    // Log the request
    _logRequest(apiUrl, headers, body);

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: headers,
      body: jsonEncode(body),
    );
    _logResponse(response.statusCode, response.headers, response.body);

    if (response.statusCode == 200) {
      try {
        final jsonResponse = jsonDecode(response.body) as Map<String, Object?>;
        return _jsonToAPIResponse(jsonResponse);
      } catch (e) {
        _log.severe('Failed to parse response: $e\nBody: ${response.body}');
        rethrow;
      }
    } else {
      throw Exception(
        'Failed to call API: ${response.statusCode} ${response.body}',
      );
    }
  }

  void _logRequest(
    // TODO(dantup): Logging should be in the base client.
    String url,
    Map<String, String> headers,
    Map<String, Object?> body,
  ) {
    _log.finer('''
==> URL: $url
==> Headers: ${jsonEncode(headers).split('\n').join('\n             ')}
==> Body: ${jsonEncode(body).split('\n').join('\n          ')}
''');
  }

  void _logResponse(int statusCode, Map<String, String> headers, String body) {
    _log.finer('''
<== Status: $statusCode
<== Headers: ${jsonEncode(headers).split('\n').join('\n             ')}
<== Body: ${body.split('\n').join('\n          ')}
''');
  }

  Map<String, Object?> _messageToJson(Message message) {
    return {
      'role': message.role,
      if (message.content != null) 'content': message.content,
      if (message.toolCallId != null) 'tool_call_id': message.toolCallId,
      if (message.toolCalls != null) 'tool_calls': message.toolCalls!.map(_toolCallToJson).toList(),
    };
  }

  Map<String, Object?> _toolCallToJson(ToolCall toolCall) {
    return {
      'id': toolCall.id,
      'function': _toolFunctionCallToJson(toolCall.function),
    };
  }

  Map<String, Object?> _toolFunctionCallToJson(
    ToolFunctionCall toolFunctionCall,
  ) {
    return {
      'name': toolFunctionCall.name,
      if (toolFunctionCall.arguments != null) 'arguments': jsonEncode(toolFunctionCall.arguments),
    };
  }

  Map<String, Object?> _toolFunctionDefinitionToJson(
    ToolFunction toolFunction,
  ) {
    return {
      'name': toolFunction.name,
      'description': toolFunction.description,
      'parameters': toolFunction.parameters,
    };
  }

  Map<String, Object?> _toolDefinitionToJson(ToolDefinition toolDefinition) {
    return {
      'type': toolDefinition.type,
      'function': _toolFunctionDefinitionToJson(toolDefinition.function),
    };
  }

  APIResponse _jsonToAPIResponse(Map<String, Object?> json) {
    return APIResponse(
      choices: (json['choices']! as List).cast<Map<String, Object?>>().map(_jsonToChoice).toList(),
    );
  }

  Choice _jsonToChoice(Map<String, Object?> json) {
    return Choice(
      message: _jsonToMessage(json['message']! as Map<String, Object?>),
    );
  }

  Message _jsonToMessage(Map<String, Object?> json) {
    return Message(
      role: json['role']! as String,
      content: json['content'] as String?,
      toolCallId: json['tool_call_id'] as String?,
      toolCalls: json['tool_calls'] != null
          ? (json['tool_calls']! as List).cast<Map<String, Object?>>().map(_jsonToToolCall).toList()
          : null,
    );
  }

  ToolCall _jsonToToolCall(Map<String, Object?> json) {
    return ToolCall(
      id: json['id']! as String,
      function: _jsonToToolFunctionCall(
        json['function']! as Map<String, Object?>,
      ),
    );
  }

  ToolFunctionCall _jsonToToolFunctionCall(Map<String, Object?> json) {
    return ToolFunctionCall(
      name: json['name']! as String,
      arguments: switch (json['arguments'] as String?) {
        (final String argumentsJson) => jsonDecode(argumentsJson) as Map<String, Object?>?,
        null => null,
      },
    );
  }
}
