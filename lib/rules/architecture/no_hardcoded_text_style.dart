import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart' show DiagnosticReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:analyzer/dart/ast/ast.dart';

/// TextStyle must use theme typography, not raw fontSize values.
class NoHardcodedTextStyle extends DartLintRule {
  const NoHardcodedTextStyle() : super(code: _code);

  static const _code = LintCode(
    name: 'rigid_no_hardcoded_text_style',
    problemMessage:
        'Hardcoded TextStyle detected. Use theme typography '
        '(Theme.of(context).textTheme.*) or design system text styles.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      final typeName = node.constructorName.type.name.lexeme;
      if (typeName != 'TextStyle') return;
      if (_isInsideThemeOrStyleDefinition(node)) return;

      for (final arg in node.argumentList.arguments) {
        if (arg is NamedExpression && arg.name.label.name == 'fontSize') {
          if (arg.expression is IntegerLiteral ||
              arg.expression is DoubleLiteral) {
            reporter.atNode(node.constructorName, code);
            return;
          }
        }
      }
    });
  }

  static bool _isInsideThemeOrStyleDefinition(AstNode node) {
    var current = node.parent;
    while (current != null) {
      if (current is ClassDeclaration) {
        final name = current.name.lexeme.toLowerCase();
        if (name.contains('theme') || name.contains('style') ||
            name.contains('typography')) {
          return true;
        }
      }
      if (current is VariableDeclaration) {
        final name = current.name.lexeme.toLowerCase();
        if (name.contains('theme') || name.contains('style') ||
            name.contains('typography')) {
          return true;
        }
      }
      current = current.parent;
    }
    return false;
  }
}
