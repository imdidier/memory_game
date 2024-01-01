import 'package:flutter/material.dart';
import 'package:huts_web/core/services/employee_services/employee_services.dart';
import 'package:huts_web/core/services/employee_services/widgets/employee_requests.dart';
import 'package:huts_web/core/utils/code/code_utils.dart';
import 'package:huts_web/core/utils/ui/widgets/general/custom_date_selector.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/general_info/display/providers/general_info_provider.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/navigation_service.dart';
import '../../../../core/utils/ui/ui_variables.dart';
import '../../../requests/domain/entities/request_entity.dart';
import '../../domain/entities/employee_entity.dart';

class EmployeesRequestsHistoryDialog {
  static void show(Employee employee) {
    BuildContext? context = NavigationService.getGlobalContext();
    if (context == null) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(15),
              ),
            ),
            titlePadding: EdgeInsets.zero,
            title: _DialogContent(
              employee: employee,
              screenSize: context.read<GeneralInfoProvider>().screenSize,
            ),
          ),
        );
      },
    );
  }
}

class _DialogContent extends StatefulWidget {
  final Employee employee;
  final ScreenSize screenSize;
  const _DialogContent({
    Key? key,
    required this.employee,
    required this.screenSize,
  }) : super(key: key);

  @override
  State<_DialogContent> createState() => _DialogContentState();
}

class _DialogContentState extends State<_DialogContent> {
  ValueNotifier<List<Request>> requestsNotifier =
      ValueNotifier<List<Request>>([]);

  ValueNotifier<bool> showDatePicker = ValueNotifier<bool>(true);

  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.screenSize.width * 0.9,
      height: widget.screenSize.height * 0.85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          _buildBody(),
          _buildHeader(context),
          _buildDatePicker(),
        ],
      ),
    );
  }

  Positioned _buildDatePicker() {
    return Positioned(
        left: 20,
        top: 80,
        child: ValueListenableBuilder(
          valueListenable: showDatePicker,
          builder: (_, bool isVisible, Widget? child) {
            return CustomDateSelector(
              isVisible: isVisible,
              onDateSelected: (DateTime? startDate, DateTime? endDate) async {
                if (startDate == null) return;
                startDate = DateTime(
                  startDate.year,
                  startDate.month,
                  startDate.day,
                  00,
                  00,
                );
                if (endDate != null) {
                  endDate = DateTime(
                    endDate.year,
                    endDate.month,
                    endDate.day,
                    23,
                    59,
                  );
                } else {
                  endDate = DateTime(
                    startDate.year,
                    startDate.month,
                    startDate.day,
                    23,
                    59,
                  );
                }

                List<Request>? requests = await EmployeeServices.getRequests(
                    widget.employee.id, startDate, endDate);

                if (requests == null) return;

                requestsNotifier.value = [...requests];
              },
            );
          },
        ));
  }

  Container _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: UiVariables.primaryColor.withOpacity(0.8),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            InkWell(
              onTap: () => Navigator.of(context).pop(),
              child: Icon(
                Icons.close,
                color: Colors.white,
                size: widget.screenSize.blockWidth >= 920 ? 26 : 15,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              "Historial solicitudes ${CodeUtils.getFormatedName(widget.employee.profileInfo.names, widget.employee.profileInfo.lastNames)}",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: widget.screenSize.blockWidth >= 920 ? 18 : 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Container(
      width: double.infinity,
      height: widget.screenSize.height * 0.8,
      padding: const EdgeInsets.symmetric(
        horizontal: 30,
      ),
      margin: EdgeInsets.only(
        // top: screenSize.height * 0.05,
        bottom: widget.screenSize.height * 0.05,
      ),
      child: NotificationListener(
        onNotification: (Notification notification) {
          if (_scrollController.position.pixels > 50 && showDatePicker.value) {
            showDatePicker.value = false;

            return true;
          }

          if (_scrollController.position.pixels <= 60 &&
              !showDatePicker.value) {
            showDatePicker.value = true;
          }
          return true;
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            children: [
              SizedBox(height: widget.screenSize.height * 0.15),
              ValueListenableBuilder(
                valueListenable: requestsNotifier,
                builder: (_, List<Request> requests, Widget? child) {
                  return EmployeeRequests(
                    fromHistoricalDialog: true,
                    requests: requests,
                    screenSize: widget.screenSize,
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
