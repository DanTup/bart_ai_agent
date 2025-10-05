import 'dart:io' show Platform;

import 'package:file/local.dart';
import 'package:file/memory.dart';
import 'package:path/path.dart' as path;

import '../../test/support/utils.dart';

final dataDirectory = const LocalFileSystem().directory(
  path.join(packageRoot, 'integration_test', 'data'),
);

final fileSystem = MemoryFileSystem(
  style: Platform.isWindows ? FileSystemStyle.windows : FileSystemStyle.posix,
);
