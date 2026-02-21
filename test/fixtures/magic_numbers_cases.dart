// Test fixture for no_magic_numbers rule.
// This file is analyzed by the test — it is NOT a test itself.

void validCode() {
  // These should NOT trigger:
  final x = 0; // Allowed integer
  final y = 1; // Allowed integer
  final z = 0.0; // Allowed double
  final w = 1.0; // Allowed double
  final half = 0.5; // Allowed double
}

void violatingCode() {
  // These SHOULD trigger (magic numbers in layout params):
  // expect_lint: rigid_no_magic_numbers
  final p = Padding(padding: 16);
  // expect_lint: rigid_no_magic_numbers
  final m = Container(margin: 24.0);
  // expect_lint: rigid_no_magic_numbers
  final h = SizedBox(height: 48);
  // expect_lint: rigid_no_magic_numbers
  final s = Column(spacing: 12.0);
}

void edgeCases() {
  // Non-layout params should NOT trigger:
  final count = Items(count: 42);
  final opacity = Widget(opacity: 0.7);

  // Allowed values in layout params should NOT trigger:
  final zero = Padding(padding: 0);
  final one = SizedBox(height: 1);
  final two = Container(width: 2);
}

// Mock classes (not from Flutter, so TypeChecker won't match — that's fine,
// we're testing the AST logic of named expression detection)
class Padding { const Padding({required int padding}); }
class Container { const Container({double? margin, double? width}); }
class SizedBox { const SizedBox({int? height}); }
class Column { const Column({double? spacing}); }
class Items { const Items({required int count}); }
class Widget { const Widget({double? opacity}); }
