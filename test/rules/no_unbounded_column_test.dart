import 'package:rigid_dart/rules/layout/no_unbounded_column.dart';
import 'package:test/test.dart';

import '../test_helper.dart';

void main() {
  const rule = NoUnboundedColumn();
  final file = fixture('test/fixtures/unbounded_column_cases.dart');

  test('fixture file exists', () {
    expect(file.existsSync(), isTrue);
  });

  test('zero false positives on non-Flutter types', () async {
    final errors = await rule.testAnalyzeAndRun(file);
    final ruleErrors = errors
        .where((e) => e.errorCode.name == 'rigid_no_unbounded_column')
        .toList();

    expect(
      ruleErrors,
      isEmpty,
      reason:
          'Should not flag non-Flutter Column/ListView — even with '
          'mainAxisSize, shrinkWrap, and SizedBox patterns present',
    );
  });
}
