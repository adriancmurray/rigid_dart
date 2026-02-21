import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart' show DiagnosticReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Use Color.withValues(alpha:), not withOpacity().
class NoWithOpacity extends DartLintRule {
  const NoWithOpacity() : super(code: _code);

  static const _code = LintCode(
    name: 'rigid_no_with_opacity',
    problemMessage:
        'withOpacity() is deprecated. '
        'Use Color.withValues(alpha: value) instead.',
    errorSeverity: DiagnosticSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      if (node.methodName.name != 'withOpacity') return;

      final targetType = node.realTarget?.staticType;
      if (targetType == null) return;

      final typeName = targetType.getDisplayString();
      if (typeName == 'Color' || typeName == 'Color?') {
        reporter.atNode(node.methodName, code);
      }
    });
  }
}
