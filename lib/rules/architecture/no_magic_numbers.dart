import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart' show DiagnosticReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:analyzer/dart/ast/ast.dart';

/// Numeric literals in layout code must be named constants or design tokens.
class NoMagicNumbers extends DartLintRule {
  const NoMagicNumbers() : super(code: _code);

  static const _code = LintCode(
    name: 'rigid_no_magic_numbers',
    problemMessage:
        'Magic number in layout code. Extract to a named constant '
        'or use spacing tokens from your design system.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  static const _allowedIntegers = {0, 1, 2};
  static final _allowedDoubles = {0.0, 0.5, 1.0, 2.0};

  static const _layoutParams = {
    'padding', 'margin', 'height', 'width', 'top', 'bottom', 'left', 'right',
    'horizontal', 'vertical', 'all', 'symmetric', 'only', 'radius',
    'elevation', 'spacing', 'runSpacing', 'mainAxisSpacing',
    'crossAxisSpacing', 'indent', 'endIndent', 'thickness', 'extent',
    'maxCrossAxisExtent',
  };

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addIntegerLiteral((node) {
      if (_allowedIntegers.contains(node.value)) return;
      if (!_isInLayoutContext(node)) return;
      reporter.atNode(node, code);
    });

    context.registry.addDoubleLiteral((node) {
      if (_allowedDoubles.contains(node.value)) return;
      if (!_isInLayoutContext(node)) return;
      reporter.atNode(node, code);
    });
  }

  static bool _isInLayoutContext(AstNode node) {
    var current = node.parent;
    while (current != null) {
      if (current is NamedExpression) {
        final paramName = current.name.label.name;
        if (_layoutParams.contains(paramName)) return true;
      }
      if (current is MethodDeclaration || current is FunctionDeclaration) {
        return false;
      }
      current = current.parent;
    }
    return false;
  }
}
