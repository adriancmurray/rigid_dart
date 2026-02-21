// Test fixture for no_print rule.
// NOTE: This file must NOT be in the test/ directory or it will be
// treated as a test file and print() will be allowed.
// We place it in test/fixtures/ but the rule detects test files by path.
// So this test validates the NEGATIVE case — print is allowed in test files.

// SHOULD NOT trigger (file path contains /test/):
void testPrint() {
  print('allowed in test files');
}

void debugPrintUsage() {
  debugPrint('this is always fine');
}

void methodOnObject() {
  final logger = Logger();
  logger.print('this is a method on an object, not top-level print');
}

class Logger {
  void print(String message) {}
}

class Printer {
  void print(String data) {}
}

void adversarialCase() {
  final printer = Printer();
  printer.print('not a top-level print');
}

void debugPrint(String message) {}
