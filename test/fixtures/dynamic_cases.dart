// Test fixture for no_dynamic rule.

// SHOULD trigger:
// expect_lint: rigid_no_dynamic
void takesAnything(dynamic input) {}

// expect_lint: rigid_no_dynamic
dynamic fetchData() => null;

class MyClass {
  // expect_lint: rigid_no_dynamic
  late dynamic value;
}

// SHOULD NOT trigger:
void typedFunction(Object? input) {}
String getString() => '';
void castExpression(Object x) {
  // Cast to dynamic is an allowed escape hatch
  final y = x as dynamic;
}
int normalCode = 42;
