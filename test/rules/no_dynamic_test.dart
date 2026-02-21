import 'package:rigid_dart/rules/freshness/no_dynamic.dart';
import 'package:test/test.dart';

import '../test_helper.dart';

void main() {
  final rule = const NoDynamic();
  final file = fixture('test/fixtures/dynamic_cases.dart');

  test('fixture file exists', () {
    expect(file.existsSync(), isTrue);
  });

  test('detects dynamic type annotations', () async {
    final errors = await rule.testAnalyzeAndRun(file);
    final dynamicErrors = errors
        .where((e) => e.errorCode.name == 'rigid_no_dynamic')
        .toList();

    expect(
      dynamicErrors.length,
      greaterThanOrEqualTo(3),
      reason: 'Expected violations for dynamic param, return, and field',
    );
  });

  test('does NOT flag Object?, String, int, etc.', () async {
    final errors = await rule.testAnalyzeAndRun(file);
    final dynamicErrors = errors
        .where((e) => e.errorCode.name == 'rigid_no_dynamic')
        .toList();

    final source = file.readAsStringSync();
    final validStart = source.indexOf('// SHOULD NOT trigger:');

    for (final error in dynamicErrors) {
      expect(
        error.offset < validStart,
        isTrue,
        reason: 'Should not flag valid types like Object?, String',
      );
    }
  });

  test('does NOT flag "as dynamic" cast expressions', () async {
    final errors = await rule.testAnalyzeAndRun(file);
    final dynamicErrors = errors
        .where((e) => e.errorCode.name == 'rigid_no_dynamic')
        .toList();

    final source = file.readAsStringSync();
    for (final error in dynamicErrors) {
      final lineStart = source.lastIndexOf('\n', error.offset) + 1;
      final lineEnd = source.indexOf('\n', error.offset);
      final line = source.substring(lineStart, lineEnd);
      expect(
        line.contains('as dynamic'),
        isFalse,
        reason: 'Should not flag "as dynamic" cast expressions',
      );
    }
  });
}
