import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart' show DiagnosticReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Use PopScope, not deprecated WillPopScope.
class NoWillPopScope extends DartLintRule {
  const NoWillPopScope() : super(code: _code);

  static const _code = LintCode(
    name: 'rigid_no_will_pop_scope',
    problemMessage:
        'WillPopScope is deprecated. Use PopScope with '
        'canPop and onPopInvokedWithResult instead.',
    errorSeverity: DiagnosticSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      final typeName = node.constructorName.type.name.lexeme;
      if (typeName == 'WillPopScope') {
        reporter.atNode(node.constructorName, code);
      }
    });
  }
}
