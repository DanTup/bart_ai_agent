import 'package:bart/output_message.dart';
import 'package:file/file.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

class ToolContext {
  final Set<Directory> allowedDirectories;
  final void Function(OutputMessage message) showOutput;

  ToolContext({
    required this.allowedDirectories,
    required this.showOutput,
  });

  @visibleForTesting
  ToolContext.test({
    Set<Directory>? allowedDirectories,
    void Function(OutputMessage message)? showOutput,
  }) : this(
         allowedDirectories: allowedDirectories ?? {},
         showOutput: showOutput ?? (_) {},
       );

  /// Checks if a path is within the allowed directories.
  bool isAllowed(File file) {
    final filePath = file.absolute.path;
    return allowedDirectories.any((allowedDirectory) {
      return path.isWithin(allowedDirectory.absolute.path, filePath);
    });
  }
}
