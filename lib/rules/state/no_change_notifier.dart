
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart' show DiagnosticReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../src/types.dart';
import '../../src/utils.dart';

/// Bans `ChangeNotifier` and `ValueNotifier` subclasses.
///
/// Type-resolved: uses [TypeChecker.isAssignableFrom] to catch any class
/// that extends, mixes in, or implements ChangeNotifier — even through
/// intermediate classes.
class NoChangeNotifier extends DartLintRule {
  const NoChangeNotifier() : super(code: _code);

  static const _code = LintCode(
    name: 'rigid_no_change_notifier',
    problemMessage:
        'ChangeNotifier/ValueNotifier is banned. '
        'Use Riverpod Notifier or AsyncNotifier for state management.',
    errorSeverity: DiagnosticSeverity.ERROR,
  );

  static const _notifierFamily = TypeChecker.any([
    FlutterTypes.changeNotifier,
    FlutterTypes.valueNotifier,
  ]);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    if (isGeneratedFile(resolver.path)) return;

    context.registry.addClassDeclaration((node) {
      final element = node.declaredFragment?.element;
      if (element == null) return;

      // Check if this class is assignable to ChangeNotifier/ValueNotifier.
      if (_notifierFamily.isAssignableFrom(element)) {
        reporter.atNode(node, code);
      }
    });
  }
}
