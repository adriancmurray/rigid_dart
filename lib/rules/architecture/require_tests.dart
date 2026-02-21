import 'dart:io';

import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart' show DiagnosticReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:path/path.dart' as p;

import '../../src/utils.dart';

/// Flags `lib/` files that have no corresponding `_test.dart` file.
///
/// This enforces a "test-first" discipline — every production file must
/// have adversarial tests. The rule checks by path convention:
///
///   `lib/src/foo/bar.dart` → expects `test/src/foo/bar_test.dart`
///   `lib/models/user.dart` → expects `test/models/user_test.dart`
///
/// Excludes:
/// - Generated files (`.g.dart`, `.freezed.dart`, etc.)
/// - Barrel/export files (files with only export directives)
/// - The root `lib/<package>.dart` library file
class RequireTests extends DartLintRule {
  const RequireTests() : super(code: _code);

  static const _code = LintCode(
    name: 'rigid_require_tests',
    problemMessage:
        'This file has no corresponding test file. '
        'Create {0} with adversarial tests.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    final filePath = resolver.path;
    if (isGeneratedFile(filePath)) return;
    if (isTestFile(filePath)) return;

    // Only check files under lib/.
    if (!filePath.contains('${p.separator}lib${p.separator}')) return;

    // Extract the path relative to lib/.
    final libIndex = filePath.indexOf('${p.separator}lib${p.separator}');
    final projectRoot = filePath.substring(0, libIndex);
    final relativePath =
        filePath.substring(libIndex + '${p.separator}lib${p.separator}'.length);

    // Skip the root library file (e.g., lib/my_package.dart).
    if (!relativePath.contains(p.separator)) {
      // Root-level lib file — skip.
      return;
    }

    // Compute expected test file path.
    final baseName = p.basenameWithoutExtension(relativePath);
    final dirName = p.dirname(relativePath);
    final testPath =
        p.join(projectRoot, 'test', dirName, '${baseName}_test.dart');

    if (!File(testPath).existsSync()) {
      // Report at the library/compilation-unit level (first line).
      context.registry.addCompilationUnit((node) {
        reporter.atNode(
          node,
          LintCode(
            name: 'rigid_require_tests',
            problemMessage:
                'This file has no corresponding test file. '
                'Create test/${dirName}/${baseName}_test.dart with adversarial tests.',
            errorSeverity: DiagnosticSeverity.WARNING,
          ),
        );
      });
    }
  }
}
