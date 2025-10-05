import 'package:file/file.dart';
import 'package:path/path.dart' as path;

class ToolContext {
  final Set<Directory> allowedDirectories;

  const ToolContext({required this.allowedDirectories});

  /// Checks if a path is within the allowed directories.
  bool isAllowed(File file) {
    final filePath = file.absolute.path;
    return allowedDirectories.any((allowedDirectory) {
      return path.isWithin(allowedDirectory.absolute.path, filePath);
    });
  }
}
