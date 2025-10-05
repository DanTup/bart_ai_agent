import 'package:bart/tools/files/file.dart';
import 'package:bart/tools/tool.dart';
import 'package:bart/tools/tool_context.dart';
import 'package:bart/tools/tool_schema.dart';

/// Tool for editing files by replacing specific content.
/// Uses search-and-replace with exact string matching for unambiguous edits.
class EditFileTool extends FileTool {
  EditFileTool(super.fileSystem);

  @override
  String get name => 'edit_file';

  @override
  String get description =>
      'Edit a file by replacing existing content with new content, or rename a file. '
      'The old_string must match exactly (including whitespace) and should include enough context to be unique. '
      'Include 2-3 lines of surrounding context in old_string to avoid ambiguity.';

  @override
  ToolParameters get parameters => const ToolParameters({
    'file_path': Parameter.string(
      description: 'The path to the file to edit.',
      required: true,
    ),
    'old_string': Parameter.string(
      description:
          'The exact text to replace. Must include enough context to be unique in the file. '
          'Not required when renaming.',
    ),
    'new_string': Parameter.string(
      description: 'The replacement text.',
      required: true,
    ),
    'new_file_path': Parameter.string(
      description: 'Optional: New path for the file (for renaming).',
    ),
  });

  @override
  Object? execute(Map<String, Object?> arguments, ToolContext context) {
    final filePath = arguments['file_path']! as String;
    final newString = arguments['new_string']! as String;
    final oldString = arguments['old_string'] as String?;
    final newFilePath = arguments['new_file_path'] as String?;
    final oldFile = fileSystem.file(filePath).absolute;
    final newFile = newFilePath != null && newFilePath.isNotEmpty
        ? fileSystem.file(newFilePath).absolute
        : null;

    ensureAccess(oldFile, context);
    ensureFileExists(oldFile);
    if (newFile != null) {
      ensureAccess(newFile, context);
      ensureFileDoesNotExist(newFile);
    }

    try {
      if (oldString != null) {
        final content = oldFile.readAsStringSync();
        ensureUniqueStringInFile(
          oldFile,
          content: content,
          searchString: oldString,
        );
        final newContent = content.replaceFirst(oldString, newString);
        oldFile.writeAsStringSync(newContent);
      }

      if (newFile != null) {
        oldFile.renameSync(newFile.path);
      }

      final changes = [
        if (oldString != null) 'edited',
        if (newFile != null) 'renamed to "$newFilePath"',
      ];

      return 'File "$filePath" successfully ${changes.join(" and ")}.';
    } catch (e) {
      if (e is ToolException) rethrow;
      throw ToolException('Unable to edit file "${oldFile.path}": $e');
    }
  }
}
