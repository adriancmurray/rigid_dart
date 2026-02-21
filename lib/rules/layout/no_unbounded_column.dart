import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart' show DiagnosticReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:analyzer/dart/ast/ast.dart';

/// Column/ListView inside another scrollable without shrinkWrap or
/// bounded height constraints.
class NoUnboundedColumn extends DartLintRule {
  const NoUnboundedColumn() : super(code: _code);

  static const _code = LintCode(
    name: 'rigid_no_unbounded_column',
    problemMessage:
        'Column or ListView nested inside a scrollable without '
        'shrinkWrap or bounded height. Wrap in SizedBox/ConstrainedBox '
        'or set shrinkWrap: true.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  static const _scrollableTypes = {
    'ListView', 'GridView', 'SingleChildScrollView', 'CustomScrollView',
  };
  static const _verticalTypes = {'Column', 'ListView'};

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      final typeName = node.constructorName.type.name.lexeme;
      if (!_verticalTypes.contains(typeName)) return;

      final scrollableAncestor = _findAncestorOfType(node, _scrollableTypes);
      if (scrollableAncestor == null) return;
      if (typeName == 'ListView' && _hasShrinkWrap(node)) return;
      if (_hasBoundedHeightAncestor(node, scrollableAncestor)) return;

      reporter.atNode(node.constructorName, code);
    });
  }

  static bool _hasShrinkWrap(InstanceCreationExpression node) {
    for (final arg in node.argumentList.arguments) {
      if (arg is NamedExpression && arg.name.label.name == 'shrinkWrap') {
        final expr = arg.expression;
        if (expr is BooleanLiteral && expr.value) return true;
      }
    }
    return false;
  }

  static bool _hasBoundedHeightAncestor(
    InstanceCreationExpression node,
    InstanceCreationExpression ancestor,
  ) {
    var current = node.parent;
    while (current != null && current != ancestor) {
      if (current is InstanceCreationExpression) {
        final name = current.constructorName.type.name.lexeme;
        if (name == 'SizedBox' || name == 'ConstrainedBox' || name == 'Container') {
          if (_hasHeightArgument(current)) return true;
        }
      }
      current = current.parent;
    }
    return false;
  }

  static bool _hasHeightArgument(InstanceCreationExpression node) {
    for (final arg in node.argumentList.arguments) {
      if (arg is NamedExpression) {
        final name = arg.name.label.name;
        if (name == 'height' || name == 'constraints') return true;
      }
    }
    return false;
  }

  static InstanceCreationExpression? _findAncestorOfType(
    InstanceCreationExpression node,
    Set<String> types,
  ) {
    var current = node.parent;
    while (current != null) {
      if (current is InstanceCreationExpression) {
        final name = current.constructorName.type.name.lexeme;
        if (types.contains(name)) return current;
      }
      current = current.parent;
    }
    return null;
  }
}
