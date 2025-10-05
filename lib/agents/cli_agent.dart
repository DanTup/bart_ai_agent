import 'dart:async';
import 'dart:io' show stdin, stdout;

import 'package:bart/agents/agent.dart';
import 'package:bart/output_message.dart';

/// A command-line interface implementation of [Agent].
class CliAgent extends Agent {
  @override
  late final allowedDirectories = {fileSystem.currentDirectory};

  String? _workingReason;
  Timer? spinnerTimer;
  var spinnerIndex = 0;
  final spinnerChars = ['|', '/', '-', r'\'];

  CliAgent({
    required super.client,
    super.systemMessage,
    required super.fileSystem,
    required super.tools,
  });

  @override
  void startWorking(String reason) {
    _workingReason = reason;
    _startSpinner();
  }

  @override
  void stopWorking() {
    _stopSpinner();
  }

  @override
  String? getUserMessage() {
    stdout.write('You: ');
    return stdin.readLineSync();
  }

  /// Whether the agent is currently working.
  bool get isWorking => _workingReason != null;

  @override
  void showOutput(OutputMessage message) {
    if (isWorking) {
      _stopSpinner();
    }

    switch (message) {
      case SystemOutput(content: final content):
        print('System: $content');
      case AssistantMessage(content: final content):
        print('Agent: $content');
      case ToolCall(toolName: final toolName):
        print('Tool called: $toolName');
    }

    if (isWorking) {
      _startSpinner();
    }
  }

  void _startSpinner() {
    spinnerTimer?.cancel();
    spinnerTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      stdout.write('\r$_workingReason… ${spinnerChars[spinnerIndex]}');
      spinnerIndex = (spinnerIndex + 1) % spinnerChars.length;
    });
  }

  void _stopSpinner() {
    spinnerTimer?.cancel();
    spinnerTimer = null;
    stdout.write('\r\x1b[K');
  }
}
