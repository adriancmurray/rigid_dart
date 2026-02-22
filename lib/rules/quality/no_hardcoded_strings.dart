import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart' show DiagnosticReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../src/config.dart';
import '../../src/utils.dart';

/// Flags hardcoded string literals inside UI text widgets.
///
/// Agents always hardcode strings: `Text('Hello World')`. For apps
/// that need localization or maintainable string resources, this is
/// a code smell that compounds rapidly.
///
/// Catches string literals in:
/// - `Text('...')`
/// - `Tooltip(message: '...')`
/// - `InputDecoration(labelText: '...', hintText: '...')`
/// - `AppBar(title: Text('...'))`
///
/// Skips:
/// - Test files
/// - Files with `l10n` or `intl` in the path
/// - Empty strings and single-character strings
/// - Strings that look like keys/identifiers (no spaces)
class NoHardcodedStrings extends DartLintRule {
  const NoHardcodedStrings() : super(code: _code);

  static const _code = LintCode(
    name: 'rigid_no_hardcoded_strings',
    problemMessage:
        "Don't hardcode user-visible strings. "
        'Use your localization system (AppLocalizations, easy_localization, etc.) '
        'or a string constants file.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  /// Widget constructors where positional string args are user-visible text.
  static const _textWidgets = {'Text', 'SelectableText', 'RichText'};

  /// Named parameters that contain user-visible strings.
  static const _textParams = {
    'labelText',
    'hintText',
    'helperText',
    'errorText',
    'counterText',
    'prefixText',
    'suffixText',
    'semanticsLabel',
    'label',
    'message',
    'tooltip',
    'title',
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

    // Skip l10n/intl files.
    final path = resolver.path.toLowerCase();
    if (path.contains('l10n') || path.contains('intl') ||
        path.contains('string') || path.contains('constants')) {
      return;
    }

    context.registry.addInstanceCreationExpression((node) {
      final typeName = node.constructorName.type.name.lexeme;

      // Check Text('hardcoded') — first positional arg.
      if (_textWidgets.contains(typeName)) {
        final args = node.argumentList.arguments;
        if (args.isNotEmpty) {
          final first = args.first;
          if (first is! NamedExpression && first is SimpleStringLiteral) {
            if (_isUserVisible(first.value)) {
              reporter.atNode(first, code);
            }
          }
        }
      }

      // Check named params like labelText, hintText, message, etc.
      for (final arg in node.argumentList.arguments) {
        if (arg is NamedExpression &&
            _textParams.contains(arg.name.label.name)) {
          final expr = arg.expression;
          if (expr is SimpleStringLiteral && _isUserVisible(expr.value)) {
            reporter.atNode(expr, code);
          }
        }
      }
    });

    // Also check method calls: Tooltip(message: '...') etc.
    context.registry.addMethodInvocation((node) {
      for (final arg in node.argumentList.arguments) {
        if (arg is NamedExpression &&
            _textParams.contains(arg.name.label.name)) {
          final expr = arg.expression;
          if (expr is SimpleStringLiteral && _isUserVisible(expr.value)) {
            reporter.atNode(expr, code);
          }
        }
      }
    });
  }

  /// Returns true if the string looks like user-visible text.
  /// Skips empty, single-char, identifier-like (no spaces), and
  /// strings that look like keys (e.g. 'user_name').
  bool _isUserVisible(String value) {
    if (value.isEmpty) return false;
    if (value.length <= 1) return false;
    // Strings with spaces are almost certainly user-visible text.
    if (value.contains(' ')) return true;
    // Multi-word camelCase might be a label.
    if (value.length > 3 && RegExp(r'[a-z][A-Z]').hasMatch(value)) return true;
    return false;
  }
}
