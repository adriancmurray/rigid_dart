import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart' show DiagnosticReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../src/utils.dart';

/// AsyncValue must be handled exhaustively with .when(), not .value.
///
/// Already type-resolved via staticType inspection.
class ExhaustiveAsync extends DartLintRule {
  const ExhaustiveAsync() : super(code: _code);

  static const _code = LintCode(
    name: 'rigid_exhaustive_async',
    problemMessage:
        'AsyncValue accessed via .value without exhaustive handling. '
        'Use .when(data:, loading:, error:) or pattern match all states.',
    errorSeverity: DiagnosticSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    if (isGeneratedFile(resolver.path)) return;

    context.registry.addPropertyAccess((node) {
      if (node.propertyName.name != 'value') return;

      final targetType = node.realTarget.staticType;
      if (targetType == null) return;

      final typeName = targetType.getDisplayString();
      if (typeName.startsWith('AsyncValue')) {
        reporter.atNode(node.propertyName, code);
      }
    });
  }
}
