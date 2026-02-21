import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart' show DiagnosticReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../src/config.dart';
import '../../src/utils.dart';

/// Flags async functions that contain `await` but no `try/catch`.
///
/// Agents routinely generate `onPressed: () async { await api.fetch(); }`
/// with zero error handling. If the call throws, the app crashes silently.
///
/// Excludes:
/// - Test files and generated files
/// - `main()` functions (typically use runZonedGuarded)
class NoRawAsync extends DartLintRule {
  const NoRawAsync() : super(code: _code);

  static const _code = LintCode(
    name: 'rigid_no_raw_async',
    problemMessage:
        'Async method contains await without try/catch. '
        'Wrap in try/catch or use a Result type for error handling.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    if (isGeneratedFile(resolver.path)) return;
    if (!RigidConfig.forFile(resolver.path).isEnabled(code.name)) return;
    if (isTestFile(resolver.path)) return;

    // Check function declarations (top-level & class methods).
    context.registry.addFunctionDeclaration((node) {
      // Skip main() — typically wrapped in runZonedGuarded.
      if (node.name.lexeme == 'main') return;
      _checkBody(node.functionExpression.body, node, reporter);
    });

    context.registry.addMethodDeclaration((node) {
      _checkBody(node.body, node, reporter);
    });

    // Check function expressions (lambdas, callbacks).
    context.registry.addFunctionExpression((node) {
      // Skip if it's part of a named function declaration (handled above).
      if (node.parent is FunctionDeclaration) return;
      _checkBody(node.body, null, reporter);
    });
  }

  // Methods whose awaits are inherently safe (won't throw in normal use).
  static const _safeAwaits = {
    'showDialog',
    'showModalBottomSheet',
    'showCupertinoDialog',
    'showDatePicker',
    'showTimePicker',
    'showSearch',
    'showMenu',
    'push',
    'pushNamed',
    'pushReplacement',
    'pushReplacementNamed',
    'popAndPushNamed',
    'pushAndRemoveUntil',
    'pushNamedAndRemoveUntil',
    'maybePop',
    'delayed',
    'wait',
    'animateTo',
    'forward',
    'reverse',
    'fling',
    'nextFrame',
    'precacheImage',
    'ensureInitialized',
  };

  void _checkBody(FunctionBody body, AstNode? nameNode, DiagnosticReporter reporter) {
    // Only check async bodies.
    if (body.keyword?.lexeme != 'async') return;
    if (body.star != null) return; // async* generators are different.

    // Walk the body to find awaits, try statements, and safe calls.
    var hasUnsafeAwait = false;
    var hasTry = false;

    void visit(AstNode node) {
      if (node is TryStatement) hasTry = true;
      if (node is AwaitExpression) {
        // Check if the awaited expression is a known safe method.
        final expr = node.expression;
        if (expr is MethodInvocation) {
          if (!_safeAwaits.contains(expr.methodName.name)) {
            hasUnsafeAwait = true;
          }
        } else if (expr is FunctionExpressionInvocation) {
          hasUnsafeAwait = true; // Dynamic calls are never safe.
        } else {
          hasUnsafeAwait = true;
        }
      }
      // Don't recurse into nested functions — they have their own scope.
      if (node is FunctionExpression && node != body.parent) return;
      if (node is FunctionDeclaration) return;
      node.childEntities.whereType<AstNode>().forEach(visit);
    }

    if (body is BlockFunctionBody) {
      visit(body.block);
    } else if (body is ExpressionFunctionBody) {
      visit(body.expression);
    }

    if (hasUnsafeAwait && !hasTry) {
      final reportNode = nameNode ?? body;
      reporter.atNode(reportNode, code);
    }
  }
}
