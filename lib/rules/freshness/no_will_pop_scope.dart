import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart' show DiagnosticReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../src/fixes.dart';
import '../../src/types.dart';
import '../../src/utils.dart';
import '../../src/config.dart';

/// WillPopScope is deprecated. Use PopScope instead.
///
/// Type-resolved: catches aliases and reexports via TypeChecker.
class NoWillPopScope extends DartLintRule {
  const NoWillPopScope() : super(code: _code);

  static const _code = LintCode(
    name: 'rigid_no_will_pop_scope',
    problemMessage:
        'WillPopScope is deprecated. '
        'Use PopScope(canPop:, onPopInvokedWithResult:) instead.',
    errorSeverity: DiagnosticSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    if (isGeneratedFile(resolver.path)) return;
    if (!RigidConfig.forFile(resolver.path).isEnabled(code.name)) return;

    context.registry.addInstanceCreationExpression((node) {
      final type = node.staticType;
      if (type == null) return;

      if (FlutterTypes.willPopScope.isExactlyType(type)) {
        reporter.atNode(node.constructorName, code);
      }
    });
  }

  @override
  List<Fix> getFixes() => [NoWillPopScopeFix()];
}
