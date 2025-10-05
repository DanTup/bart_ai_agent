import 'dart:async';

import 'package:bart/agents/agent.dart';
import 'package:bart/output_message.dart';
import 'package:file/file.dart';

/// An implementation of [Agent] for integration testing.
///
/// Allows controlling the agent's input and inspecting outputs.
class TestAgent extends Agent {
  @override
  final Set<Directory> allowedDirectories;

  /// The last tool call made by the assistant.
  ToolCall get lastToolCall => _lastToolCall ?? (throw 'No tool calls made');
  ToolCall? _lastToolCall;

  /// The last output message from the assistant.
  String get lastAssistantMessage => _lastAssistantMessage ?? (throw 'No assistant messages');
  String? _lastAssistantMessage;

  Completer<String?>? _inputCompleter;
  Completer<void>? _readyCompleter;
  Future<void>? _runFuture;

  /// Creates a [TestAgent] and immediately starts it running which will result in a request for user input.
  ///
  /// Input can be provided by calling [provideInput].
  TestAgent.start({
    required super.client,
    super.systemMessage,
    required super.fileSystem,
    required this.allowedDirectories,
    required super.tools,
  }) {
    _runFuture = run();
  }

  @override
  void startWorking(String reason) {
    log.finest('Starting work: $reason');
  }

  @override
  void stopWorking() {
    log.finest('Stopping work');
  }

  @override
  Future<String?> getUserMessage() {
    // The agent asked for input, so we complete the `provideInput()` completer to signal to the test that
    // the round of conversation from the last input is done. This allows it to perform tests before
    // providing the next input.
    _readyCompleter?.complete();

    // Create a completer allow the test to provide the next input later.
    return (_inputCompleter = Completer<String?>()).future;
  }

  /// Provide input to the agent and run until it waits for the next input.
  Future<void> provideInput(String? message) async {
    final completer = _inputCompleter;
    if (completer == null || completer.isCompleted) {
      throw 'The agent is not waiting for input!';
    }

    // Send the message.
    log.fine('You: ${message ?? '(end)'}');
    completer.complete(message);

    // If it was a normal message, wait for it to be send and handled.
    if (message != null) {
      await (_readyCompleter = Completer<void>()).future;
    }
  }

  @override
  void showOutput(OutputMessage message) {
    switch (message) {
      case ToolCall():
        _lastToolCall = message;
      case AssistantMessage():
        log.fine('Assistant: ${message.content}');
        _lastAssistantMessage = message.content;
      default:
    }
  }

  /// Ends the agent session.
  Future<void> end() async {
    await provideInput(null);
    await _runFuture;
  }
}
