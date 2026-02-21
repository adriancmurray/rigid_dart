import 'package:rigid_dart/rules/state/no_build_context_across_async.dart';
import 'package:test/test.dart';

import '../test_helper.dart';

void main() {
  final rule = const NoBuildContextAcrossAsync();
  final file = fixture('test/fixtures/build_context_async_cases.dart');

  test('fixture file exists', () {
    expect(file.existsSync(), isTrue);
  });

  test('detects context usage after await', () async {
    final errors = await rule.testAnalyzeAndRun(file);
    final contextErrors = errors
        .where((e) => e.errorCode.name == 'rigid_no_build_context_across_async')
        .toList();

    expect(
      contextErrors.length,
      greaterThanOrEqualTo(2),
      reason: 'Expected at least 2 violations for context after await',
    );
  });

  test('does NOT flag when mounted guard is present', () async {
    final errors = await rule.testAnalyzeAndRun(file);
    final contextErrors = errors
        .where((e) => e.errorCode.name == 'rigid_no_build_context_across_async')
        .toList();

    final source = file.readAsStringSync();
    final safeStart = source.indexOf('Future<void> safeNavigation');
    final safeEnd = source.indexOf('}', safeStart + 50) + 1;

    for (final error in contextErrors) {
      expect(
        error.offset < safeStart || error.offset > safeEnd,
        isTrue,
        reason: 'Should not flag code guarded by mounted check',
      );
    }
  });

  test('does NOT flag synchronous methods', () async {
    final errors = await rule.testAnalyzeAndRun(file);
    final contextErrors = errors
        .where((e) => e.errorCode.name == 'rigid_no_build_context_across_async')
        .toList();

    final source = file.readAsStringSync();
    final syncStart = source.indexOf('void synchronousMethod');
    final syncEnd = source.indexOf('}', syncStart) + 1;

    for (final error in contextErrors) {
      expect(
        error.offset < syncStart || error.offset > syncEnd,
        isTrue,
        reason: 'Should not flag synchronous methods',
      );
    }
  });

  test('does NOT flag context captured before await', () async {
    final errors = await rule.testAnalyzeAndRun(file);
    final contextErrors = errors
        .where((e) => e.errorCode.name == 'rigid_no_build_context_across_async')
        .toList();

    final source = file.readAsStringSync();
    final captureStart = source.indexOf('Future<void> contextBeforeAwait');
    final captureEnd = source.indexOf('}', captureStart + 50) + 1;

    for (final error in contextErrors) {
      expect(
        error.offset < captureStart || error.offset > captureEnd,
        isTrue,
        reason: 'Should not flag context captured before await',
      );
    }
  });
}
