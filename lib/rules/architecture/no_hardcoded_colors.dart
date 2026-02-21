import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart' show DiagnosticReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:analyzer/dart/ast/ast.dart';

/// Colors must come from the theme, not hardcoded hex values or Colors.*
class NoHardcodedColors extends DartLintRule {
  const NoHardcodedColors() : super(code: _code);

  static const _code = LintCode(
    name: 'rigid_no_hardcoded_colors',
    problemMessage:
        'Hardcoded color detected. Use theme colors '
        '(Theme.of(context).colorScheme.*) or design tokens instead.',
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
      if (typeName == 'Color') {
        if (_isInsideThemeDefinition(node)) return;
        reporter.atNode(node, code);
      }
    });

    context.registry.addPrefixedIdentifier((node) {
      if (node.prefix.name == 'Colors') {
        if (_isInsideThemeDefinition(node)) return;
        reporter.atNode(node, code);
      }
    });
  }

  static bool _isInsideThemeDefinition(AstNode node) {
    var current = node.parent;
    while (current != null) {
      if (current is ClassDeclaration) {
        final name = current.name.lexeme.toLowerCase();
        if (name.contains('theme') || name.contains('palette') ||
            name.contains('color')) {
          return true;
        }
      }
      if (current is FunctionDeclaration) {
        if (current.name.lexeme.toLowerCase().contains('theme')) return true;
      }
      if (current is VariableDeclaration) {
        final name = current.name.lexeme.toLowerCase();
        if (name.contains('theme') || name.contains('color') ||
            name.contains('palette')) {
          return true;
        }
      }
      current = current.parent;
    }
    return false;
  }
}
