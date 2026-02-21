import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart' show DiagnosticReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../src/types.dart';
import '../../src/utils.dart';

/// Expanded/Flexible must be a direct child of Row, Column, Flex, or Wrap.
///
/// Uses [TypeChecker] for type-resolved detection — catches aliases,
/// subclasses, and reexports, not just string names.
class NoExpandedOutsideFlex extends DartLintRule {
  const NoExpandedOutsideFlex() : super(code: _code);

  static const _code = LintCode(
    name: 'rigid_no_expanded_outside_flex',
    problemMessage:
        'Expanded/Flexible must be a direct child of Row, Column, or Flex. '
        'Wrap the parent in a Flex widget or remove the Expanded.',
    errorSeverity: DiagnosticSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    if (isGeneratedFile(resolver.path)) return;

    context.registry.addInstanceCreationExpression((node) {
      final type = node.staticType;
      if (type == null) return;

      // Is this an Expanded or Flexible?
      if (!FlutterTypes.expanded.isExactlyType(type) &&
          !FlutterTypes.flexible.isExactlyType(type)) {
        return;
      }

      // Walk up to the nearest parent widget constructor.
      final parent = _findParentWidgetCreation(node);
      if (parent == null) return;

      final parentType = parent.staticType;
      if (parentType == null) return;

      // Parent must be a Flex-family widget.
      if (!FlutterTypes.flexFamily.isAssignableFromType(parentType)) {
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
