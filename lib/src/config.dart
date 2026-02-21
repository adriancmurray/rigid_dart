import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Rule category. Universal rules prevent bugs; opinionated rules enforce
/// architecture preferences and default to OFF unless configured.
enum RuleCategory { universal, opinionated }

/// Maps each rule name to its category.
const _ruleCategories = <String, RuleCategory>{
  // Universal — crash/leak/deprecation prevention
  'rigid_no_expanded_outside_flex': RuleCategory.universal,
  'rigid_no_unbounded_column': RuleCategory.universal,
  'rigid_constrained_text_field': RuleCategory.universal,
  'rigid_no_with_opacity': RuleCategory.universal,
  'rigid_no_will_pop_scope': RuleCategory.universal,
  'rigid_no_build_context_across_async': RuleCategory.universal,
  'rigid_dispose_required': RuleCategory.universal,

  // Opinionated — architecture/style preferences
  'rigid_no_set_state': RuleCategory.opinionated,
  'rigid_no_change_notifier': RuleCategory.opinionated,
  'rigid_exhaustive_async': RuleCategory.opinionated,
  'rigid_no_magic_numbers': RuleCategory.opinionated,
  'rigid_no_hardcoded_colors': RuleCategory.opinionated,
  'rigid_no_hardcoded_text_style': RuleCategory.opinionated,
  'rigid_no_print': RuleCategory.opinionated,
  'rigid_no_dynamic': RuleCategory.opinionated,
  'rigid_require_tests': RuleCategory.opinionated,
};

/// Preset definitions. Each maps rule names to enabled/disabled.
enum Preset {
  /// All 16 rules enabled as errors.
  strict,

  /// Universal rules as errors. Opinionated rules enabled based on
  /// user `preferences` section (default: as warnings).
  balanced,

  /// Only universal rules. All opinionated rules off.
  safety,

  /// Fully manual — per `rules:` section.
  custom,
}

/// Configuration for rigid_dart rules, read from `rigid_dart.yaml`.
class RigidConfig {
  RigidConfig._({
    required this.preset,
    required this.ruleOverrides,
    required this.preferences,
  });

  final Preset preset;
  final Map<String, Object?> ruleOverrides; // rule name → bool | 'warning'
  final Map<String, Object?> preferences;

  // ── Cache ──────────────────────────────────────────────────────────────

  static final Map<String, RigidConfig> _cache = {};

  /// Resolve config for the project containing [filePath].
  /// Caches by project root.
  static RigidConfig forFile(String filePath) {
    final root = _findProjectRoot(filePath);
    if (root == null) return _default;

    return _cache.putIfAbsent(root, () => _loadFromRoot(root));
  }

  static final RigidConfig _default = RigidConfig._(
    preset: Preset.balanced,
    ruleOverrides: const {},
    preferences: const {},
  );

  // ── API ────────────────────────────────────────────────────────────────

  /// Whether [ruleName] is enabled in this configuration.
  bool isEnabled(String ruleName) {
    // 1. Check per-rule overrides first.
    if (ruleOverrides.containsKey(ruleName)) {
      final override = ruleOverrides[ruleName];
      if (override == false) return false;
      if (override == true || override == 'warning') return true;
    }

    // 2. Apply preset logic.
    final category = _ruleCategories[ruleName] ?? RuleCategory.opinionated;

    switch (preset) {
      case Preset.strict:
        return true;
      case Preset.safety:
        return category == RuleCategory.universal;
      case Preset.balanced:
        if (category == RuleCategory.universal) return true;
        return _isEnabledByPreferences(ruleName);
      case Preset.custom:
        // In custom mode, only explicitly listed rules are enabled.
        return ruleOverrides.containsKey(ruleName) &&
            ruleOverrides[ruleName] != false;
    }
  }

  /// Whether this rule should produce a warning instead of an error.
  bool isWarning(String ruleName) {
    if (ruleOverrides.containsKey(ruleName)) {
      return ruleOverrides[ruleName] == 'warning';
    }
    // In balanced mode, opinionated rules default to warning.
    if (preset == Preset.balanced) {
      final category = _ruleCategories[ruleName] ?? RuleCategory.opinionated;
      return category == RuleCategory.opinionated;
    }
    return false;
  }

  // ── Preference-based enablement ────────────────────────────────────────

  bool _isEnabledByPreferences(String ruleName) {
    switch (ruleName) {
      case 'rigid_no_set_state':
      case 'rigid_no_change_notifier':
      case 'rigid_exhaustive_async':
        final sm = preferences['state_management'];
        return sm == 'riverpod';

      case 'rigid_no_hardcoded_colors':
      case 'rigid_no_hardcoded_text_style':
        return preferences['theme_system'] == true;

      case 'rigid_require_tests':
        return preferences['require_tests'] == true;

      case 'rigid_no_magic_numbers':
      case 'rigid_no_print':
      case 'rigid_no_dynamic':
        // These are style preferences — enabled in balanced if preferences
        // don't explicitly disable them.
        return preferences[ruleName] != false;

      default:
        return false;
    }
  }

  // ── File system ────────────────────────────────────────────────────────

  static String? _findProjectRoot(String filePath) {
    var dir = File(filePath).parent;
    for (var i = 0; i < 20; i++) {
      if (File(p.join(dir.path, 'pubspec.yaml')).existsSync()) {
        return dir.path;
      }
      final parent = dir.parent;
      if (parent.path == dir.path) break;
      dir = parent;
    }
    return null;
  }

  static RigidConfig _loadFromRoot(String root) {
    final configFile = File(p.join(root, 'rigid_dart.yaml'));
    if (!configFile.existsSync()) return _default;

    try {
      final yaml = loadYaml(configFile.readAsStringSync());
      if (yaml is! YamlMap) return _default;

      final presetStr = yaml['preset'] as String? ?? 'balanced';
      final preset = Preset.values.firstWhere(
        (p) => p.name == presetStr,
        orElse: () => Preset.balanced,
      );

      final rulesYaml = yaml['rules'];
      final ruleOverrides = <String, Object?>{};
      if (rulesYaml is YamlMap) {
        for (final entry in rulesYaml.entries) {
          final key = 'rigid_${entry.key}';
          ruleOverrides[key] = entry.value;
        }
      }

      final prefsYaml = yaml['preferences'];
      final preferences = <String, Object?>{};
      if (prefsYaml is YamlMap) {
        for (final entry in prefsYaml.entries) {
          preferences[entry.key as String] = entry.value;
        }
      }

      return RigidConfig._(
        preset: preset,
        ruleOverrides: ruleOverrides,
        preferences: preferences,
      );
    } catch (_) {
      return _default;
    }
  }
}
