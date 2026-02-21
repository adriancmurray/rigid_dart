import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart' show DiagnosticReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../src/types.dart';
import '../../src/utils.dart';
import '../../src/config.dart';

/// Nesting scrollable widgets without constraints causes unbounded height.
///
/// Catches Column/ListView/GridView nested inside another scrollable
/// without a SizedBox or ConstrainedBox providing bounds.
class NoUnboundedColumn extends DartLintRule {
  const NoUnboundedColumn() : super(code: _code);

  static const _code = LintCode(
    name: 'rigid_no_unbounded_column',
    problemMessage:
        'Potentially unbounded widget nested inside a scrollable. '
        'Wrap in SizedBox with a height, or use shrinkWrap: true.',
    errorSeverity: DiagnosticSeverity.WARNING,
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

      // Is this a Column or scrollable?
      final isColumn = FlutterTypes.column.isExactlyType(type);
      final isScrollable = FlutterTypes.scrollableFamily.isAssignableFromType(
        type,
      );
      if (!isColumn && !isScrollable) return;

      // Check for shrinkWrap: true
      if (_hasShrinkWrap(node)) return;

      // Walk up — is there a parent scrollable without a SizedBox boundary?
      var current = node.parent;
      while (current != null) {
        if (current is InstanceCreationExpression) {
          final parentType = current.staticType;
          if (parentType == null) break;

          // If we hit a SizedBox, constraints are applied — OK.
          if (FlutterTypes.sizedBox.isExactlyType(parentType)) return;

          // If we hit another scrollable, that's the problem.
          if (FlutterTypes.scrollableFamily.isAssignableFromType(parentType) ||
              FlutterTypes.column.isExactlyType(parentType)) {
            reporter.atNode(node.constructorName, code);
            return;
          }
        }
        current = current.parent;
      }
    });
  }

  static bool _hasShrinkWrap(InstanceCreationExpression node) {
    for (final arg in node.argumentList.arguments) {
      if (arg is NamedExpression &&
          arg.name.label.name == 'shrinkWrap' &&
          arg.expression is BooleanLiteral &&
          (arg.expression as BooleanLiteral).value) {
        return true;
      }
    }
    return false;
  }
}
