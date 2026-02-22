/// Rigid Dart — Rust-grade guardrails for Dart/Flutter.
///
/// This is a [custom_lint] plugin that enforces layout safety,
/// state discipline, architecture boundaries, and modern Dart idioms
/// as hard analyzer errors.
///
/// All rules use [TypeChecker]-based type resolution — they catch
/// aliases, subclasses, and reexports, not just string names.
library rigid_dart;

import 'package:custom_lint_builder/custom_lint_builder.dart';

// ── Layout Safety ─────────────────────────────────────────────────────
import 'package:rigid_dart/rules/layout/constrained_text_field.dart';
import 'package:rigid_dart/rules/layout/no_expanded_outside_flex.dart';
import 'package:rigid_dart/rules/layout/no_unbounded_column.dart';
// ── State Discipline ──────────────────────────────────────────────────
import 'package:rigid_dart/rules/state/dispose_required.dart';
import 'package:rigid_dart/rules/state/exhaustive_async.dart';
import 'package:rigid_dart/rules/state/no_build_context_across_async.dart';
import 'package:rigid_dart/rules/state/no_change_notifier.dart';
import 'package:rigid_dart/rules/state/no_set_state.dart';
// ── Architecture ──────────────────────────────────────────────────────
import 'package:rigid_dart/rules/architecture/layer_boundaries.dart';
import 'package:rigid_dart/rules/architecture/no_hardcoded_colors.dart';
import 'package:rigid_dart/rules/architecture/no_hardcoded_text_style.dart';
import 'package:rigid_dart/rules/architecture/no_magic_numbers.dart';
import 'package:rigid_dart/rules/architecture/require_tests.dart';
import 'package:rigid_dart/rules/architecture/no_direct_instantiation.dart';
// ── Quality ───────────────────────────────────────────────────────────
import 'package:rigid_dart/rules/quality/max_widget_lines.dart';
import 'package:rigid_dart/rules/quality/min_test_assertions.dart';
import 'package:rigid_dart/rules/quality/no_hardcoded_strings.dart';
import 'package:rigid_dart/rules/quality/no_raw_async.dart';
import 'package:rigid_dart/rules/quality/require_key_in_list.dart';
// ── Freshness ─────────────────────────────────────────────────────────
import 'package:rigid_dart/rules/freshness/no_dynamic.dart';
import 'package:rigid_dart/rules/freshness/no_print.dart';
import 'package:rigid_dart/rules/freshness/no_will_pop_scope.dart';
import 'package:rigid_dart/rules/freshness/no_with_opacity.dart';

PluginBase createPlugin() => _RigidDartPlugin();

class _RigidDartPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => const [
    // Phase 1: Layout Safety (3 rules)
    NoExpandedOutsideFlex(),
    NoUnboundedColumn(),
    ConstrainedTextField(),
    // Phase 2: State Discipline (5 rules)
    NoSetState(),
    NoChangeNotifier(),
    ExhaustiveAsync(),
    NoBuildContextAcrossAsync(),
    DisposeRequired(),
    // Phase 3: Architecture (6 rules)
    NoHardcodedColors(),
    NoHardcodedTextStyle(),
    NoMagicNumbers(),
    RequireTests(),
    LayerBoundaries(),
    NoDirectInstantiation(),
    // Phase 4: Freshness (4 rules)
    NoWillPopScope(),
    NoWithOpacity(),
    NoDynamic(),
    NoPrint(),
    // Phase 5: Quality (5 rules)
    MaxWidgetLines(),
    NoRawAsync(),
    MinTestAssertions(),
    RequireKeyInList(),
    NoHardcodedStrings(),
  ];
}
