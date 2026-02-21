import 'dart:io';

import 'package:path/path.dart' as p;

/// Returns the absolute path to a test fixture file.
File fixture(String relativePath) {
  final absolute = p.normalize(p.join(Directory.current.path, relativePath));
  return File(absolute);
}
