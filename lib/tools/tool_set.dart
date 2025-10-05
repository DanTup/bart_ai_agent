import 'package:bart/tools/files/create.dart';
import 'package:bart/tools/files/delete.dart';
import 'package:bart/tools/files/edit.dart';
import 'package:bart/tools/files/read.dart';
import 'package:bart/tools/todo/todo_tool.dart';
import 'package:bart/tools/tool.dart';
import 'package:file/file.dart';

/// A collection of tools that can be easily passed to an agent.
/// Provides convenient access to common tool sets.
class ToolSet {
  static List<Tool> fileTools(FileSystem fileSystem) => [
    CreateFileTool(fileSystem),
    DeleteFileTool(fileSystem),
    EditFileTool(fileSystem),
    ReadFileTool(fileSystem),
  ];

  static List<Tool> all(FileSystem fileSystem) => [
    ...fileTools(fileSystem),
    TodoTool(),
  ];
}
