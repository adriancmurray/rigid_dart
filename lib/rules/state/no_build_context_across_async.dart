import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart' show DiagnosticReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../src/utils.dart';

/// Catches BuildContext used after an async gap (await).
///
/// Accessing a BuildContext after an await can crash if the widget has been
/// unmounted during the async operation. This is a real production crash
/// that Rust's ownership model would prevent.
class NoBuildContextAcrossAsync extends DartLintRule {
  const NoBuildContextAcrossAsync() : super(code: _code);

  static const _code = LintCode(
    name: 'rigid_no_build_context_across_async',
    problemMessage:
        'BuildContext used after an await. The widget may have been '
        'unmounted. Check context.mounted before use, or restructure '
        'to capture values before the await.',
    errorSeverity: DiagnosticSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    if (isGeneratedFile(resolver.path)) return;

    context.registry.addMethodDeclaration((node) {
      if (node.body is! BlockFunctionBody) return;
      if (!node.body.isAsynchronous) return;

      final body = node.body as BlockFunctionBody;
      _checkBlock(body.block, reporter);
    });

    context.registry.addFunctionExpression((node) {
      if (node.body is! BlockFunctionBody) return;
      if (!node.body.isAsynchronous) return;

      final body = node.body as BlockFunctionBody;
      _checkBlock(body.block, reporter);
    });
  }

  void _checkBlock(Block block, DiagnosticReporter reporter) {
    var seenAwait = false;

    for (final statement in block.statements) {
      // Track if we've passed an await expression.
      if (_containsAwait(statement)) {
        seenAwait = true;
        continue;
      }

      if (!seenAwait) continue;

      // After an await, check for mounted guard.
      if (_isMountedCheck(statement)) {
        return;
      }

      // Look for BuildContext usage in any statement after an await.
      final contextRefs = <AstNode>[];
      statement.accept(_ContextFinder(contextRefs));

      for (final ref in contextRefs) {
        reporter.atNode(ref, code);
      }
    }
  }

  bool _containsAwait(AstNode node) {
    if (node is ExpressionStatement && node.expression is AwaitExpression) {
      return true;
    }
    if (node is VariableDeclarationStatement) {
      for (final decl in node.variables.variables) {
        if (decl.initializer is AwaitExpression) return true;
      }
    }
    var found = false;
    node.accept(_AwaitFinder(() => found = true));
    return found;
  }

  bool _isMountedCheck(Statement statement) {
    if (statement is IfStatement) {
      final source = statement.expression.toSource();
      if (source.contains('mounted')) return true;
    }
    return false;
  }
}

class _AwaitFinder extends RecursiveAstVisitor<void> {
  _AwaitFinder(this.onFound);
  final void Function() onFound;

  @override
  void visitAwaitExpression(AwaitExpression node) {
    onFound();
  }
}

class _ContextFinder extends RecursiveAstVisitor<void> {
  _ContextFinder(this.results);
  final List<AstNode> results;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name == 'context') {
      final parent = node.parent;
      if (parent is MethodInvocation ||
          parent is PrefixedIdentifier ||
          parent is PropertyAccess ||
          parent is ArgumentList) {
        results.add(node);
      }
    }
    super.visitSimpleIdentifier(node);
  }
}
