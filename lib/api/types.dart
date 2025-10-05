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

  Message({required this.role, this.content});
}
