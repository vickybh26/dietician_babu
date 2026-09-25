import 'package:flutter_test/flutter_test.dart';
import 'package:dietician_babu/core/diet_plan_selection.dart';

void main() {
  test('an older active plan wins over a newer legacy plan', () {
    final older = {'format': 'structured', 'isActive': true, 'title': 'Active'};
    expect(selectMealPlan([{'format': 'structured'}, older]), same(older));
  });

  test('archived and explicitly inactive plans are never selected', () {
    expect(selectMealPlan([
      {'format': 'structured', 'isActive': true, 'status': 'archived'},
      {'format': 'structured', 'isActive': false},
    ]), isNull);
  });

  test('the latest legacy structured plan remains available', () {
    final latest = {'format': 'structured', 'title': 'Latest'};
    expect(selectMealPlan([latest, {'format': 'structured'}]), same(latest));
  });

  test('an active document plan prevents stale structured meals', () {
    expect(selectMealPlan([
      {'format': 'pdf', 'isActive': true},
      {'format': 'structured'},
    ]), isNull);
  });

  test('no plans produces no meals', () {
    expect(selectMealPlan([]), isNull);
  });
}