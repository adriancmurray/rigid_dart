/// Rigid Dart -- Rust-grade guardrails for Dart/Flutter.
///
/// This is a [custom_lint] plugin that enforces layout safety,
/// state discipline, architecture boundaries, and modern Dart idioms
/// as hard analyzer errors.
library rigid_dart;

import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:rigid_dart/rules/layout/no_expanded_outside_flex.dart';
import 'package:rigid_dart/rules/layout/no_unbounded_column.dart';
import 'package:rigid_dart/rules/layout/constrained_text_field.dart';
import 'package:rigid_dart/rules/state/no_set_state.dart';
import 'package:rigid_dart/rules/state/no_change_notifier.dart';
import 'package:rigid_dart/rules/state/exhaustive_async.dart';
import 'package:rigid_dart/rules/architecture/no_hardcoded_colors.dart';
import 'package:rigid_dart/rules/architecture/no_hardcoded_text_style.dart';
import 'package:rigid_dart/rules/architecture/no_magic_numbers.dart';
import 'package:rigid_dart/rules/freshness/no_will_pop_scope.dart';
import 'package:rigid_dart/rules/freshness/no_with_opacity.dart';
import 'package:rigid_dart/rules/freshness/no_dynamic.dart';

/// Plugin entry point for custom_lint.
PluginBase createPlugin() => _RigidDartPlugin();

class _RigidDartPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        // Phase 1: Layout Safety
        const NoExpandedOutsideFlex(),
        const NoUnboundedColumn(),
        const ConstrainedTextField(),

        // Phase 2: State Discipline
        const NoSetState(),
        const NoChangeNotifier(),
        const ExhaustiveAsync(),

        // Phase 3: Architecture Enforcement
        const NoHardcodedColors(),
        const NoHardcodedTextStyle(),
        const NoMagicNumbers(),

        // Phase 4: Freshness / Modern Dart
        const NoWillPopScope(),
        const NoWithOpacity(),
        const NoDynamic(),
      ];
}
