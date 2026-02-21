import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart' show DiagnosticReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../src/fixes.dart';
import '../../src/utils.dart';

/// Ban the `dynamic` type. Everything must be explicitly typed.
class NoDynamic extends DartLintRule {
  const NoDynamic() : super(code: _code);

  static const _code = LintCode(
    name: 'rigid_no_dynamic',
    problemMessage:
        'The type "dynamic" is banned. Use an explicit type, '
        'Object?, or a generic type parameter instead.',
    errorSeverity: DiagnosticSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    if (isGeneratedFile(resolver.path)) return;

    context.registry.addNamedType((node) {
      if (node.name.lexeme == 'dynamic') {
        // Skip if this is inside a cast expression (as dynamic) — rare but valid.
        if (node.parent is AsExpression) return;

        reporter.atNode(node, code);
      }
    });
  }

  @override
  List<Fix> getFixes() => [NoDynamicFix()];
}
