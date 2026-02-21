import 'package:analyzer/dart/ast/ast.dart';

/// Returns `true` for generated files that should be excluded from linting.
///
/// Matches: `.g.dart`, `.freezed.dart`, `.gr.dart`, `.mocks.dart`,
/// `.gen.dart`, `.pb.dart` (protobuf).
bool isGeneratedFile(String path) {
  return path.endsWith('.g.dart') ||
      path.endsWith('.freezed.dart') ||
      path.endsWith('.gr.dart') ||
      path.endsWith('.mocks.dart') ||
      path.endsWith('.gen.dart') ||
      path.endsWith('.pb.dart');
}

/// Returns `true` if [path] is a test file.
bool isTestFile(String path) {
  return path.contains('/test/') || path.contains('/test_driver/');
}

/// Returns `true` if the node is inside a theme definition context —
/// a class, function, or variable whose name contains "theme", "palette",
/// or "color".
bool isInsideThemeDefinition(AstNode node) {
  var current = node.parent;
  while (current != null) {
    if (current is ClassDeclaration) {
      final name = current.name.lexeme.toLowerCase();
      if (name.contains('theme') ||
          name.contains('palette') ||
          name.contains('color')) {
        return true;
      }
    }
    if (current is FunctionDeclaration) {
      if (current.name.lexeme.toLowerCase().contains('theme')) return true;
    }
    if (current is VariableDeclaration) {
      final name = current.name.lexeme.toLowerCase();
      if (name.contains('theme') ||
          name.contains('color') ||
          name.contains('palette')) {
        return true;
      }
    }
    current = current.parent;
  }
  return false;
}
