import 'package:flutter/material.dart';
import 'package:huts_web/core/services/local_notification_service.dart';
import 'package:huts_web/features/activity/display/providers/activity_provider.dart';
import 'package:huts_web/features/activity/display/widgets/general_activity_data_table.dart';
import 'package:huts_web/features/auth/display/providers/auth_provider.dart';
import 'package:huts_web/features/auth/domain/entities/web_user_entity.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/ui/widgets/general/custom_date_selector.dart';
import '../../../auth/domain/entities/screen_size_entity.dart';
import '../../../general_info/display/providers/general_info_provider.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({Key? key}) : super(key: key);

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  bool isScreenLoaded = false;
  late ActivityProvider activityProvider;
  late ScreenSize screenSize;
  bool isDesktop = false;

  ValueNotifier<bool> showDatePicker = ValueNotifier<bool>(true);
  final ScrollController _scrollController = ScrollController();

  @override
  void didChangeDependencies() {
    if (isScreenLoaded) return;
    isScreenLoaded = true;
    activityProvider = context.watch<ActivityProvider>();
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    screenSize = Provider.of<GeneralInfoProvider>(context).screenSize;
    isDesktop = screenSize.width >= 1120;
    return SizedBox(
      height: screenSize.height,
      width: screenSize.blockWidth,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            NotificationListener(
              onNotification: (Notification notification) {
                if (_scrollController.position.pixels > 20 &&
                    showDatePicker.value) {
                  showDatePicker.value = false;

                  return true;
                }

                if (_scrollController.position.pixels <= 30 &&
                    !showDatePicker.value) {
                  showDatePicker.value = true;
                }
                return true;
              },
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitle(),
                    _buildContent(),
                  ],
                ),
              ),
            ),
            Positioned(
              top: screenSize.height * 0.01,
              right: screenSize.blockWidth >= 920
                  ? screenSize.width * 0.016
                  : screenSize.width * 0.005,
              child: ValueListenableBuilder(
                valueListenable: showDatePicker,
                builder: (_, isVisible, __) {
                  return CustomDateSelector(
                    isVisible: isVisible,
                    onDateSelected:
                        (DateTime? startDate, DateTime? endDate) async {
                      if (startDate == null) return;

                      if (endDate != null &&
                          endDate.difference(startDate).inDays > 35) {
                        LocalNotificationService.showSnackBar(
                          type: "fail",
                          message:
                              "Solo puedes seleccionar rangos de máximo 35 días",
                          icon: Icons.error_outline,
                        );

                        return;
                      }

                      startDate = DateTime(
                          startDate.year, startDate.month, startDate.day, 0, 0);
                      if (endDate != null) {
                        endDate = DateTime(
                          endDate.year,
                          endDate.month,
                          endDate.day,
                          23,
                          59,
                        );
                      }
                      endDate ??= DateTime(startDate.year, startDate.month,
                          startDate.day, 23, 59);

                      WebUser webUser = context.read<AuthProvider>().webUser;

                      await activityProvider.getGeneralActivity(
                        startDate,
                        endDate,
                        webUser,
                      );
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Column _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Actividad General",
          style: TextStyle(
            color: Colors.black,
            fontSize: screenSize.width * 0.016,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          "Reportes generales del uso de la plataforma",
          style: TextStyle(
            color: Colors.black54,
            fontSize: screenSize.width * 0.01,
          ),
        ),
      ],
    );
  }

  Column _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SizedBox(height: 30),
        _buildSearchBar(),
        Container(
          margin: EdgeInsets.only(top: screenSize.height * 0.04),
          child: const GeneralActivityDataTable(),
        )
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      width: screenSize.blockWidth * 0.3,
      height: screenSize.height * 0.055,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            offset: Offset(0, 2),
            color: Colors.black26,
            blurRadius: 2,
          )
        ],
      ),
      child: TextField(
        controller: activityProvider.generalSearchController,
        decoration: InputDecoration(
          suffixIcon: const Icon(Icons.search),
          hintText: "Buscar registro",
          hintStyle: TextStyle(
            color: Colors.black54,
            fontSize: isDesktop ? 14 : 10,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
              horizontal: 20, vertical: screenSize.blockWidth >= 920 ? 12 : 8),
        ),
        onChanged: activityProvider.filterGeneralActivity,
      ),
    );
  }
}
