sealed class OutputMessage {}

class SystemOutput extends OutputMessage {
  final String content;

  SystemOutput(this.content);
}

class AssistantMessage extends OutputMessage {
  final String content;

  AssistantMessage(this.content);
}
