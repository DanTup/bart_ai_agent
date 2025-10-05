import 'package:bart/tools/files/read.dart';
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
  late ReadFileTool tool;

  setUp(() {
    fileSystem = MemoryFileSystem();
    tempDir = fileSystem.systemTempDirectory.createTempSync('test_read_').absolute;
    outsideDir = fileSystem.systemTempDirectory.createTempSync('outside_').absolute;
    context = ToolContext.test(allowedDirectories: {tempDir});
    tool = ReadFileTool(fileSystem);
  });

  group('ReadFileTool', () {
    test('successfully reads a file within allowed directory (absolute)', () {
      final file = tempDir.childFile('test.txt')..writeAsStringSync('Hello, world!');

      final result = tool.execute({'file_path': file.path}, context);
      expect(result, equals('Hello, world!'));
    });

    test('successfully reads a file within allowed directory (relative)', () {
      fileSystem.currentDirectory = tempDir;
      tempDir.childFile('test.txt').writeAsStringSync('Hello, world!');

      final result = tool.execute({'file_path': 'test.txt'}, context);
      expect(result, equals('Hello, world!'));
    });

    test('fails to read a file that does not exist', () {
      final file = tempDir.childFile('nonexistent.txt');

      expect(
        () => tool.execute({'file_path': file.path}, context),
        throwsToolException(contains('does not exist')),
      );
    });

    test('fails to read a file outside allowed directory (absolute)', () {
      final file = outsideDir.childFile('outside.txt')..writeAsStringSync('outside content');

      expect(
        () => tool.execute({'file_path': file.path}, context),
        throwsToolException(contains('is outside the allowed directories')),
      );
    });

    test('fails to read a file outside allowed directory (relative)', () {
      fileSystem.currentDirectory = tempDir;
      final file = outsideDir.childFile('outside.txt')..writeAsStringSync('outside content');

      expect(
        () => tool.execute({
          'file_path': fileSystem.path.relative(file.path, from: fileSystem.currentDirectory.path),
        }, context),
        throwsToolException(contains('is outside the allowed directories')),
      );
    });
  });
}
