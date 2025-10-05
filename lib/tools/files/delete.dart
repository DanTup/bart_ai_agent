import 'package:bart/tools/files/file.dart';
import 'package:bart/tools/tool.dart';
import 'package:bart/tools/tool_context.dart';
import 'package:bart/tools/tool_schema.dart';

/// Tool for deleting files.
class DeleteFileTool extends FileTool {
  DeleteFileTool(super.fileSystem);

  @override
  String get name => 'delete_file';

  @override
  String get description => 'Delete a file from the filesystem.';

  @override
  ToolParameters get parameters => const ToolParameters({
    'file_path': Parameter.string(
      description: 'The path of the file to delete.',
      required: true,
    ),
  });

  @override
  Object? execute(Map<String, Object?> arguments, ToolContext context) {
    final filePath = arguments['file_path']! as String;
    final file = fileSystem.file(filePath).absolute;

    ensureAccess(file, context);
    ensureFileExists(file);

    try {
      file.deleteSync();
      return 'File "$filePath" deleted successfully.';
    } catch (e) {
      throw ToolException('Unable to delete file "$filePath": $e');
    }
  }
}
