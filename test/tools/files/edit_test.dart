import 'package:bart/tools/files/edit.dart';
import 'package:bart/tools/tool_context.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:test/test.dart';

import '../../support/utils.dart';

void main() {
  late MemoryFileSystem fileSystem;
  late Directory tempDir;
  late Directory outsideDir;
  late ToolContext context;
  late EditFileTool tool;

  setUp(() {
    fileSystem = MemoryFileSystem();
    tempDir = fileSystem.systemTempDirectory.createTempSync('test_edit_').absolute;
    outsideDir = fileSystem.systemTempDirectory.createTempSync('outside_').absolute;
    context = ToolContext(allowedDirectories: {tempDir});
    tool = EditFileTool(fileSystem);
  });

  group('EditFileTool', () {
    test('successfully edits a file within allowed directory (absolute)', () {
      final file = tempDir.childFile('test.txt')..writeAsStringSync('Hello, world!');

      final result = tool.execute({
        'file_path': file.path,
        'old_string': 'Hello, world!',
        'new_string': 'Hello, Dart!',
      }, context);
      expect(result, equals('File "${file.path}" successfully edited.'));
      expect(file.readAsStringSync(), equals('Hello, Dart!'));
    });

    test('successfully edits a file within allowed directory (relative)', () {
      fileSystem.currentDirectory = tempDir;
      final file = tempDir.childFile('test.txt')..writeAsStringSync('Hello, world!');

      final result = tool.execute({
        'file_path': 'test.txt',
        'old_string': 'Hello, world!',
        'new_string': 'Hello, Dart!',
      }, context);
      expect(result, equals('File "test.txt" successfully edited.'));
      expect(file.readAsStringSync(), equals('Hello, Dart!'));
    });

    test('fails to edit a file that does not exist', () {
      final file = tempDir.childFile('nonexistent.txt');

      expect(
        () => tool.execute({
          'file_path': file.path,
          'old_string': 'old',
          'new_string': 'new',
        }, context),
        throwsToolException(contains('does not exist')),
      );
    });

    test('fails to edit a file outside allowed directory (absolute)', () {
      final file = outsideDir.childFile('outside.txt')..writeAsStringSync('outside content');

      expect(
        () => tool.execute({
          'file_path': file.path,
          'old_string': 'outside content',
          'new_string': 'new content',
        }, context),
        throwsToolException(contains('is outside the allowed directories')),
      );
    });

    test('fails to edit a file outside allowed directory (relative)', () {
      fileSystem.currentDirectory = tempDir;
      final file = outsideDir.childFile('outside.txt')..writeAsStringSync('outside content');

      expect(
        () => tool.execute({
          'file_path': fileSystem.path.relative(file.path, from: fileSystem.currentDirectory.path),
          'old_string': 'outside content',
          'new_string': 'new content',
        }, context),
        throwsToolException(contains('is outside the allowed directories')),
      );
    });
  });
}
