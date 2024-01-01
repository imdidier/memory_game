import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/services/local_notification_service.dart';
import 'package:huts_web/features/fares/display/provider/fares_provider.dart';
import 'package:huts_web/features/fares/display/widgets/new_job/new_fare_widget.dart';
import 'package:provider/provider.dart';

import '../../../../../core/services/navigation_service.dart';
import '../../../../../core/utils/ui/ui_variables.dart';
import '../../../../auth/domain/entities/screen_size_entity.dart';
import '../../../../general_info/display/providers/general_info_provider.dart';

class CreateJobDialog {
  static Future<void> show({Map<String, dynamic>? fareData}) async {
    BuildContext? globalContext = NavigationService.getGlobalContext();
    if (globalContext == null) return;

    showDialog(
      context: globalContext,
      barrierDismissible: false,
      builder: (_) {
        return SingleChildScrollView(
          child: WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(15),
                ),
              ),
              titlePadding: EdgeInsets.zero,
              title: _DialogContent(fareData: fareData),
            ),
          ),
        );
      },
    );
  }
}

class _DialogContent extends StatefulWidget {
  final Map<String, dynamic>? fareData;
  const _DialogContent({this.fareData, Key? key}) : super(key: key);
  @override
  State<_DialogContent> createState() => __DialogContentState();
}

class __DialogContentState extends State<_DialogContent> {
  bool isWidgetLoaded = false;
  late ScreenSize screenSize;
  late GeneralInfoProvider generalInfoProvider;
  late FaresProvider faresProvider;
  TextEditingController jobNameController = TextEditingController();
  List<Map<String, dynamic>> systemDocs = [];

  bool isDesktop = false;

  @override
  void didChangeDependencies() {
    if (isWidgetLoaded) return;
    isWidgetLoaded = true;
    generalInfoProvider = Provider.of<GeneralInfoProvider>(context);
    faresProvider = Provider.of<FaresProvider>(context);

    faresProvider.dynamicFares = [];

    faresProvider.normalControllers = [];

    faresProvider.holidayControllers = List<TextEditingController>.generate(
      2,
      (index) => TextEditingController(),
    );

    faresProvider.dynamicControllers = [];

    if (widget.fareData == null) return;
    jobNameController.text = widget.fareData!["name"];

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    screenSize =
        Provider.of<GeneralInfoProvider>(context, listen: false).screenSize;

    isDesktop = screenSize.width >= 1100;

    return SingleChildScrollView(
      child: Container(
        width: screenSize.blockWidth * 0.8,
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
                size: isDesktop ? 26 : 18,
              ),
            ),
            const SizedBox(
              width: 15,
            ),
            Text(
              (widget.fareData == null)
                  ? "Agregar nuevo cargo a Huts"
                  : "Editar cargo: ${widget.fareData!["name"]}",
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style:
                  TextStyle(color: Colors.white, fontSize: isDesktop ? 22 : 16),
            ),
          ],
        ),
      ),
    );
  }

  Container _buildBody() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 30,
      ),
      margin: EdgeInsets.symmetric(
        vertical: screenSize.height * 0.09,
      ),
      height: 500,
      width: double.infinity,
      child: SingleChildScrollView(
        child: OverflowBar(
          spacing: 15,
          overflowSpacing: 15,
          // crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNameField(),
            if (widget.fareData == null) _buildFareSection(),
            _buildDocsSelection(),
          ],
        ),
      ),
    );
  }

  Column _buildFareSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Tarifa",
          style: TextStyle(
            fontSize: screenSize.blockWidth >= 920 ? 16 : 12,
            color: Colors.grey,
          ),
        ),
        NewFareWidget(
          screenSize: screenSize,
        ),
      ],
    );
  }

  Widget _buildDocsSelection() {
    if (generalInfoProvider.generalInfo.countryInfo.requiredDocs.isEmpty) {
      return const SizedBox();
    }

    if (systemDocs.isEmpty) {
      generalInfoProvider.generalInfo.countryInfo.requiredDocs.forEach(
        ((key, value) {
          value["key"] = key;
          value["is_selected"] = (widget.fareData == null)
              ? false
              : value["jobs"].contains(widget.fareData!["value"]);
          systemDocs.add(value);
        }),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text(
          "Documentos solicitados para el cargo",
          style: TextStyle(
            fontSize: screenSize.blockWidth >= 920 ? 16 : 12,
            color: Colors.grey,
          ),
        ),
        OverflowBar(
          spacing: 10,
          overflowSpacing: 10,
          alignment: MainAxisAlignment.spaceBetween,
          children: [
            Wrap(
              runSpacing: 15,
              spacing: 15,
              direction: screenSize.blockWidth >= 920
                  ? Axis.horizontal
                  : Axis.vertical,
              children: systemDocs
                  .map(
                    (docData) => Container(
                      margin: const EdgeInsets.only(top: 20, bottom: 20),
                      padding: const EdgeInsets.all(10),
                      width: screenSize.blockWidth >= 920
                          ? screenSize.blockWidth * 0.16
                          : screenSize.blockWidth * 0.65,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(
                            offset: Offset(0, 2),
                            blurRadius: 2,
                            color: Colors.black12,
                          )
                        ],
                      ),
                      child: OverflowBar(
                        spacing: 10,
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: Transform.scale(
                              scale: 0.6,
                              child: CupertinoSwitch(
                                value: docData["is_selected"],
                                onChanged: (bool newValue) {
                                  setState(() {
                                    docData["is_selected"] = newValue;
                                  });
                                },
                              ),
                            ),
                          ),
                          Text(
                            "${docData["doc_name"]}",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize:
                                    screenSize.blockWidth >= 920 ? 14 : 11,
                                overflow: TextOverflow.ellipsis),
                          ),
                          OverflowBar(
                            children: [
                              Text(
                                "Expira",
                                style: TextStyle(
                                    fontSize:
                                        screenSize.blockWidth >= 920 ? 12 : 9,
                                    overflow: TextOverflow.ellipsis),
                              ),
                              Checkbox(
                                activeColor: Colors.grey,
                                value: docData["can_expire"],
                                onChanged: (bool? newValue) {
                                  return;
                                },
                              ),
                              Text(
                                "Requerido",
                                style: TextStyle(
                                    fontSize:
                                        screenSize.blockWidth >= 920 ? 12 : 9,
                                    overflow: TextOverflow.ellipsis),
                              ),
                              Checkbox(
                                activeColor: Colors.grey,
                                value: docData["required"],
                                onChanged: (bool? newValue) {
                                  return;
                                },
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        )
      ],
    );
  }

  Column _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Nombre del cargo",
          style: TextStyle(
            fontSize: screenSize.blockWidth >= 920 ? 16 : 12,
            color: Colors.grey,
          ),
        ),
        Container(
          height: 50,
          width: double.infinity,
          margin: EdgeInsets.only(
            top: screenSize.height * 0.01,
            bottom: screenSize.height * 0.02,
            left: 2,
            right: 2,
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
              enabled: widget.fareData == null,
              keyboardType: TextInputType.text,
              controller: jobNameController,
              style: const TextStyle(fontSize: 15),
              decoration: const InputDecoration(
                border: InputBorder.none,
              ),
            ),
          ),
        ),
      ],
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
              if (jobNameController.text.isEmpty) {
                LocalNotificationService.showSnackBar(
                  type: "fail",
                  message: "Debes agregar el nombre del cargo",
                  icon: Icons.error_outline,
                );
                return;
              }

              // if (int.parse(faresProvider.normalControllers[0].text) <=
              //     int.parse(faresProvider.normalControllers[1].text)) {
              //   LocalNotificationService.showSnackBar(
              //     type: "fail",
              //     message:
              //         "En la tarifa normal, el valor para el cliente debe ser mayor al valor para el colaborador",
              //     icon: Icons.error_outline,
              //   );
              //   return;
              // }

              // if (int.parse(faresProvider.holidayControllers[0].text) <=
              //     int.parse(faresProvider.holidayControllers[1].text)) {
              //   LocalNotificationService.showSnackBar(
              //     type: "fail",
              //     message:
              //         "En la tarifa festiva, el valor para el cliente debe ser mayor al valor para el colaborador",
              //     icon: Icons.error_outline,
              //   );
              //   return;
              // }

              bool itsFareOk = faresProvider.validateNewJobFare();

              if (!itsFareOk) return;
              if (systemDocs
                  .every((element) => element["is_selected"] == false)) {
                LocalNotificationService.showSnackBar(
                  type: "fail",
                  message: "Debes seleccionar al menos un documento",
                  icon: Icons.error_outline,
                );
                return;
              }

              if (widget.fareData != null) {
                await faresProvider.updateJobDocs(
                  {
                    "job_info": {
                      "name": widget.fareData!["name"],
                      "value": widget.fareData!["value"],
                      "fares": widget.fareData!["fares"]
                    },
                    "required_docs": systemDocs
                        .where((element) => element["is_selected"])
                        .toList(),
                    "country_id": "costa_rica",
                  },
                );
                return;
              }

              Map<String, dynamic> dynamicFaresMap = {};

              for (var i = 0; i < faresProvider.dynamicFares.length; i++) {
                Map<String, dynamic> dynamicFare =
                    faresProvider.dynamicFares[i];
                // if (int.parse(faresProvider.dynamicControllers[i + i].text) >
                //     int.parse(
                //         faresProvider.dynamicControllers[i + i + 1].text)) {
                dynamicFaresMap[dynamicFare["key"]] = {
                  "name": dynamicFare["name"],
                  "key": dynamicFare["key"],
                  "client_fare":
                      int.parse(faresProvider.dynamicControllers[i + i].text),
                  "employee_fare": int.parse(
                      faresProvider.dynamicControllers[i + i + 1].text),
                };
                //}

                //  else {
                //   LocalNotificationService.showSnackBar(
                //     type: "fail",
                //     message:
                //         "El valor de la tarifa dinámica para el cliente debe ser mayor al valor de la tarifa para el colaborador",
                //     icon: Icons.error_outline,
                //   );
                //   return;
                // }
              }

              Map<String, dynamic> data = {
                "job_info": {
                  "name": jobNameController.text,
                  "value": jobNameController.text
                      .toLowerCase()
                      .trim()
                      .replaceAll(" ", "_"),
                  "fares": {
                    "normal": {
                      "name": "Normal",
                      "client_fare":
                          int.parse(faresProvider.normalControllers[0].text),
                      "employee_fare":
                          int.parse(faresProvider.normalControllers[1].text),
                    },
                    "holiday": {
                      "name": "Festiva",
                      "client_fare":
                          int.parse(faresProvider.holidayControllers[0].text),
                      "employee_fare":
                          int.parse(faresProvider.holidayControllers[1].text),
                    },
                    "dynamic": dynamicFaresMap,
                  }
                },
                "required_docs": systemDocs
                    .where((element) => element["is_selected"])
                    .toList(),
                "country_id": "costa_rica",
              };
              await faresProvider.createJob(data);
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
                  (widget.fareData == null)
                      ? "Crear cargo"
                      : "Actualizar cargo",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
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
