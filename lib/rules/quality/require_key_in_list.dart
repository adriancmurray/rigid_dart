import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart' show DiagnosticReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../src/config.dart';
import '../../src/utils.dart';

/// Flags widgets constructed inside list-building contexts without a `Key`.
///
/// When widgets in a `ListView.builder`, `Column`, `Row`, or similar
/// lack explicit keys, Flutter can mix up widget state during reorders,
/// insertions, or removals. Agents virtually never add keys.
///
/// Catches:
/// - `ListView.builder` / `ListView.separated` `itemBuilder` callbacks
/// - `List.generate` that returns widgets
/// - `map()` chains on lists that return widgets
class RequireKeyInList extends DartLintRule {
  const RequireKeyInList() : super(code: _code);

  static const _code = LintCode(
    name: 'rigid_require_key_in_list',
    problemMessage:
        'Widget in list builder has no explicit Key parameter. '
        'Add a Key (e.g. ValueKey, ObjectKey) to prevent state bugs during '
        'reorders and insertions.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  // Widget constructors that agents commonly use in lists.
  static const _widgetNames = {
    'Card',
    'ListTile',
    'Container',
    'Padding',
    'Column',
    'Row',
    'SizedBox',
    'Dismissible',
    'InkWell',
    'GestureDetector',
    'AnimatedContainer',
    'Opacity',
    'DecoratedBox',
    'ClipRRect',
    'Stack',
    'Wrap',
    'Align',
    'Center',
  };

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    if (isGeneratedFile(resolver.path)) return;
    if (!RigidConfig.forFile(resolver.path).isEnabled(code.name)) return;
    if (isTestFile(resolver.path)) return;

    context.registry.addMethodInvocation((node) {
      // Check for ListView.builder / ListView.separated patterns.
      final methodName = node.methodName.name;
      final target = node.target;

      // ListView.builder(..., itemBuilder: (ctx, i) => Widget(...))
      if (target is SimpleIdentifier &&
          target.name == 'ListView' &&
          (methodName == 'builder' || methodName == 'separated')) {
        _checkItemBuilder(node, reporter);
        return;
      }

      // someList.map((item) => Widget(...))
      if (methodName == 'map') {
        _checkMapCallback(node, reporter);
        return;
      }
    });

    // List.generate(n, (i) => Widget(...))
    context.registry.addInstanceCreationExpression((node) {
      final name = node.constructorName.type.name.lexeme;
      if (name == 'List') {
        final constructorName = node.constructorName.name?.name;
        if (constructorName == 'generate') {
          _checkGenerateCallback(node, reporter);
        }
      }
    });
  }

  void _checkItemBuilder(MethodInvocation listViewCall, DiagnosticReporter reporter) {
    for (final arg in listViewCall.argumentList.arguments) {
      if (arg is NamedExpression && arg.name.label.name == 'itemBuilder') {
        final expr = arg.expression;
        if (expr is FunctionExpression) {
          _checkBodyForKeylessWidgets(expr.body, reporter);
        }
      }
    }
  }

  void _checkMapCallback(MethodInvocation mapCall, DiagnosticReporter reporter) {
    final args = mapCall.argumentList.arguments;
    if (args.isNotEmpty) {
      final first = args.first;
      if (first is FunctionExpression) {
        _checkBodyForKeylessWidgets(first.body, reporter);
      }
    }
  }

  void _checkGenerateCallback(InstanceCreationExpression node, DiagnosticReporter reporter) {
    final args = node.argumentList.arguments;
    if (args.length >= 2) {
      final callback = args[1];
      if (callback is FunctionExpression) {
        _checkBodyForKeylessWidgets(callback.body, reporter);
      }
    }
  }

  void _checkBodyForKeylessWidgets(FunctionBody body, DiagnosticReporter reporter) {
    // Find the return expression(s) in the body.
    void visitForReturn(AstNode node) {
      if (node is ReturnStatement && node.expression != null) {
        _checkWidgetExpression(node.expression!, reporter);
      }
      // For expression bodies: (i) => Widget(...)
      if (node is ExpressionFunctionBody) {
        _checkWidgetExpression(node.expression, reporter);
        return;
      }
      // Don't recurse into nested functions.
      if (node is FunctionExpression) return;
      node.childEntities.whereType<AstNode>().forEach(visitForReturn);
    }

    visitForReturn(body);
  }

  void _checkWidgetExpression(Expression expr, DiagnosticReporter reporter) {
    if (expr is! InstanceCreationExpression) return;

    final typeName = expr.constructorName.type.name.lexeme;
    if (!_widgetNames.contains(typeName)) return;

    // Check if 'key' is among the named arguments.
    final hasKey = expr.argumentList.arguments
        .whereType<NamedExpression>()
        .any((arg) => arg.name.label.name == 'key');

    if (!hasKey) {
      reporter.atNode(expr.constructorName, code);
    }
  }
}
