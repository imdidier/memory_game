import '../../domain/entities/available_day.dart';

class AvailabilityDayModel extends AvailableDay {
  AvailabilityDayModel({
    required String id,
    required String name,
    required bool morningShiftEnabled,
    required bool afternoonShiftEnabled,
    required bool nightShiftEnabled,
  }) : super(
          id: id,
          name: name,
          morningShiftEnabled: morningShiftEnabled,
          afternoonShiftEnabled: afternoonShiftEnabled,
          nightShiftEnabled: nightShiftEnabled,
        );

  factory AvailabilityDayModel.fromMap(Map<dynamic, dynamic> map) {
    return AvailabilityDayModel(
      id: map["id"],
      name: map["name"],
      morningShiftEnabled: map["morning_shift_enabled"],
      afternoonShiftEnabled: map["afternoon_shift_enabled"],
      nightShiftEnabled: map["night_shift_enabled"],
    );
  }

  static Map<String, dynamic> toMap(AvailableDay avaliabilityDay) {
    return {
      'id': avaliabilityDay.id,
      'name': avaliabilityDay.name,
      'morning_shift_enabled': avaliabilityDay.morningShiftEnabled,
      'afternoon_shift_enabled': avaliabilityDay.afternoonShiftEnabled,
      'night_shift_enabled': avaliabilityDay.nightShiftEnabled
    };
  }
}
