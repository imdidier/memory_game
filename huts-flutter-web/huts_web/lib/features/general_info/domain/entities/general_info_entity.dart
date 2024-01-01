import 'package:huts_web/features/general_info/domain/entities/country_info_entity.dart';

class GeneralInfo {
  final Map<String, dynamic> statusBannerInfo;
  final int distanceFilterUpdatesMeters;
  final int distanceFilterUpdatesMilliseconds;
  final int locationTimeOutSeconds;
  final String helpUrl;
  final String termsUrl;
  final int minMinutesToArrive;
  final int minMetersToArrive;
  final int minMinutesToListenRequest;
  final List<int> unabledHours;
  final List<Map<String, dynamic>> ratingOptions;
  final Map<String, dynamic> updatesInfo;
  final CountryInfo countryInfo;
  final Map<String, dynamic> nightWorkshift;

  GeneralInfo({
    required this.statusBannerInfo,
    required this.distanceFilterUpdatesMeters,
    required this.distanceFilterUpdatesMilliseconds,
    required this.locationTimeOutSeconds,
    required this.helpUrl,
    required this.termsUrl,
    required this.minMinutesToArrive,
    required this.minMetersToArrive,
    required this.minMinutesToListenRequest,
    required this.unabledHours,
    required this.ratingOptions,
    required this.updatesInfo,
    required this.countryInfo,
    required this.nightWorkshift,
  });
}
