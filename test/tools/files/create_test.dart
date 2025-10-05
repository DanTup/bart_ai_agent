import 'package:bart/tools/files/create.dart';
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
  late CreateFileTool tool;

  setUp(() {
    fileSystem = MemoryFileSystem();
    tempDir = fileSystem.systemTempDirectory.createTempSync('test_create_').absolute;
    outsideDir = fileSystem.systemTempDirectory.createTempSync('outside_').absolute;
    context = ToolContext(allowedDirectories: {tempDir});
    tool = CreateFileTool(fileSystem);
  });

  group('CreateFileTool', () {
    test('successfully creates a file within allowed directory (absolute)', () {
      final file = tempDir.childFile('test.txt');

      final result = tool.execute({'file_path': file.path, 'content': 'Hello, world!'}, context);
      expect(result, equals('File "${file.path}" created successfully.'));
      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync(), equals('Hello, world!'));
    });

    test('successfully creates a file within allowed directory (relative)', () {
      fileSystem.currentDirectory = tempDir;
      final file = tempDir.childFile('test.txt');

      final result = tool.execute({'file_path': 'test.txt', 'content': 'Hello, world!'}, context);
      expect(result, equals('File "test.txt" created successfully.'));
      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync(), equals('Hello, world!'));
    });

    test('fails to create a file that already exists', () {
      final file = tempDir.childFile('test.txt')..writeAsStringSync('existing content');

      expect(
        () => tool.execute({'file_path': file.path, 'content': 'new content'}, context),
        throwsToolException(contains('already exists')),
      );
    });

    test('fails to create a file outside allowed directory (absolute)', () {
      final file = outsideDir.childFile('outside.txt');

      expect(
        () => tool.execute({'file_path': file.path, 'content': 'outside content'}, context),
        throwsToolException(contains('is outside the allowed directories')),
      );
    });

    test('fails to create a file outside allowed directory (relative)', () {
      fileSystem.currentDirectory = tempDir;
      final file = outsideDir.childFile('outside.txt');

      expect(
        () => tool.execute({
          'file_path': fileSystem.path.relative(file.path, from: fileSystem.currentDirectory.path),
          'content': 'outside content',
        }, context),
        throwsToolException(contains('is outside the allowed directories')),
      );
    });
  });
}
