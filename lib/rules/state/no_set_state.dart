import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart' show DiagnosticReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Ban setState entirely. Use Riverpod or equivalent.
class NoSetState extends DartLintRule {
  const NoSetState() : super(code: _code);

  static const _code = LintCode(
    name: 'rigid_no_set_state',
    problemMessage:
        'setState is banned. Use Riverpod (ref.read/ref.watch) for '
        'state management instead of StatefulWidget + setState.',
    errorSeverity: DiagnosticSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      if (node.methodName.name == 'setState') {
        reporter.atNode(node.methodName, code);
      }
    });
  }
}
