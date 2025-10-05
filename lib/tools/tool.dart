import 'package:bart/api/types.dart';
import 'package:bart/tools/tool_context.dart';
import 'package:bart/tools/tool_schema.dart';

/// Exception thrown by tools when an error occurs during execution.
class ToolException implements Exception {
  final String message;

  ToolException(this.message);

  @override
  String toString() => message;
}

abstract class Tool {
  // TODO(dantup): Implement prompting the user for permission to run.
  //  Some tools will always require permission, and others may be conditional
  //  depending on the args (and/or config).

  String get name;
  String get description;
  ToolParameters get parameters;

  ToolDefinition get definition => ToolDefinition(
    type: 'function',
    function: ToolFunction(
      name: name,
      description: description,
      parameters: parameters.toJson(),
    ),
  );

  Object? execute(Map<String, Object?> arguments, ToolContext context);
}
