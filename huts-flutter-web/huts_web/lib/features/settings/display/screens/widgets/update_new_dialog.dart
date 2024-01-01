import 'package:flutter/material.dart';
import 'package:huts_web/core/services/local_notification_service.dart';
import 'package:provider/provider.dart';

import '../../../../../core/services/navigation_service.dart';
import '../../../../../core/utils/code/code_utils.dart';
import '../../../../../core/utils/ui/ui_variables.dart';
import '../../../../auth/domain/entities/screen_size_entity.dart';
import '../../../../general_info/display/providers/general_info_provider.dart';
import '../../providers/settings_provider.dart';

class DialogUpdateHoliday {
  static void show({required Map<String, dynamic> holiday}) {
    BuildContext? globalContext = NavigationService.getGlobalContext();
    if (globalContext == null) return;
    showDialog(
      context: globalContext,
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
              holiday: holiday,
            ),
          ),
        );
      },
    );
  }
}

class _DialogContent extends StatefulWidget {
  final Map<String, dynamic> holiday;
  const _DialogContent({
    Key? key,
    required this.holiday,
  }) : super(key: key);

  @override
  State<_DialogContent> createState() => __DialogContentState();
}

class __DialogContentState extends State<_DialogContent> {
  late ScreenSize screenSize;
  late SettingsProvider settingsProvider;

  DateTime? selectedDate;
  TextEditingController newDateHolidayController = TextEditingController();
  TextEditingController newNameHolidayController = TextEditingController();
  DateTime currentDate = DateTime.now();

  @override
  void didChangeDependencies() {
    settingsProvider = Provider.of<SettingsProvider>(context);

    super.didChangeDependencies();
  }

  @override
  void initState() {
    String key =
        '${widget.holiday['day'] < 10 ? '0${widget.holiday['day']}' : widget.holiday['day']}-${widget.holiday['month'] < 10 ? '0${widget.holiday['month']}' : widget.holiday['month']}';
    widget.holiday['old_holiday'] = {
      'key': key,
      'name': widget.holiday['name'],
      'month': widget.holiday['month'],
      'day': widget.holiday['day'],
    };
    newNameHolidayController.text = widget.holiday['name'];
    newDateHolidayController.text =
        '${widget.holiday['day'] < 10 ? '0${widget.holiday['day']}' : widget.holiday['day']}/${widget.holiday['month'] < 10 ? '0${widget.holiday['month']}' : widget.holiday['month']}/${currentDate.year}';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    screenSize =
        Provider.of<GeneralInfoProvider>(context, listen: false).screenSize;
    return SizedBox(
      width: screenSize.blockWidth * 0.42,
      height: screenSize.height * 0.44,
      child: Stack(
        children: [
          _buildBody(),
          _buildHeader(),
          _buildFooter(),
        ],
      ),
    );
  }

  Container _buildHeader() {
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
                size: screenSize.width * 0.018,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Editar día festivo',
              style: TextStyle(
                color: Colors.white,
                fontSize: screenSize.blockWidth >= 920
                    ? screenSize.width * 0.015
                    : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Container _buildBody() {
    return Container(
      margin: const EdgeInsets.only(top: 50, bottom: 15),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          const Text(
            "Nombre",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          Container(
            margin: const EdgeInsets.only(top: 5, bottom: 30),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(
                  offset: Offset(0, 2),
                  color: Colors.black26,
                  blurRadius: 2,
                )
              ],
            ),
            child: TextField(
              controller: newNameHolidayController,
              style: TextStyle(
                fontSize: screenSize.blockWidth >= 920 ? 16 : 14,
              ),
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
            ),
          ),
          const Text(
            "Fecha",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 5),
          InkWell(
            onTap: () async {
              final DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: currentDate,
                firstDate: currentDate,
                lastDate: currentDate.add(
                  const Duration(
                    days: 10000,
                  ),
                ),
              );
              if (pickedDate != null) {
                selectedDate = DateTime(
                  pickedDate.year,
                  pickedDate.month,
                  pickedDate.day,
                );
                newDateHolidayController.text = CodeUtils.formatDateWithoutHour(
                  selectedDate!,
                );
                widget.holiday['month'] = selectedDate!.month;
                widget.holiday['day'] = selectedDate!.day;
                setState(() {});
              }
            },
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [
                  BoxShadow(
                    offset: Offset(0, 2),
                    color: Colors.black26,
                    blurRadius: 2,
                  )
                ],
              ),
              child: TextField(
                enabled: false,
                readOnly: true,
                controller: newDateHolidayController,
                style: TextStyle(
                  fontSize: screenSize.blockWidth >= 920 ? 16 : 14,
                ),
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 15,
          ),
        ],
      ),
    );
  }

  Positioned _buildFooter() {
    return Positioned(
      bottom: 12,
      left: 0,
      right: 0,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(
          top: 8.0,
          bottom: 8.0,
          left: 8.0,
          right: 14.0,
        ),
        child: Align(
          alignment: Alignment.centerRight,
          child: InkWell(
            onTap: () async {
              widget.holiday['name'] = newNameHolidayController.text;
              if (newNameHolidayController.text.isEmpty) {
                LocalNotificationService.showSnackBar(
                  type: "fail",
                  message: "Debes agregar el nombre del festivo",
                  icon: Icons.error_outline,
                );
                return;
              }
              settingsProvider.updateHoliday(newHoliday: widget.holiday);
            },
            child: Container(
              width: 150,
              height: 35,
              decoration: BoxDecoration(
                color: UiVariables.primaryColor.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  "Guardar cambios",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenSize.blockWidth >= 920 ? 15 : 12,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
