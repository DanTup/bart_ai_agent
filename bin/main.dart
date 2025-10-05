import 'dart:io' show IOSink, exit;

import 'package:args/args.dart';
import 'package:bart/agents/cli_agent.dart';
import 'package:bart/api/ollama_client.dart';
import 'package:bart/tools/tool_set.dart';
import 'package:file/local.dart';
import 'package:logging/logging.dart';

final client = OllamaClient(model: 'gpt-oss:20b');
const fileSystem = LocalFileSystem();
final tools = ToolSet.fileTools(fileSystem);

const fileLogLevel = Level.ALL;
const consoleLogLevel = Level.INFO;

/// Argument parser for command line options.
final parser = ArgParser()
  ..addOption(
    'log-file',
    abbr: 'l',
    help: 'Record verbose logging to this file',
  )
  ..addFlag(
    'help',
    abbr: 'h',
    negatable: false,
    help: 'Print this usage information',
  );

/// Main entry point of the application.
Future<void> main(List<String> args) async {
  final argResults = _parseArgs(args);
  final logSink = _setUpLogging(argResults['log-file'] as String?);

  try {
    final agent = CliAgent(
      client: client,
      fileSystem: fileSystem,
      tools: tools,
    );

    await agent.run();
  } finally {
    await logSink?.flush();
    await logSink?.close();
  }
}

IOSink? _setUpLogging(String? logFilePath) {
  Logger.root.level = fileLogLevel;
  final logSink = logFilePath != null ? fileSystem.file(logFilePath).openWrite() : null;

  Logger.root.onRecord.listen((record) {
    final prefix = '${record.level.name}: ${record.time}: ';
    final text = record.message.split('\n').join('\n${' ' * prefix.length}');
    final message = '$prefix$text';
    logSink?.writeln(message);
    if (record.level >= consoleLogLevel) {
      print(message);
    }
  });

  return logSink;
}

ArgResults _parseArgs(List<String> args) {
  ArgResults argResults;
  try {
    argResults = parser.parse(args);
  } on ArgParserException catch (e) {
    print('Error: ${e.message}');
    print('');
    print(parser.usage);
    exit(1);
  }

  if (argResults['help'] as bool) {
    print(parser.usage);
    exit(0);
  }
  return argResults;
}
