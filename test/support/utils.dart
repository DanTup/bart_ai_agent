import 'dart:isolate';

import 'package:bart/tools/tool.dart';
import 'package:file/file.dart';
import 'package:test/test.dart';

void tryDelete(Directory directory) {
  try {
    directory.deleteSync(recursive: true);
  } catch (_) {
    // Ignore file locking errors on Windows.
  }
}

final packageRoot = Isolate.resolvePackageUriSync(
  Uri.parse('package:bart/'),
)!.resolve('..').toFilePath();

Matcher throwsToolException(Object? messageMatcher) => throwsA(
  isA<ToolException>().having(
    (e) => e.message,
    'message',
    messageMatcher,
  ),
);
