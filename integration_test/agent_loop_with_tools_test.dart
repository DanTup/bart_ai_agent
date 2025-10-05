import 'package:bart/api/client.dart';
import 'package:bart/api/ollama_client.dart';
import 'package:bart/tools/tool_set.dart';
import 'package:file/file.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import '../test/support/utils.dart';
import 'support/test_agent.dart';
import 'support/test_client.dart';
import 'support/utils.dart';

const mode = TestMode.useSnapshots;

const logLevel = Level.FINE;

void main() {
  _setUpLogging();

  group('Agent Loop with Tools', () {
    late final Directory tempProjectDir;
    late final TestApiClient client;
    late final ApiClient? realApi;
    late final TestAgent agent;

    const readmeFilename = 'README.md';
    final readmeFile = fileSystem.file(readmeFilename);
    const testPhrase = 'The cat sat on the mat';

    setUp(() {
      tempProjectDir = fileSystem.systemTempDirectory.createTempSync('bart_test_');
      fileSystem.currentDirectory = tempProjectDir;

      realApi = (mode == TestMode.useLlm || mode == TestMode.recordSnapshots)
          ? OllamaClient(model: 'gpt-oss:20b')
          : null;
      client = TestApiClient(
        realClient: realApi,
        dataDirectory: dataDirectory,
        mode: mode,
      );
    });

    tearDown(() async {
      await agent.provideInput(null);
      tryDelete(tempProjectDir);
    });

    test('Use create, edit, read, delete tools', () async {
      expect(readmeFile.existsSync(), isFalse); // Ensure initial state.

      agent = TestAgent.start(
        client: client,
        fileSystem: fileSystem,
        allowedDirectories: {tempProjectDir},
        tools: ToolSet.fileTools(fileSystem),
      );

      // Create
      await agent.provideInput('Create a $readmeFilename file with the content "Hello World".');
      expect(agent.lastToolCall.toolName, 'create_file');
      expect(readmeFile.readAsStringSync(), 'Hello World');

      // Edit
      await agent.provideInput(
        'Edit the $readmeFilename file to change "Hello World" to "Hello Universe".',
      );
      expect(agent.lastToolCall.toolName, 'edit_file');
      expect(readmeFile.readAsStringSync(), 'Hello Universe');

      readmeFile.writeAsStringSync(testPhrase);
      await agent.provideInput(
        'I modified $readmeFilename to verify your read tool. Please return the contents.',
      );
      expect(agent.lastToolCall.toolName, 'read_file');
      expect(agent.lastAssistantMessage, contains(testPhrase));

      // Delete
      await agent.provideInput('Delete the $readmeFilename file.');
      expect(agent.lastToolCall.toolName, 'delete_file');
      expect(readmeFile.existsSync(), isFalse);
    });
  });
}

void _setUpLogging() {
  Logger.root.level = logLevel;
  Logger.root.onRecord.listen((record) {
    final prefix = '${record.level.name}: ${record.time}: ';
    final text = record.message.split('\n').join('\n${' ' * prefix.length}');
    final message = '$prefix$text';
    print(message);
  });
}
