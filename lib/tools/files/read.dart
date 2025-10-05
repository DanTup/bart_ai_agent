import 'package:bart/tools/files/file.dart';
import 'package:bart/tools/tool.dart';
import 'package:bart/tools/tool_context.dart';
import 'package:bart/tools/tool_schema.dart';

/// Tool for reading file contents.
class ReadFileTool extends FileTool {
  ReadFileTool(super.fileSystem);

  @override
  String get name => 'read_file';

  @override
  String get description => 'Read the contents of a file.';

  @override
  ToolParameters get parameters => const ToolParameters({
    'file_path': Parameter.string(
      description: 'The path to the file to read.',
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
      return file.readAsStringSync();
    } catch (e) {
      throw ToolException('Unable to read file "$filePath": $e');
    }
  }
}
