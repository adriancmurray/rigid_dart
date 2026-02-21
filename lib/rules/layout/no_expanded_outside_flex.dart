import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart' show DiagnosticReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:analyzer/dart/ast/ast.dart';

/// Expanded/Flexible must be a direct child of Row, Column, or Flex.
///
/// This is the #1 runtime crash agents produce:
/// `Expanded` placed inside a `Stack`, `Container`, or `Padding`
/// causes "Incorrect use of ParentDataWidget" errors.
class NoExpandedOutsideFlex extends DartLintRule {
  const NoExpandedOutsideFlex() : super(code: _code);

  static const _code = LintCode(
    name: 'rigid_no_expanded_outside_flex',
    problemMessage:
        'Expanded/Flexible must be a direct child of Row, Column, or Flex. '
        'Wrap the parent in a Flex widget or remove the Expanded.',
    errorSeverity: DiagnosticSeverity.ERROR,
  );

  static const _flexTypes = {'Row', 'Column', 'Flex', 'Wrap'};
  static const _expandedTypes = {'Expanded', 'Flexible'};

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      final typeName = node.constructorName.type.name.lexeme;
      if (!_expandedTypes.contains(typeName)) return;

      final parent = _findParentWidgetCreation(node);
      if (parent == null) return;

      final parentTypeName = parent.constructorName.type.name.lexeme;
      if (!_flexTypes.contains(parentTypeName)) {
        reporter.atNode(node.constructorName, code);
      }
    });
  }

  static InstanceCreationExpression? _findParentWidgetCreation(
    InstanceCreationExpression node,
  ) {
    var current = node.parent;
    while (current != null) {
      if (current is InstanceCreationExpression && current != node) {
        return current;
      }
      current = current.parent;
    }
    return null;
  }
}
