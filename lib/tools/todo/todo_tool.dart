import 'package:bart/output_message.dart';
import 'package:bart/tools/tool.dart';
import 'package:bart/tools/tool_context.dart';
import 'package:bart/tools/tool_schema.dart';
import 'package:collection/collection.dart';

/// Tool that allows the agent to manage a list of TODO items.
class TodoTool extends Tool {
  final todoList = TodoList();

  @override
  String get name => 'todo';

  @override
  String get description =>
      'Create and update a TODO list to keep track of your tasks and let the user see your progress as you work.';

  @override
  ToolParameters get parameters => const ToolParameters({
    'operation': Parameter.string(
      description: 'The operation to perform on the TODO list.',
      required: true,
      enumValues: ['add', 'complete', 'remove', 'list', 'clear'],
    ),
    'task': Parameter.string(
      description:
          'Task description. When completing or removing, provide the exact text previously added.',
    ),
  });

  @override
  Object? execute(Map<String, Object?> arguments, ToolContext context) {
    final operation = (arguments['operation']! as String).toLowerCase();
    final taskText = (arguments['task'] as String?)?.trim();

    try {
      switch (operation) {
        case 'add':
          todoList._add(taskText);
          return 'Added task "$taskText".';
        case 'complete':
          todoList._complete(taskText);
          return 'Completed task "$taskText".';
        case 'remove':
          todoList._remove(taskText);
          return 'Removed task "$taskText".';
        case 'list':
          return todoList.formattedTodoList;
        case 'clear':
          todoList._clear();
          return 'Cleared TODO list.';
        default:
          throw ToolException('Unsupported operation: $operation');
      }
    } finally {
      context.showOutput(TodoListUpdate(todoList));
    }
  }
}

class TodoList {
  final List<TodoTask> _tasks = [];

  TodoTask _findTask(String? maybeTaskText) {
    final taskText = _taskText(maybeTaskText);
    return _tasks.firstWhereOrNull((t) => t.task == taskText) ??
        (throw ToolException('Could not find task "$taskText".'));
  }

  String _taskText(String? taskText) {
    if (taskText == null || taskText.isEmpty) {
      throw ToolException('A task description must be provided.');
    }
    return taskText;
  }

  void _add(String? taskText) {
    _tasks.add(TodoTask(_taskText(taskText)));
  }

  void _complete(String? taskText) {
    _findTask(taskText)._complete();
  }

  void _remove(String? taskText) {
    _tasks.remove(_findTask(taskText));
  }

  void _clear() {
    _tasks.clear();
  }

  String get formattedTodoList {
    if (_tasks.isEmpty) {
      return 'TODO list is empty.';
    }

    final buffer = StringBuffer()..writeln('Current TODO list:');
    for (final task in _tasks) {
      buffer
        ..write('- ')
        ..write(task.isComplete ? '✓ ' : '○ ')
        ..writeln(task.task);
    }

    return buffer.toString();
  }

  List<TodoTask> get tasks => List.unmodifiable(_tasks);
}

class TodoTask {
  final String task;

  var _isComplete = false;
  bool get isComplete => _isComplete;

  TodoTask(this.task);

  void _complete() => _isComplete = true;
}
