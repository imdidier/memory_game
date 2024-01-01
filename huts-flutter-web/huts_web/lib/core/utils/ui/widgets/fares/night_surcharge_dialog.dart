// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huts_web/core/services/fares/night_surcharge_services.dart';
import 'package:huts_web/core/services/local_notification_service.dart';
import 'package:huts_web/core/utils/ui/ui_methods.dart';
import 'package:provider/provider.dart';

import '../../../../../features/auth/domain/entities/screen_size_entity.dart';
import '../../../../../features/general_info/display/providers/general_info_provider.dart';
import '../../../../services/navigation_service.dart';
import '../../ui_variables.dart';

class NightSurchargeDialog {
  static show({String? clientId, required Map<String, dynamic> data}) {
    BuildContext? context = NavigationService.getGlobalContext();
    if (context == null) return;

    return showDialog(
        context: context,
        builder: (_) {
          return WillPopScope(
            child: AlertDialog(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(15),
                ),
              ),
              titlePadding: const EdgeInsets.all(0),
              title: _DialogContent(
                data: data,
                clientId: clientId,
              ),
            ),
            onWillPop: () async => false,
          );
        });
  }
}

class _DialogContent extends StatefulWidget {
  final String? clientId;
  final Map<String, dynamic> data;

  const _DialogContent({required this.clientId, required this.data});

  @override
  State<_DialogContent> createState() => __DialogContentState();
}

class __DialogContentState extends State<_DialogContent> {
  bool isDialogLoaded = false;

  MaterialLocalizations? localizations;

  late TimeOfDay startTime;
  late TimeOfDay endTime;

  TextEditingController surchargeController = TextEditingController();

  @override
  void didChangeDependencies() {
    if (isDialogLoaded) return;
    isDialogLoaded = true;

    startTime = TimeOfDay(
      hour: widget.data["start_hour"].toInt(),
      minute: widget.data["start_minutes"].toInt(),
    );

    endTime = TimeOfDay(
      hour: widget.data["end_hour"].toInt(),
      minute: widget.data["end_minutes"].toInt(),
    );

    surchargeController.text = "${(widget.data["surcharge"] * 100).toInt()}";

    super.didChangeDependencies();
  }

  late ScreenSize screenSize;
  @override
  Widget build(BuildContext context) {
    localizations = MaterialLocalizations.of(context);
    screenSize =
        Provider.of<GeneralInfoProvider>(context, listen: false).screenSize;
    return Container(
      width: 600,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
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
                size: screenSize.blockWidth >= 920 ? 26 : 15,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              "Modificar recargo nocturno",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: screenSize.blockWidth >= 920 ? 18 : 14),
            ),
          ],
        ),
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
                if (surchargeController.text.isEmpty) {
                  LocalNotificationService.showSnackBar(
                    type: "fail",
                    message: "Debes agregar un porcentaje de recargo",
                    icon: Icons.error_outline,
                  );
                  return;
                }

                UiMethods().showLoadingDialog(context: context);

                bool itsOK = await NightSurchargeServices.update(
                  clientID: widget.clientId,
                  newData: {
                    "start_hour": startTime.hour,
                    "start_minutes": startTime.minute,
                    "end_hour": endTime.hour,
                    "end_minutes": endTime.minute,
                    "surcharge": double.parse(surchargeController.text) / 100,
                  },
                );

                UiMethods().hideLoadingDialog(context: context);

                if (itsOK) {
                  Navigator.of(context).pop();

                  LocalNotificationService.showSnackBar(
                    type: "success",
                    message: "Listo, información actualizada correctamente",
                    icon: Icons.check,
                  );

                  return;
                }
                LocalNotificationService.showSnackBar(
                  type: "fail",
                  message: "Ocurrió un error al actualizar la información",
                  icon: Icons.error_outline,
                );
              },
              child: Container(
                width: screenSize.blockWidth > 920 ? 150 : 150,
                height:
                    screenSize.blockWidth > 920 ? 35 : screenSize.height * 0.03,
                decoration: BoxDecoration(
                  color: UiVariables.primaryColor.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    "Guardar cambios",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: screenSize.blockWidth >= 920 ? 15 : 12),
                  ),
                ),
              ),
            ),
          ),
        ));
  }

  SingleChildScrollView _buildBody() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 30,
        ),
        margin: EdgeInsets.symmetric(
          vertical: screenSize.height * 0.09,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 15),
            _builTimeField(fromStart: true),
            const SizedBox(height: 15),
            _builTimeField(fromStart: false),
            const SizedBox(height: 15),
            _buildSurchargePercent(),
          ],
        ),
      ),
    );
  }

  Column _builTimeField({required bool fromStart}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          fromStart ? "Hora inicio" : "Hora fin",
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        InkWell(
          onTap: () async {
            TimeOfDay? selectedTime = await showTimePicker(
              initialEntryMode: TimePickerEntryMode.input,
              context: context,
              initialTime: fromStart ? startTime : endTime,
              builder: (pickerContext, child) {
                return MediaQuery(
                  data: MediaQuery.of(pickerContext)
                      .copyWith(alwaysUse24HourFormat: true),
                  child: child ?? Container(),
                );
              },
            );

            if (selectedTime == null) return;

            if (fromStart) {
              if (selectedTime.hour < 18) {
                LocalNotificationService.showSnackBar(
                  type: "fail",
                  message: "La hora de inicio debe ser mínimo a las 18:00",
                  icon: Icons.error_outline,
                );
                return;
              }

              if (selectedTime == endTime) {
                LocalNotificationService.showSnackBar(
                  type: "fail",
                  message: "La hora de inicio no puede ser la misma de fin",
                  icon: Icons.error_outline,
                );
                return;
              }

              startTime = selectedTime;
              setState(() {});
              return;
            }

            if (selectedTime == startTime) {
              LocalNotificationService.showSnackBar(
                type: "fail",
                message: "La hora de fin no puede ser la misma de inicio",
                icon: Icons.error_outline,
              );
              return;
            }

            endTime = selectedTime;

            setState(() {});
          },
          child: Container(
            height: 50,
            width: double.infinity,
            margin: EdgeInsets.only(
              top: screenSize.height * 0.01,
              bottom: screenSize.height * 0.02,
            ),
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
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                localizations!.formatTimeOfDay(fromStart ? startTime : endTime),
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Column _buildSurchargePercent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Porcentaje de recargo (%)",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        Container(
          height: 50,
          width: double.infinity,
          margin: EdgeInsets.only(
            top: screenSize.height * 0.01,
            bottom: screenSize.height * 0.02,
          ),
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
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextField(
              controller: surchargeController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp("[0-9]"),
                ),
              ],
              decoration: const InputDecoration(border: InputBorder.none),
            ),
          ),
        ),
      ],
    );
  }
}
