import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart' show DiagnosticReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:path/path.dart' as p;

import '../../src/config.dart';
import '../../src/utils.dart';

/// Enforces user-defined layer boundaries on imports.
///
/// Only active when `layers` is defined in `rigid_dart.yaml`:
///
/// ```yaml
/// preferences:
///   layers:
///     data: [domain]
///     domain: []
///     features: [domain]
/// ```
///
/// A file in `lib/features/` importing from `lib/data/` would be flagged
/// because `data` is not in the `features` layer's allowed list.
class LayerBoundaries extends DartLintRule {
  const LayerBoundaries() : super(code: _code);

  static const _code = LintCode(
    name: 'rigid_layer_boundaries',
    problemMessage:
        "Import from '{0}' layer is not allowed in '{1}' layer. "
        'Allowed imports: [{2}].',
    errorSeverity: DiagnosticSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    if (isGeneratedFile(resolver.path)) return;
    final config = RigidConfig.forFile(resolver.path);
    if (!config.isEnabled(code.name)) return;

    final layers = config.layers;
    if (layers.isEmpty) return; // No layers defined → rule is silent.

    final filePath = resolver.path;

    // Determine which layer the current file belongs to.
    final currentLayer = _layerForPath(filePath, layers);
    if (currentLayer == null) return; // File not in any defined layer.

    final allowedLayers = layers[currentLayer] ?? [];

    context.registry.addImportDirective((node) {
      final uri = node.uri.stringValue;
      if (uri == null) return;

      // Only check relative imports (package imports have different semantics).
      if (!uri.startsWith('.') && !uri.startsWith('/')) return;

      // Resolve the imported path relative to the current file.
      final currentDir = p.dirname(filePath);
      final importedPath = p.normalize(p.join(currentDir, uri));

      final importedLayer = _layerForPath(importedPath, layers);
      if (importedLayer == null) return; // Imported file not in a defined layer.
      if (importedLayer == currentLayer) return; // Same layer — always OK.

      if (!allowedLayers.contains(importedLayer)) {
        reporter.atNode(
          node,
          LintCode(
            name: 'rigid_layer_boundaries',
            problemMessage:
                "Import from '$importedLayer' layer is not allowed in "
                "'$currentLayer' layer. "
                'Allowed imports: [${allowedLayers.join(', ')}].',
            errorSeverity: DiagnosticSeverity.ERROR,
          ),
        );
      }
    });
  }

  /// Returns the layer name for a file path, or null if not in any layer.
  String? _layerForPath(String filePath, Map<String, List<String>> layers) {
    // Normalize the path to use forward slashes for matching.
    final normalized = filePath.replaceAll(r'\', '/');

    for (final layerName in layers.keys) {
      // Match /lib/<layerName>/ anywhere in the path.
      if (normalized.contains('/lib/$layerName/')) {
        return layerName;
      }
    }
    return null;
  }
}
