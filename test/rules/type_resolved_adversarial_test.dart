import 'package:rigid_dart/rules/layout/no_expanded_outside_flex.dart';
import 'package:rigid_dart/rules/layout/no_unbounded_column.dart';
import 'package:rigid_dart/rules/layout/constrained_text_field.dart';
import 'package:rigid_dart/rules/state/no_set_state.dart';
import 'package:rigid_dart/rules/state/no_change_notifier.dart';
import 'package:rigid_dart/rules/state/exhaustive_async.dart';
import 'package:rigid_dart/rules/state/dispose_required.dart';
import 'package:rigid_dart/rules/architecture/no_hardcoded_colors.dart';
import 'package:rigid_dart/rules/architecture/no_hardcoded_text_style.dart';
import 'package:rigid_dart/rules/freshness/no_will_pop_scope.dart';
import 'package:rigid_dart/rules/freshness/no_with_opacity.dart';
import 'package:test/test.dart';

import '../test_helper.dart';

/// Adversarial false-positive test suite.
///
/// Fixture defines classes with the SAME NAMES as Flutter widgets
/// (Expanded, Color, ChangeNotifier, etc.) but they are NOT from Flutter.
///
/// TypeChecker.fromName(..., packageName: 'flutter') must NOT match them.
/// If ANY rule fires, it's a false positive and the test fails.
void main() {
  final file = fixture('test/fixtures/type_resolved_adversarial.dart');

  test('fixture file exists', () {
    expect(file.existsSync(), isTrue);
  });

  group('Layout rules — zero false positives on non-Flutter types', () {
    test('no_expanded_outside_flex', () async {
      final errors =
          await const NoExpandedOutsideFlex().testAnalyzeAndRun(file);
      final ruleErrors = errors
          .where((e) => e.errorCode.name == 'rigid_no_expanded_outside_flex')
          .toList();
      expect(ruleErrors, isEmpty,
          reason: 'Should not flag non-Flutter Expanded');
    });

    test('no_unbounded_column', () async {
      final errors = await const NoUnboundedColumn().testAnalyzeAndRun(file);
      final ruleErrors = errors
          .where((e) => e.errorCode.name == 'rigid_no_unbounded_column')
          .toList();
      expect(ruleErrors, isEmpty,
          reason: 'Should not flag non-Flutter Column');
    });

    test('constrained_text_field', () async {
      final errors =
          await const ConstrainedTextField().testAnalyzeAndRun(file);
      final ruleErrors = errors
          .where((e) => e.errorCode.name == 'rigid_constrained_text_field')
          .toList();
      expect(ruleErrors, isEmpty,
          reason: 'Should not flag non-Flutter TextField');
    });
  });

  group('State rules — zero false positives on non-Flutter types', () {
    test('no_set_state', () async {
      final errors = await const NoSetState().testAnalyzeAndRun(file);
      final ruleErrors = errors
          .where((e) => e.errorCode.name == 'rigid_no_set_state')
          .toList();
      expect(ruleErrors, isEmpty,
          reason: 'Should not flag setState on non-Flutter State');
    });

    test('no_change_notifier', () async {
      final errors = await const NoChangeNotifier().testAnalyzeAndRun(file);
      final ruleErrors = errors
          .where((e) => e.errorCode.name == 'rigid_no_change_notifier')
          .toList();
      expect(ruleErrors, isEmpty,
          reason: 'Should not flag non-Flutter ChangeNotifier');
    });

    test('exhaustive_async', () async {
      final errors = await const ExhaustiveAsync().testAnalyzeAndRun(file);
      final ruleErrors = errors
          .where((e) => e.errorCode.name == 'rigid_exhaustive_async')
          .toList();
      expect(ruleErrors, isEmpty,
          reason: 'Should not flag .value on non-Riverpod types');
    });

    test('dispose_required', () async {
      final errors = await const DisposeRequired().testAnalyzeAndRun(file);
      final ruleErrors = errors
          .where((e) => e.errorCode.name == 'rigid_dispose_required')
          .toList();
      expect(ruleErrors, isEmpty,
          reason: 'Should not flag non-Flutter disposables');
    });
  });

  group('Architecture rules — zero false positives on non-Flutter types', () {
    test('no_hardcoded_colors', () async {
      final errors = await const NoHardcodedColors().testAnalyzeAndRun(file);
      final ruleErrors = errors
          .where((e) => e.errorCode.name == 'rigid_no_hardcoded_colors')
          .toList();
      expect(ruleErrors, isEmpty,
          reason: 'Should not flag non-Flutter Color');
    });

    test('no_hardcoded_text_style', () async {
      final errors =
          await const NoHardcodedTextStyle().testAnalyzeAndRun(file);
      final ruleErrors = errors
          .where((e) => e.errorCode.name == 'rigid_no_hardcoded_text_style')
          .toList();
      expect(ruleErrors, isEmpty,
          reason: 'Should not flag non-Flutter TextStyle');
    });
  });

  group('Freshness rules — zero false positives on non-Flutter types', () {
    test('no_will_pop_scope', () async {
      final errors = await const NoWillPopScope().testAnalyzeAndRun(file);
      final ruleErrors = errors
          .where((e) => e.errorCode.name == 'rigid_no_will_pop_scope')
          .toList();
      expect(ruleErrors, isEmpty,
          reason: 'Should not flag non-Flutter WillPopScope');
    });

    test('no_with_opacity', () async {
      final errors = await const NoWithOpacity().testAnalyzeAndRun(file);
      final ruleErrors = errors
          .where((e) => e.errorCode.name == 'rigid_no_with_opacity')
          .toList();
      expect(ruleErrors, isEmpty,
          reason: 'Should not flag non-Flutter .withOpacity()');
    });
  });
}
