import 'dart:async';
import 'dart:convert';
import 'dart:io'
    show
        ContentType,
        HttpRequest,
        HttpServer,
        HttpStatus,
        InternetAddress,
        WebSocket,
        WebSocketTransformer;

import 'package:bart/agents/agent.dart';
import 'package:bart/output_message.dart';
import 'package:file/file.dart';

/// A web-based implementation of [Agent] that serves a web interface that can be accessed in a browser.
class WebAgent extends Agent {
  final int port;
  final FileSystem webResourceFileSystem;
  final String webResourceRootPath;
  WebSocket? _webSocket;
  final _userInputQueue = <String>[];
  Completer<String?>? _userInputCompleter;
  final _outputController = StreamController<String>();

  @override
  late final allowedDirectories = {fileSystem.currentDirectory};

  WebAgent({
    required super.client,
    super.systemMessage,
    required super.fileSystem,
    required super.tools,
    required this.port,
    required this.webResourceFileSystem,
    required this.webResourceRootPath,
  });

  @override
  Future<void> run({String? initialUserMessage}) async {
    await _startServer();
    // TODO(dantup): This needs to be the actual port we bind to, not what was
    //  passed here, as it could be zero.
    print('Web agent started. Open http://localhost:$port in your browser.');
    print('Press Ctrl+C to stop.');

    await super.run(initialUserMessage: initialUserMessage);
  }

  Future<void> _startServer() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    server.listen(_handleRequest);
  }

  Future<void> _handleRequest(HttpRequest request) async {
    var requestPath = request.uri.path;
    if (requestPath.endsWith('/')) {
      requestPath += 'index.html';
    }

    if (requestPath == '/ws') {
      // Handle WebSocket upgrade
      _webSocket = await WebSocketTransformer.upgrade(request);

      _webSocket!.listen(
        (message) {
          final data = jsonDecode(message as String) as Map<String, Object?>;
          if (data['type'] == 'input') {
            _handleUserInput(data['content']! as String);
          }
        },
        onDone: () {
          _handleUserInput(null); // Signal end
        },
      );

      // Send outputs to the client
      // TODO(dantup): This fails on page refresh
      _outputController.stream.listen((message) {
        _webSocket?.add(message);
      });
    } else {
      final resourcePath = webResourceFileSystem.path.join(
        webResourceRootPath,
        requestPath.substring(1).split('/').join(webResourceFileSystem.path.separator),
      );
      print(resourcePath);
      final resourceFile = webResourceFileSystem.file(resourcePath);
      if (webResourceFileSystem.path.isWithin(webResourceRootPath, resourcePath) &&
          await resourceFile.exists()) {
        final contentType = _getContentType(requestPath);
        request.response
          ..headers.contentType = contentType
          ..add(await resourceFile.readAsBytes());
        await request.response.close();
      } else {
        log.warning('Could not find $requestPath');
        request.response
          ..statusCode = HttpStatus.notFound
          ..write('File not found');
      }
      await request.response.close();
    }
  }

  ContentType _getContentType(String path) {
    if (path.endsWith('.html')) return ContentType.html;
    if (path.endsWith('.css')) return ContentType('text', 'css');
    if (path.endsWith('.js')) return ContentType('application', 'javascript');
    return ContentType.binary;
  }

  void _handleUserInput(String? input) {
    if (_userInputCompleter != null && !_userInputCompleter!.isCompleted) {
      _userInputCompleter!.complete(input);
      _userInputCompleter = null;
    } else if (input != null) {
      _userInputQueue.add(input);
    }
  }

  @override
  void startWorking(String reason) {
    _outputController.add(jsonEncode({'type': 'working', 'reason': reason}));
  }

  @override
  void stopWorking() {
    _outputController.add(jsonEncode({'type': 'stop_working'}));
  }

  @override
  Future<String?> getUserMessage() async {
    if (_userInputQueue.isNotEmpty) {
      return _userInputQueue.removeAt(0);
    }

    _userInputCompleter = Completer<String?>();
    return _userInputCompleter!.future;
  }

  @override
  Future<void> showOutput(OutputMessage message) async {
    // TODO(dantup): Change this to send the object over as JSON and let the
    //  frontend handle with the real types.
    String jsonMessage;
    switch (message) {
      case SystemOutput(content: final content):
        jsonMessage = jsonEncode({'type': 'system', 'content': content});
      case AssistantMessage(content: final content):
        jsonMessage = jsonEncode({'type': 'assistant', 'content': content});
      case ToolCall(toolName: final toolName):
        jsonMessage = jsonEncode({'type': 'tool_call', 'toolName': toolName});
    }
    _outputController.add(jsonMessage);
  }
}
