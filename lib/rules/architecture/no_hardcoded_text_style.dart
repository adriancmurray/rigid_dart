import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart' show DiagnosticReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../src/types.dart';
import '../../src/utils.dart';

/// TextStyle must come from the theme, not raw fontSize values.
///
/// Type-resolved: checks the constructed type is `TextStyle` from Flutter.
class NoHardcodedTextStyle extends DartLintRule {
  const NoHardcodedTextStyle() : super(code: _code);

  static const _code = LintCode(
    name: 'rigid_no_hardcoded_text_style',
    problemMessage:
        'Raw TextStyle with hardcoded fontSize detected. '
        'Use Theme.of(context).textTheme.* instead.',
    errorSeverity: DiagnosticSeverity.WARNING,
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

      if (!FlutterTypes.textStyle.isExactlyType(type)) return;
      if (isInsideThemeDefinition(node)) return;

      // Only flag if fontSize is present as a named argument.
      final hasFontSize = node.argumentList.arguments.any(
        (arg) => arg is NamedExpression && arg.name.label.name == 'fontSize',
      );

      if (hasFontSize) {
        reporter.atNode(node.constructorName, code);
      }
    });
  }
}
