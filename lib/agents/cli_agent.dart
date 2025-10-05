import 'dart:io' show stdin, stdout;

import 'package:bart/agents/agent.dart';
import 'package:bart/output_message.dart';

/// A command-line interface implementation of [Agent].
class CliAgent extends Agent {
  CliAgent({
    required super.client,
    super.systemMessage,
  });

  @override
  String? getUserMessage() {
    stdout.write('You: ');
    return stdin.readLineSync();
  }

  @override
  void showOutput(OutputMessage message) {
    switch (message) {
      case SystemOutput(content: final content):
        print('System: $content');
      case AssistantMessage(content: final content):
        print('Agent: $content');
    }
  }
}
