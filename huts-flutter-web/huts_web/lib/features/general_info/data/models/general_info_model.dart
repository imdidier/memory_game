import 'package:huts_web/features/general_info/data/models/country_info_model.dart';
import 'package:huts_web/features/general_info/domain/entities/general_info_entity.dart';

class GeneralInfoModel extends GeneralInfo {
  GeneralInfoModel({
    required super.statusBannerInfo,
    required super.distanceFilterUpdatesMeters,
    required super.distanceFilterUpdatesMilliseconds,
    required super.locationTimeOutSeconds,
    required super.helpUrl,
    required super.termsUrl,
    required super.minMinutesToArrive,
    required super.minMetersToArrive,
    required super.minMinutesToListenRequest,
    required super.unabledHours,
    required super.ratingOptions,
    required super.updatesInfo,
    required super.countryInfo,
    required super.nightWorkshift,
  });

  factory GeneralInfoModel.fromMap(Map<String, dynamic> map) {
    return GeneralInfoModel(
      statusBannerInfo: map["banner_info"],
      distanceFilterUpdatesMeters: map["distance_filter_updates"],
      distanceFilterUpdatesMilliseconds: map["milliseconds_filter_updates"],
      locationTimeOutSeconds: map["get_location_seconds_time_out"],
      helpUrl: map["help_url"],
      termsUrl: map["terms_url"],
      minMinutesToArrive: map["min_minutes_to_mark_arrival"],
      minMetersToArrive: map["min_meters_to_mark_arrival"],
      minMinutesToListenRequest: map["min_minutes_to_listen_next_request"],
      unabledHours: List<int>.from(map["unabled_hours"]),
      ratingOptions: List<Map<String, dynamic>>.from(map["rating_options"]),
      updatesInfo: map["updates_info"],
      countryInfo: CountryInfoModel.fromMap(
        map['country_info'],
      ),
      nightWorkshift: map['country_info']["night_workshift"],
    );
  }
}
