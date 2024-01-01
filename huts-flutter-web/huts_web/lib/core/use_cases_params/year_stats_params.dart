import '../../features/auth/display/providers/auth_provider.dart';
import '../../features/general_info/display/providers/general_info_provider.dart';

class YearStatsParams {
  final int year;
  final DateTime? startDate;
  final DateTime? endDate;

  final AuthProvider authProvider;
  final GeneralInfoProvider generalInfoProvider;
  final bool isFirstTime;
  final String companyId;
  final String adminDashboardType;

  YearStatsParams({
    required this.year,
    required this.authProvider,
    required this.generalInfoProvider,
    required this.companyId,
    required this.adminDashboardType,
    this.startDate,
    this.endDate,
    this.isFirstTime = false,
  });
}
