import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart' show DiagnosticReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../src/config.dart';
import '../../src/utils.dart';

/// Flags widget classes that exceed a configurable line threshold.
///
/// Default: 250 lines. Configure via `rigid_dart.yaml`:
///
/// ```yaml
/// preferences:
///   max_widget_lines: 300
/// ```
///
/// Set to `0` to disable.
class MaxWidgetLines extends DartLintRule {
  const MaxWidgetLines() : super(code: _code);

  static const _code = LintCode(
    name: 'rigid_max_widget_lines',
    problemMessage:
        'Widget class has {0} lines (max {1}). '
        'Decompose into smaller, focused widgets.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  static const _defaultMax = 250;

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    if (isGeneratedFile(resolver.path)) return;
    final config = RigidConfig.forFile(resolver.path);
    if (!config.isEnabled(code.name)) return;
    if (isTestFile(resolver.path)) return;

    final maxLines = config.maxWidgetLines ?? _defaultMax;
    if (maxLines <= 0) return; // Disabled by user.

    context.registry.addClassDeclaration((node) {
      final extendsClause = node.extendsClause;
      if (extendsClause == null) return;

      final superName = extendsClause.superclass.name.lexeme;
      // Match common widget base classes by name. For type resolution we'd
      // need the full type hierarchy which is expensive; name-matching covers
      // the practical cases agents produce.
      const widgetBases = {
        'StatelessWidget',
        'StatefulWidget',
        'State',
        'ConsumerWidget',
        'ConsumerStatefulWidget',
        'HookWidget',
        'HookConsumerWidget',
      };
      if (!widgetBases.contains(superName)) return;

      final startLine = node.leftBracket.offset;
      final endLine = node.rightBracket.offset;
      final source = resolver.source.contents.data;
      // Count newlines in the class body.
      var lineCount = 0;
      for (var i = startLine; i < endLine && i < source.length; i++) {
        if (source[i] == '\n') lineCount++;
      }

      if (lineCount > maxLines) {
        reporter.atNode(
          node,
          LintCode(
            name: 'rigid_max_widget_lines',
            problemMessage:
                'Widget class has $lineCount lines (max $maxLines). '
                'Decompose into smaller, focused widgets.',
            errorSeverity: DiagnosticSeverity.WARNING,
          ),
        );
      }
    });
  }
}
