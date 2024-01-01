class AvailableDay {
  final String id;
  final String name;
  late bool morningShiftEnabled;
  late bool afternoonShiftEnabled;
  late bool nightShiftEnabled;

  AvailableDay({
    required this.id,
    required this.name,
    required this.morningShiftEnabled,
    required this.afternoonShiftEnabled,
    required this.nightShiftEnabled,
  });
}
