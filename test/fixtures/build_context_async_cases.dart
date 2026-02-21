// Test fixture for no_build_context_across_async rule.

// SHOULD trigger:
Future<void> dangerousNavigation(BuildContext context) async {
  await Future.delayed(Duration(seconds: 1));
  // expect_lint: rigid_no_build_context_across_async
  Navigator.of(context).pop();
}

Future<void> dangerousScaffold(BuildContext context) async {
  await loadData();
  // expect_lint: rigid_no_build_context_across_async
  ScaffoldMessenger.of(context).showSnackBar(SnackBar());
}

// SHOULD NOT trigger — has mounted guard:
Future<void> safeNavigation(BuildContext context) async {
  await Future.delayed(Duration(seconds: 1));
  if (!context.mounted) return;
  Navigator.of(context).pop(); // Guarded — should NOT trigger.
}

// SHOULD NOT trigger — synchronous method:
void synchronousMethod(BuildContext context) {
  Navigator.of(context).pop(); // No await — should NOT trigger.
}

// SHOULD NOT trigger — context used BEFORE await:
Future<void> contextBeforeAwait(BuildContext context) async {
  final nav = Navigator.of(context); // Captured before await
  await Future.delayed(Duration(seconds: 1));
  nav.pop(); // Not using context directly — should NOT trigger.
}

// Adversarial: variable named 'context' that isn't a BuildContext
Future<void> nonBuildContext() async {
  final context = 'just a string';
  await Future.delayed(Duration(seconds: 1));
  // This might trigger since we check by name — acceptable false positive
  // for safety. Better to over-warn than under-warn.
}

// Mock types
class BuildContext {
  bool get mounted => true;
}

class Navigator {
  static Navigator of(BuildContext context) => Navigator();
  void pop() {}
}

class ScaffoldMessenger {
  static ScaffoldMessenger of(BuildContext context) => ScaffoldMessenger();
  void showSnackBar(SnackBar snackBar) {}
}

class SnackBar {
  const SnackBar();
}

Future<void> loadData() async {}
