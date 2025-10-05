import 'package:bart/tools/todo/todo_tool.dart';
import 'package:bart/tools/tool_context.dart';
import 'package:test/test.dart';

import '../../support/utils.dart';

void main() {
  late ToolContext context;
  late TodoTool tool;
  late TodoList todoList;

  setUp(() {
    context = ToolContext.test();
    tool = TodoTool();
    todoList = tool.todoList;
  });

  group('TodoTool', () {
    test('adds tasks to the list', () {
      final result = tool.execute({'operation': 'add', 'task': 'Task 1'}, context);

      expect(result, contains('Added task "Task 1".'));
      expect(todoList, hasIncompleteTask('Task 1'));
    });

    test('fails to add task with no task text', () {
      expect(
        () => tool.execute({'operation': 'add'}, context),
        throwsToolException('A task description must be provided.'),
      );
    });

    test('fails to add task with empty task text', () {
      expect(
        () => tool.execute({'operation': 'add', 'task': ''}, context),
        throwsToolException('A task description must be provided.'),
      );
    });

    test('completes a task by description', () {
      tool.execute({'operation': 'add', 'task': 'Task 1'}, context);

      final result = tool.execute({'operation': 'complete', 'task': 'Task 1'}, context);

      expect(result, contains('Completed task "Task 1".'));
      expect(todoList, hasCompleteTask('Task 1'));
    });

    test('fails to complete task with no task text', () {
      expect(
        () => tool.execute({'operation': 'complete'}, context),
        throwsToolException('A task description must be provided to complete a task.'),
      );
    });

    test('fails to complete task with empty task text', () {
      expect(
        () => tool.execute({'operation': 'complete', 'task': ''}, context),
        throwsToolException('A task description must be provided to complete a task.'),
      );
    });

    test('fails to complete non-existent task', () {
      expect(
        () => tool.execute({'operation': 'complete', 'task': 'Task 1'}, context),
        throwsToolException('Could not find task "Task 1".'),
      );
    });

    test('removes a task', () {
      tool
        ..execute({'operation': 'add', 'task': 'Task 1'}, context)
        ..execute({'operation': 'add', 'task': 'Task 2'}, context);

      final result = tool.execute({'operation': 'remove', 'task': 'Task 1'}, context);

      expect(result, contains('Removed task "Task 1".'));
      expect(todoList, isNot(hasTask('Task 1')));
      expect(todoList, hasTask('Task 2'));
    });

    test('fails to remove task with no task text', () {
      expect(
        () => tool.execute({'operation': 'remove'}, context),
        throwsToolException('A task description must be provided.'),
      );
    });

    test('fails to remove task with empty task text', () {
      expect(
        () => tool.execute({'operation': 'remove', 'task': ''}, context),
        throwsToolException('A task description must be provided.'),
      );
    });

    test('fails to remove non-existent task', () {
      expect(
        () => tool.execute({'operation': 'remove', 'task': 'Task 1'}, context),
        throwsToolException('Could not find task "Task 1".'),
      );
    });

    test('clears all tasks', () {
      tool
        ..execute({'operation': 'add', 'task': 'Task 1'}, context)
        ..execute({'operation': 'add', 'task': 'Task 2'}, context);

      final result = tool.execute({'operation': 'clear'}, context);

      expect(result, contains('Cleared TODO list.'));
      expect(todoList.tasks, isEmpty);
    });

    test('lists tasks', () {
      tool
        ..execute({'operation': 'add', 'task': 'Task 1'}, context)
        ..execute({'operation': 'add', 'task': 'Task 2'}, context)
        ..execute({'operation': 'complete', 'task': 'Task 2'}, context);

      final result = tool.execute({'operation': 'list'}, context);

      expect(
        result,
        contains('''
Current TODO list:
- ○ Task 1
- ✓ Task 2
'''),
      );
    });
  });
}

Matcher hasCompleteTask(String task) => hasTask(task, isComplete: isTrue);

Matcher hasIncompleteTask(String task) => hasTask(task, isComplete: isFalse);

Matcher hasTask(String task, {Matcher isComplete = anything}) => isA<TodoList>().having(
  (list) => list.tasks,
  'tasks',
  contains(
    isA<TodoTask>()
        .having((t) => t.task, 'task', task)
        .having((t) => t.isComplete, 'isComplete', isComplete),
  ),
);
