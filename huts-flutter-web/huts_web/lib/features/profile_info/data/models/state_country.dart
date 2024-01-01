import 'package:huts_web/features/profile_info/domain/entities/state_country.dart';

class StateCountryModel extends StateCountry {
  StateCountryModel({required super.name, required super.cities});

  factory StateCountryModel.fromMap(Map<dynamic, dynamic> map) {
    return StateCountryModel(name: map['name'], cities: map['cities']);
  }
}
