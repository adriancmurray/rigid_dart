import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart' show DiagnosticReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../src/types.dart';
import '../../src/utils.dart';

/// TextField in a Row must be width-constrained (Expanded or SizedBox).
///
/// Without constraints, TextField takes infinite width and crashes.
class ConstrainedTextField extends DartLintRule {
  const ConstrainedTextField() : super(code: _code);

  static const _code = LintCode(
    name: 'rigid_constrained_text_field',
    problemMessage:
        'TextField inside a Row must be wrapped in Expanded, Flexible, '
        'or SizedBox to constrain its width.',
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

      if (!FlutterTypes.textFieldFamily.isAssignableFromType(type)) return;

      // Walk up — check if inside a Row without width constraint.
      var current = node.parent;
      while (current != null) {
        if (current is InstanceCreationExpression) {
          final parentType = current.staticType;
          if (parentType == null) break;

          // If wrapped in Expanded/Flexible/SizedBox, it's constrained.
          if (FlutterTypes.expanded.isExactlyType(parentType) ||
              FlutterTypes.flexible.isExactlyType(parentType) ||
              FlutterTypes.sizedBox.isExactlyType(parentType)) {
            return;
          }

          // If we hit a Row without constraint wrapper, flag it.
          if (FlutterTypes.row.isExactlyType(parentType)) {
            reporter.atNode(node.constructorName, code);
            return;
          }
        }
        current = current.parent;
      }
    });
  }
}
