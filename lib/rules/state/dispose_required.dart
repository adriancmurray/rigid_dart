import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart' show DiagnosticReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../src/types.dart';
import '../../src/utils.dart';

/// Disposable controllers must be disposed in the dispose() method.
class DisposeRequired extends DartLintRule {
  const DisposeRequired() : super(code: _code);

  static const _code = LintCode(
    name: 'rigid_dispose_required',
    problemMessage:
        'Disposable resource created but may not be disposed. '
        'Call .dispose() or .cancel() in the dispose() method to prevent '
        'memory leaks.',
    errorSeverity: DiagnosticSeverity.ERROR,
  );

  static const _disposableTypes = TypeChecker.any([
    FlutterTypes.animationController,
    FlutterTypes.scrollController,
    FlutterTypes.textEditingController,
    FlutterTypes.focusNode,
    FlutterTypes.tabController,
    FlutterTypes.pageController,
  ]);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    if (isGeneratedFile(resolver.path)) return;

    context.registry.addClassDeclaration((node) {
      // Collect field names that are disposable.
      final disposableFields = <String>{};

      for (final member in node.members) {
        if (member is FieldDeclaration) {
          for (final variable in member.fields.variables) {
            final type = variable.declaredFragment?.element.type;
            if (type != null && _disposableTypes.isAssignableFromType(type)) {
              disposableFields.add(variable.name.lexeme);
            }
          }
        }
      }

      if (disposableFields.isEmpty) return;

      // Find dispose() method and check what it disposes.
      final disposedFields = <String>{};
      for (final member in node.members) {
        if (member is MethodDeclaration && member.name.lexeme == 'dispose') {
          member.accept(_DisposeFinder(disposedFields));
        }
      }

      // Report fields that are not disposed.
      for (final member in node.members) {
        if (member is FieldDeclaration) {
          for (final variable in member.fields.variables) {
            final name = variable.name.lexeme;
            if (disposableFields.contains(name) &&
                !disposedFields.contains(name)) {
              reporter.atNode(variable, code);
            }
          }
        }
      }
    });
  }
}

class _DisposeFinder extends RecursiveAstVisitor<void> {
  _DisposeFinder(this.names);
  final Set<String> names;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final methodName = node.methodName.name;
    if (methodName == 'dispose' || methodName == 'cancel') {
      final target = node.realTarget;
      if (target is SimpleIdentifier) {
        names.add(target.name);
      }
      if (target is PrefixedIdentifier) {
        names.add(target.identifier.name);
      }
    }
    super.visitMethodInvocation(node);
  }
}
