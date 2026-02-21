import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart' show DiagnosticReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Ban ChangeNotifier subclasses. Use Riverpod Notifier/AsyncNotifier.
class NoChangeNotifier extends DartLintRule {
  const NoChangeNotifier() : super(code: _code);

  static const _code = LintCode(
    name: 'rigid_no_change_notifier',
    problemMessage:
        'ChangeNotifier is banned. Use Riverpod Notifier or '
        'AsyncNotifier for reactive state management.',
    errorSeverity: DiagnosticSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addClassDeclaration((node) {
      final extendsClause = node.extendsClause;
      if (extendsClause != null) {
        final superName = extendsClause.superclass.name.lexeme;
        if (superName == 'ChangeNotifier') {
          reporter.atNode(extendsClause.superclass, code);
        }
      }

      final withClause = node.withClause;
      if (withClause != null) {
        for (final mixin in withClause.mixinTypes) {
          if (mixin.name.lexeme == 'ChangeNotifier') {
            reporter.atNode(mixin, code);
          }
        }
      }
    });
  }
}
