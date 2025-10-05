/// Represents the API response.
class APIResponse {
  final List<Choice> choices;

  APIResponse({required this.choices});
}

/// Represents a choice in the API response.
class Choice {
  final Message message;

  Choice({required this.message});
}

/// Represents a message in the conversation.
class Message {
  // TODO(dantup): Make this an enum.
  final String role;

  final String? content;
  // TODO(dantup): Make this a sealed class with sub-classes for each kind of message.
  final String? toolCallId;
  final List<ToolCall>? toolCalls;

  Message({required this.role, this.content, this.toolCallId, this.toolCalls});
}

/// Represents a tool call.
class ToolCall {
  final String id;
  final ToolFunctionCall function;

  ToolCall({required this.id, required this.function});
}

/// Represents a tool definition.
class ToolDefinition {
  final String type;
  final ToolFunction function;

  ToolDefinition({required this.type, required this.function});
}

/// Represents a tool function.
class ToolFunction {
  final String name;
  final String? description;
  final Map<String, Object?>? parameters;

  ToolFunction({required this.name, this.description, this.parameters});
}

/// Represents a tool function call.
class ToolFunctionCall {
  final String name;
  final Map<String, Object?>? arguments;

  ToolFunctionCall({required this.name, this.arguments});
}
