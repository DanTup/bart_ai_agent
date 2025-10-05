import 'package:bart/tools/files/delete.dart';
import 'package:bart/tools/tool.dart';
import 'package:bart/tools/tool_context.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:test/test.dart';

void main() {
  late MemoryFileSystem fileSystem;
  late Directory tempDir;
  late Directory outsideDir;
  late ToolContext context;
  late DeleteFileTool tool;

  setUp(() {
    fileSystem = MemoryFileSystem();
    tempDir = fileSystem.systemTempDirectory.createTempSync('test_delete_').absolute;
    outsideDir = fileSystem.systemTempDirectory.createTempSync('outside_').absolute;
    context = ToolContext(allowedDirectories: {tempDir});
    tool = DeleteFileTool(fileSystem);
  });

  group('DeleteFileTool', () {
    test('successfully deletes a file within allowed directory (absolute)', () {
      final file = tempDir.childFile('test.txt')..writeAsStringSync('Hello, world!');

      final result = tool.execute({'file_path': file.path}, context);
      expect(result, equals('File "${file.path}" deleted successfully.'));
      expect(file.existsSync(), isFalse);
    });

    test('successfully deletes a file within allowed directory (relative)', () {
      fileSystem.currentDirectory = tempDir;
      final file = tempDir.childFile('test.txt')..writeAsStringSync('Hello, world!');

      final result = tool.execute({'file_path': 'test.txt'}, context);
      expect(result, equals('File "test.txt" deleted successfully.'));
      expect(file.existsSync(), isFalse);
    });

    test('fails to delete a file that does not exist', () {
      final file = tempDir.childFile('nonexistent.txt');

      expect(
        () => tool.execute({'file_path': file.path}, context),
        throwsA(
          isA<ToolException>().having(
            (e) => e.message,
            'message',
            contains('does not exist'),
          ),
        ),
      );
    });

    test('fails to delete a file outside allowed directory (absolute)', () {
      final file = outsideDir.childFile('outside.txt')..writeAsStringSync('outside content');

      expect(
        () => tool.execute({'file_path': file.path}, context),
        throwsA(
          isA<ToolException>().having(
            (e) => e.message,
            'message',
            contains('is outside the allowed directories'),
          ),
        ),
      );
    });

    test('fails to delete a file outside allowed directory (relative)', () {
      fileSystem.currentDirectory = tempDir;
      final file = outsideDir.childFile('outside.txt')..writeAsStringSync('outside content');

      expect(
        () => tool.execute({
          'file_path': fileSystem.path.relative(file.path, from: fileSystem.currentDirectory.path),
        }, context),
        throwsA(
          isA<ToolException>().having(
            (e) => e.message,
            'message',
            contains('is outside the allowed directories'),
          ),
        ),
      );
    });
  });
}
