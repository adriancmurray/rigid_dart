void badLogging() {
  print('debug info');
  print('more debug');
  print('yet more');
}

void goodLogging() {
  debugPrint('this is fine');
}

void methodOnObject() {
  final logger = Logger();
  logger.print('not top-level');
}

class Logger {
  void print(String message) {}
}

void debugPrint(String message) {}
