import 'dart:io' show IOSink, Platform, exit;

import 'package:args/args.dart';
import 'package:bart/agents/cli_agent.dart';
import 'package:bart/agents/web_agent.dart';
import 'package:bart/api/ollama_client.dart';
import 'package:bart/tools/tool_set.dart';
import 'package:file/local.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

final client = OllamaClient(model: 'gpt-oss:20b');
const fileSystem = LocalFileSystem();
final tools = ToolSet.all(fileSystem);

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
    'web',
    abbr: 'w',
    negatable: false,
    help: 'Use the web interface instead of command line interface',
  )
  ..addOption(
    'web-port',
    abbr: 'p',
    defaultsTo: '0',
    help: 'Use this port for the web interface if --web was supplied',
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

  final webResourcesPath = fileSystem.path.canonicalize(
    path.join(
      fileSystem.file(Platform.script.toFilePath()).parent.parent.path,
      'web',
    ),
  );
  try {
    final agent = argResults.flag('web')
        ? WebAgent(
            client: client,
            fileSystem: fileSystem,
            tools: tools,
            port: int.parse(argResults.option('web-port')!),
            webResourceFileSystem: fileSystem, // Can't use Chroot because it's broken on Windows.
            webResourceRootPath: webResourcesPath,
          )
        : CliAgent(
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
