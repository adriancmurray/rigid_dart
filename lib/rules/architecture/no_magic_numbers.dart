import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart' show DiagnosticReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../src/utils.dart';
import '../../src/config.dart';

/// Numeric literals in layout code must be named constants or design tokens.
class NoMagicNumbers extends DartLintRule {
  const NoMagicNumbers() : super(code: _code);

  static const _code = LintCode(
    name: 'rigid_no_magic_numbers',
    problemMessage:
        'Magic number in layout parameter. Extract to a named constant '
        'or design token (e.g., kSpacingMD, AppDimens.cardPadding).',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  static const _allowedIntegers = {0, 1, 2};
  static final _allowedDoubles = {0.0, 0.5, 1.0, 2.0};

  static const _layoutParams = {
    'padding',
    'margin',
    'height',
    'width',
    'top',
    'bottom',
    'left',
    'right',
    'horizontal',
    'vertical',
    'radius',
    'spacing',
    'indent',
    'extent',
    'thickness',
    'elevation',
    'gap',
  };

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    if (isGeneratedFile(resolver.path)) return;
    if (!RigidConfig.forFile(resolver.path).isEnabled(code.name)) return;

    context.registry.addNamedExpression((node) {
      if (!_layoutParams.contains(node.name.label.name)) return;

      final expr = node.expression;
      if (expr is IntegerLiteral) {
        if (!_allowedIntegers.contains(expr.value)) {
          reporter.atNode(expr, code);
        }
      } else if (expr is DoubleLiteral) {
        if (!_allowedDoubles.contains(expr.value)) {
          reporter.atNode(expr, code);
        }
      }
    });
  }
}
