import 'package:analyzer/error/error.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Quick fix: Replace `.withOpacity(x)` with `.withValues(alpha: x)`.
class NoWithOpacityFix extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    AnalysisError analysisError,
    List<AnalysisError> others,
  ) {
    context.registry.addMethodInvocation((node) {
      if (node.methodName.name != 'withOpacity') return;
      if (!analysisError.sourceRange.intersects(node.sourceRange)) return;

      final args = node.argumentList.arguments;
      if (args.isEmpty) return;
      final opacityArg = args.first.toSource();
      final target = node.realTarget?.toSource() ?? '';

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Replace with .withValues(alpha: $opacityArg)',
        priority: 1,
      );

      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleReplacement(
          node.sourceRange,
          '$target.withValues(alpha: $opacityArg)',
        );
      });
    });
  }
}

/// Quick fix: Replace `WillPopScope` with `PopScope`.
class NoWillPopScopeFix extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    AnalysisError analysisError,
    List<AnalysisError> others,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      final typeName = node.constructorName.type.name.lexeme;
      if (typeName != 'WillPopScope') return;
      if (!analysisError.sourceRange.intersects(node.sourceRange)) return;

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Replace with PopScope',
        priority: 1,
      );

      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleReplacement(
          node.constructorName.type.sourceRange,
          'PopScope',
        );
      });
    });
  }
}

/// Quick fix: Replace `dynamic` with `Object?`.
class NoDynamicFix extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    AnalysisError analysisError,
    List<AnalysisError> others,
  ) {
    context.registry.addNamedType((node) {
      if (node.name.lexeme != 'dynamic') return;
      if (!analysisError.sourceRange.intersects(node.sourceRange)) return;

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Replace with Object?',
        priority: 1,
      );

      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleReplacement(node.sourceRange, 'Object?');
      });
    });
  }
}
