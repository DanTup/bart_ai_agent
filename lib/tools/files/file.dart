import 'package:bart/tools/tool.dart';
import 'package:bart/tools/tool_context.dart';
import 'package:file/file.dart';

abstract class FileTool extends Tool {
  final FileSystem fileSystem;

  FileTool(this.fileSystem);

  void ensureAccess(File file, ToolContext context) {
    if (!context.isAllowed(file)) {
      throw ToolException(
        'File "${file.path}" is outside the allowed directories. '
        'Allowed directories are ${context.allowedDirectories.map((d) => '"${d.path}"').join(", ")}.',
      );
    }
  }

  void ensureFileExists(File file) {
    if (!file.existsSync()) {
      throw ToolException('File "${file.path}" does not exist.');
    }
  }

  void ensureFileDoesNotExist(File file) {
    if (file.existsSync()) {
      throw ToolException('File "${file.path}" already exists.');
    }
  }

  void ensureUniqueStringInFile(
    File file, {
    required String content,
    required String searchString,
  }) {
    final occurrences = searchString.allMatches(content).length;
    if (occurrences == 0) {
      throw ToolException(
        'The specified string was not found in the file "${file.path}". '
        'Make sure it matches exactly including whitespace and line endings.',
      );
    }
    if (occurrences > 1) {
      throw ToolException(
        'The specified string was found multiple times in the file "${file.path}". '
        'Please include more context to make it unique.',
      );
    }
  }
}
