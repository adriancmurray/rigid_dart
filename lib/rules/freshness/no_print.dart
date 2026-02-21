import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart' show DiagnosticReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../src/utils.dart';

/// Bans `print()` calls. Use a logger or `debugPrint` instead.
class NoPrint extends DartLintRule {
  const NoPrint() : super(code: _code);

  static const _code = LintCode(
    name: 'rigid_no_print',
    problemMessage:
        'print() is banned. Use debugPrint() for debug output, '
        'or a structured logger for production logging.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    if (isGeneratedFile(resolver.path)) return;
    if (isTestFile(resolver.path)) return;

    context.registry.addMethodInvocation((node) {
      if (node.methodName.name == 'print' && node.realTarget == null) {
        reporter.atNode(node.methodName, code);
      }
    });
  }
}
