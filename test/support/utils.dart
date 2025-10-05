import 'dart:isolate';

import 'package:file/file.dart';

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
