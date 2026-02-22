import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart' show DiagnosticReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../src/config.dart';
import '../../src/utils.dart';

/// Flags test files that contain `test()` or `testWidgets()` blocks
/// but zero `expect()` calls.
///
/// Agents satisfy [RequireTests] by creating test files, then write
/// `test('works', () {});` — a test that always passes but validates nothing.
/// This rule closes that loophole.
class MinTestAssertions extends DartLintRule {
  const MinTestAssertions() : super(code: _code);

  static const _code = LintCode(
    name: 'rigid_min_test_assertions',
    problemMessage:
        'Test file contains test blocks but no expect() calls. '
        'Every test must assert something. Add expect() or expectLater().',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    if (isGeneratedFile(resolver.path)) return;
    if (!RigidConfig.forFile(resolver.path).isEnabled(code.name)) return;
    // Only run on test files.
    if (!isTestFile(resolver.path)) return;

    context.registry.addCompilationUnit((unit) {
      var hasTestBlock = false;
      var hasExpect = false;

      void visit(AstNode node) {
        if (node is MethodInvocation) {
          final name = node.methodName.name;
          if (name == 'test' || name == 'testWidgets' || name == 'group') {
            hasTestBlock = true;
          }
          if (name == 'expect' || name == 'expectLater' ||
              name == 'expectAsync0' || name == 'expectAsync1' ||
              name == 'verify' || name == 'verifyInOrder' ||
              name == 'verifyNever') {
            hasExpect = true;
          }
        }
        // Short-circuit if we found both.
        if (hasTestBlock && hasExpect) return;
        node.childEntities.whereType<AstNode>().forEach(visit);
      }

      visit(unit);

      if (hasTestBlock && !hasExpect) {
        reporter.atNode(unit, code);
      }
    });
  }
}
