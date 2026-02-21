
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart' show DiagnosticReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../src/types.dart';
import '../../src/utils.dart';

/// Colors must come from the theme, not hardcoded hex values or Colors.*.
///
/// Type-resolved: checks the constructed type is `Color` from the Flutter
/// SDK, catches `Color(0xFF...)`, `Color.fromRGBO(...)`, etc.
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
    if (isGeneratedFile(resolver.path)) return;

    // Catch Color(...) constructors.
    context.registry.addInstanceCreationExpression((node) {
      final type = node.staticType;
      if (type == null) return;

      if (!FlutterTypes.color.isExactlyType(type)) return;
      if (isInsideThemeDefinition(node)) return;

      reporter.atNode(node, code);
    });

    // Catch Colors.red, Colors.blue, etc.
    // Type-resolved: verify the prefix resolves to Flutter's Colors class.
    context.registry.addPrefixedIdentifier((node) {
      if (node.prefix.name != 'Colors') return;

      // Check that the Colors prefix is from Flutter material/cupertino.
      final element = node.prefix.element;
      if (element == null) return;
      final source = element.firstFragment.libraryFragment?.source;
      if (source == null) return;
      final uri = source.uri.toString();
      if (!uri.contains('flutter') && !uri.contains('material') && !uri.contains('cupertino')) {
        return;
      }

      if (isInsideThemeDefinition(node)) return;

      reporter.atNode(node, code);
    });
  }
}
