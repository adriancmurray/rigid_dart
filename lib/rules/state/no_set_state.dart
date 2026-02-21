import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart' show DiagnosticReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../src/types.dart';
import '../../src/utils.dart';

/// Bans `setState()` calls. Use Riverpod instead.
///
/// Type-resolved: checks that the receiver is actually `State<T>`,
/// not just any method named `setState`.
class NoSetState extends DartLintRule {
  const NoSetState() : super(code: _code);

  static const _code = LintCode(
    name: 'rigid_no_set_state',
    problemMessage:
        'setState() is banned. Use Riverpod (ref.read/ref.watch) '
        'for state management instead.',
    errorSeverity: DiagnosticSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    if (isGeneratedFile(resolver.path)) return;

    context.registry.addMethodInvocation((node) {
      if (node.methodName.name != 'setState') return;

      // Type-resolve: is the receiver a State<T>?
      final targetType = node.realTarget?.staticType;
      if (targetType != null) {
        if (!FlutterTypes.state.isAssignableFromType(targetType)) return;
      }
      // If no target (implicit this), we're inside a State class — still flag.

      reporter.atNode(node.methodName, code);
    });
  }
}
