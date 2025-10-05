import 'package:bart/tools/files/file.dart';
import 'package:bart/tools/tool.dart';
import 'package:bart/tools/tool_context.dart';
import 'package:bart/tools/tool_schema.dart';

/// Tool for creating new files with content.
class CreateFileTool extends FileTool {
  CreateFileTool(super.fileSystem);

  @override
  String get name => 'create_file';

  @override
  String get description =>
      'Create a new file with the specified content. Fails if the file already exists.';

  @override
  ToolParameters get parameters => const ToolParameters({
    'file_path': Parameter.string(
      description: 'The path where the new file should be created.',
      required: true,
    ),
    'content': Parameter.string(
      description: 'The content to write to the new file.',
      required: true,
    ),
  });

  @override
  Object? execute(Map<String, Object?> arguments, ToolContext context) {
    final filePath = arguments['file_path']! as String;
    final content = arguments['content']! as String;
    final file = fileSystem.file(filePath).absolute;

    ensureAccess(file, context);
    ensureFileDoesNotExist(file);

    try {
      file.writeAsStringSync(content);
      return 'File "$filePath" created successfully.';
    } catch (e) {
      throw ToolException('Unable to create file "$filePath": $e');
    }
  }
}
