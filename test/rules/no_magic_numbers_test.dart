import 'package:rigid_dart/rules/architecture/no_magic_numbers.dart';
import 'package:test/test.dart';

import '../test_helper.dart';

void main() {
  final rule = const NoMagicNumbers();
  final file = fixture('test/fixtures/magic_numbers_cases.dart');

  test('fixture file exists', () {
    expect(file.existsSync(), isTrue);
  });

  test('detects magic numbers in layout params', () async {
    final errors = await rule.testAnalyzeAndRun(file);
    final magicErrors = errors
        .where((e) => e.errorCode.name == 'rigid_no_magic_numbers')
        .toList();

    expect(
      magicErrors.length,
      greaterThanOrEqualTo(4),
      reason: 'Expected at least 4 magic number violations',
    );
  });

  test('does NOT flag allowed values (0, 1, 2, 0.0, 0.5, 1.0, 2.0)', () async {
    final errors = await rule.testAnalyzeAndRun(file);
    final magicErrors = errors
        .where((e) => e.errorCode.name == 'rigid_no_magic_numbers')
        .toList();

    final source = file.readAsStringSync();
    final validStart = source.indexOf('void validCode()');
    final validEnd = source.indexOf('}', validStart) + 1;

    for (final error in magicErrors) {
      expect(
        error.offset < validStart || error.offset > validEnd,
        isTrue,
        reason: 'Should not flag allowed values in validCode()',
      );
    }
  });

  test('does NOT flag non-layout params', () async {
    final errors = await rule.testAnalyzeAndRun(file);
    final magicErrors = errors
        .where((e) => e.errorCode.name == 'rigid_no_magic_numbers')
        .toList();

    final source = file.readAsStringSync();
    for (final error in magicErrors) {
      final errorText =
          source.substring(error.offset, error.offset + error.length);
      expect(
        errorText.contains('42') || errorText.contains('0.7'),
        isFalse,
        reason: 'Should not flag non-layout params like count or opacity',
      );
    }
  });
}
