import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart' show DiagnosticReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../src/config.dart';
import '../../src/utils.dart';

/// Flags direct instantiation of infrastructure classes inside widgets.
///
/// Agents frequently write `final repo = UserRepository();` inside a
/// `build` method instead of reading from a DI container or provider
/// provider. This creates tight coupling and makes testing impossible.
///
/// Catches class names ending in:
/// - `Repository`
/// - `Service`
/// - `Api` / `API`
/// - `Client`
/// - `DataSource`
/// - `UseCase`
///
/// Only fires inside classes that extend widget types (StatelessWidget,
/// StatefulWidget, State, ConsumerWidget, HookWidget, etc.).
class NoDirectInstantiation extends DartLintRule {
  const NoDirectInstantiation() : super(code: _code);

  static const _code = LintCode(
    name: 'rigid_no_direct_instantiation',
    problemMessage:
        "Don't instantiate '{0}' directly in a widget. "
        'Read it from a provider or inject via constructor.',
    errorSeverity: DiagnosticSeverity.ERROR,
  );

  static const _infraSuffixes = [
    'Repository',
    'Service',
    'Api',
    'API',
    'Client',
    'DataSource',
    'UseCase',
  ];

  static const _widgetBases = {
    'StatelessWidget',
    'StatefulWidget',
    'State',
    'ConsumerWidget',
    'ConsumerStatefulWidget',
    'HookWidget',
    'HookConsumerWidget',
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

    context.registry.addClassDeclaration((node) {
      // Only check widget classes.
      final extendsClause = node.extendsClause;
      if (extendsClause == null) return;
      final superName = extendsClause.superclass.name.lexeme;
      if (!_widgetBases.contains(superName)) return;

      // Walk the class body looking for direct instantiation.
      _visitForInfraInstantiation(node, reporter);
    });
  }

  void _visitForInfraInstantiation(
    ClassDeclaration classNode,
    DiagnosticReporter reporter,
  ) {
    void visit(AstNode node) {
      if (node is InstanceCreationExpression) {
        final typeName = node.constructorName.type.name.lexeme;
        for (final suffix in _infraSuffixes) {
          if (typeName.endsWith(suffix) && typeName != suffix) {
            reporter.atNode(
              node.constructorName,
              LintCode(
                name: 'rigid_no_direct_instantiation',
                problemMessage:
                    "Don't instantiate '$typeName' directly in a widget. "
                    'Read it from a provider or inject via constructor.',
                errorSeverity: DiagnosticSeverity.ERROR,
              ),
            );
            break;
          }
        }
      }
      // Don't recurse into nested class declarations.
      if (node is ClassDeclaration && node != classNode) return;
      node.childEntities.whereType<AstNode>().forEach(visit);
    }

    visit(classNode);
  }
}
