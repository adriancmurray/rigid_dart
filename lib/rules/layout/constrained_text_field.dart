import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart' show DiagnosticReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:analyzer/dart/ast/ast.dart';

/// TextField must have a width constraint when inside a Row.
class ConstrainedTextField extends DartLintRule {
  const ConstrainedTextField() : super(code: _code);

  static const _code = LintCode(
    name: 'rigid_constrained_text_field',
    problemMessage:
        'TextField must have a width constraint. Wrap it in Expanded, '
        'Flexible, or SizedBox with a width when inside a Row.',
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
      if (typeName != 'TextField' && typeName != 'TextFormField') return;
      if (!_isInsideRow(node)) return;
      if (_hasConstrainingAncestor(node)) return;
      reporter.atNode(node.constructorName, code);
    });
  }

  static bool _isInsideRow(InstanceCreationExpression node) {
    var current = node.parent;
    while (current != null) {
      if (current is InstanceCreationExpression) {
        final name = current.constructorName.type.name.lexeme;
        if (name == 'Row') return true;
        if (name == 'Column' || name == 'ListView') return false;
      }
      current = current.parent;
    }
    return false;
  }

  static bool _hasConstrainingAncestor(InstanceCreationExpression node) {
    var current = node.parent;
    while (current != null) {
      if (current is InstanceCreationExpression) {
        final name = current.constructorName.type.name.lexeme;
        if (name == 'Expanded' || name == 'Flexible' ||
            name == 'SizedBox' || name == 'ConstrainedBox' ||
            name == 'Container') {
          return true;
        }
        if (name == 'Row') return false;
      }
      current = current.parent;
    }
    return false;
  }
}
