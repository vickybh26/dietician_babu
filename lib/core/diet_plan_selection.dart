/// Selects from plans ordered newest first. Explicit activation takes precedence;
/// legacy plans without activation metadata remain usable until managed.
Map<String, dynamic>? selectMealPlan(Iterable<Map<String, dynamic>> plans) {
  final visible = plans.where((plan) => plan['status'] != 'archived').toList();
  final active = visible.where((plan) => plan['isActive'] == true);
  if (active.isNotEmpty) {
    final plan = active.first;
    return plan['format'] == 'structured' ? plan : null;
  }
  for (final plan in visible) {
    if (plan['format'] == 'structured' && plan['isActive'] == null) {
      return plan;
    }
  }
  return null;
}