import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart' show DiagnosticReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../src/fixes.dart';
import '../../src/types.dart';
import '../../src/utils.dart';

/// `.withOpacity()` is deprecated. Use `.withValues(alpha:)` instead.
///
/// Type-resolved: checks that the receiver is `Color` from Flutter,
/// not just any method named withOpacity.
class NoWithOpacity extends DartLintRule {
  const NoWithOpacity() : super(code: _code);

  static const _code = LintCode(
    name: 'rigid_no_with_opacity',
    problemMessage:
        '.withOpacity() is deprecated. '
        'Use .withValues(alpha: x) instead.',
    errorSeverity: DiagnosticSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    if (isGeneratedFile(resolver.path)) return;

    context.registry.addMethodInvocation((node) {
      if (node.methodName.name != 'withOpacity') return;

      // Type-resolve: is the receiver a Color?
      final targetType = node.realTarget?.staticType;
      if (targetType == null) return;

      if (FlutterTypes.color.isAssignableFromType(targetType)) {
        reporter.atNode(node.methodName, code);
      }
    });
  }

  @override
  List<Fix> getFixes() => [NoWithOpacityFix()];
}
