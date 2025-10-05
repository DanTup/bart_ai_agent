import 'package:bart/tools/todo/todo_tool.dart';

sealed class OutputMessage {}

class SystemOutput extends OutputMessage {
  final String content;

  SystemOutput(this.content);
}

class AssistantMessage extends OutputMessage {
  final String content;

  AssistantMessage(this.content);
}

class ToolCall extends OutputMessage {
  final String toolName;

  ToolCall(this.toolName);
}

class TodoListUpdate extends OutputMessage {
  final TodoList todoList;

  TodoListUpdate(this.todoList);
}
