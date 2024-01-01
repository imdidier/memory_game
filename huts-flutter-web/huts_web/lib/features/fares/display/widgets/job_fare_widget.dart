import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huts_web/core/services/local_notification_service.dart';
import 'package:huts_web/core/utils/ui/widgets/general/custom_scroll_behavior.dart';
import 'package:huts_web/core/utils/ui/widgets/general/custom_tooltip.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/clients/display/provider/clients_provider.dart';
import 'package:huts_web/features/fares/display/provider/fares_provider.dart';
import 'package:huts_web/features/fares/display/widgets/new_dynamic_fare.dart';
import 'package:huts_web/features/general_info/display/providers/general_info_provider.dart';
import 'package:huts_web/features/general_info/domain/entities/country_info_entity.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/ui/ui_variables.dart';
import 'new_job/create_job_dialog.dart';

class JobFareWidget extends StatefulWidget {
  final ScreenSize screenSize;
  final Map<String, dynamic> fareData;
  final bool fromClient;
  final String clientId;
  final Function? onDelete;
  final Function? onUpdate;
  const JobFareWidget({
    required this.screenSize,
    required this.fareData,
    this.onDelete,
    this.onUpdate,
    this.fromClient = false,
    this.clientId = "",
    Key? key,
  }) : super(key: key);

  @override
  State<JobFareWidget> createState() => _JobFareWidgetState();
}

class _JobFareWidgetState extends State<JobFareWidget> {
  bool isWidgetLoaded = false;

  List<Map<String, dynamic>> dynamicFares = [];

  List<TextEditingController> normalControllers = [];

  List<TextEditingController> holidayControllers =
      List<TextEditingController>.generate(
    2,
    (index) => TextEditingController(),
  );

  List<TextEditingController> dynamicControllers = [];

  late FaresProvider faresProvider;
  late CountryInfo countryInfo;

  bool isAddingFare = false;
  bool isDesktop = false;

  @override
  void didChangeDependencies() {
    if (isWidgetLoaded) return;
    isWidgetLoaded = true;
    faresProvider = Provider.of<FaresProvider>(context);
    countryInfo =
        Provider.of<GeneralInfoProvider>(context).generalInfo.countryInfo;
    setControllersValues();
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    isDesktop = widget.screenSize.width >= 1100;
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      width: isDesktop
          ? widget.screenSize.blockWidth * 0.35
          : widget.screenSize.blockWidth - 40,

      //    (widget.fromClient || isDesktop)
      // widget.screenSize.blockWidth * 0.38

      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(offset: Offset(0, 2), color: Colors.black12, blurRadius: 2)
        ],
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        // curve: Curves.elasticOut,
        child: (!widget.fareData["is_expanded"])
            ? InkWell(
                onTap: () {
                  setState(() {
                    widget.fareData["is_expanded"] = true;
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.fareData["name"],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isDesktop ? 16 : 12,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down)
                  ],
                ),
              )
            : OverflowBar(
                children: [
                  InkWell(
                    onTap: () {
                      setControllersValues();
                      setState(() {
                        widget.fareData["is_expanded"] = false;
                      });
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.fareData["name"],
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isDesktop ? 16 : 12,
                              color: UiVariables.primaryColor),
                        ),
                        const Icon(
                          Icons.arrow_drop_up,
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Divider(height: 12),
                  const SizedBox(height: 5),
                  OverflowBar(
                    spacing: 20,
                    overflowSpacing: 20,
                    alignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildNormalFare(),
                      _buildHolidayFare(),
                      _buildDynamicFares(),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildDeleteBtn(),
                      _buildSaveBtn(),
                      if (!widget.fromClient) _buildEditDocsBtn()
                    ],
                  ),
                  const SizedBox(height: 15),
                ],
              ),
      ),
    );
  }

  Align _buildEditDocsBtn() {
    return Align(
      alignment: Alignment.center,
      child: InkWell(
        onTap: () => CreateJobDialog.show(fareData: widget.fareData),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.blue,
          ),
          padding: const EdgeInsets.all(10),
          child: const Text(
            "Editar documentos",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Align _buildDeleteBtn() {
    return Align(
      alignment: Alignment.center,
      child: InkWell(
        onTap: () async {
          bool itsConfirmed = await confirm(
            context,
            title: Text(
              "Eliminar cargo",
              style: TextStyle(
                color: UiVariables.primaryColor,
                fontSize: isDesktop ? 16 : 12,
              ),
            ),
            content: Text(
              (widget.fromClient)
                  ? "¿Quieres eliminar el cargo ${widget.fareData["name"]} de este cliente?"
                  : "¿Quieres eliminar el cargo ${widget.fareData["name"]}?",
            ),
            textCancel: Text(
              "Cancelar",
              style: TextStyle(
                color: Colors.grey,
                fontSize: isDesktop ? 16 : 12,
              ),
            ),
            textOK: Text(
              "Aceptar",
              style: TextStyle(
                color: Colors.blue,
                fontSize: isDesktop ? 16 : 12,
              ),
            ),
          );

          if (!itsConfirmed) return;
          if (!mounted) return;

          Map<String, dynamic> toDeleteJob = {...widget.fareData};
          toDeleteJob.remove("is_expanded");

          if (widget.fromClient) {
            await Provider.of<ClientsProvider>(context, listen: false)
                .updateClientInfo(
              {
                "type": "remove",
                "job_info": toDeleteJob,
              },
              "jobs",
              true,
            );
          } else {
            await Provider.of<FaresProvider>(context, listen: false).deleteJob(
              {
                "country_id": "costa_rica",
                "job_info": toDeleteJob,
              },
            );
          }

          if (widget.onDelete != null) {
            widget.onDelete!();
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.orange,
          ),
          padding: const EdgeInsets.all(10),
          child: const Text(
            "Eliminar cargo",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  void setControllersValues() {
    normalControllers = [
      TextEditingController(
        text: "${widget.fareData["fares"]["normal"]["client_fare"]}",
      ),
      TextEditingController(
        text: "${widget.fareData["fares"]["normal"]["employee_fare"]}",
      ),
    ];

    holidayControllers = [
      TextEditingController(
        text: "${widget.fareData["fares"]["holiday"]["client_fare"]}",
      ),
      TextEditingController(
        text: "${widget.fareData["fares"]["holiday"]["employee_fare"]}",
      ),
    ];

    dynamicFares = List<Map<String, dynamic>>.from(
      widget.fareData["fares"]["dynamic"].values.toList(),
    );

    dynamicFares.sort((first, next) {
      int firstValue = int.parse(first["key"].split("-")[0]);
      int nextValue = int.parse(next["key"].split("-")[0]);
      return firstValue.compareTo(nextValue);
    });

    dynamicControllers.clear();

    for (Map<String, dynamic> dynamicFare in dynamicFares) {
      dynamicControllers
          .add(TextEditingController(text: "${dynamicFare["client_fare"]}"));
      dynamicControllers
          .add(TextEditingController(text: "${dynamicFare["employee_fare"]}"));
    }
  }

  void resetDynamicControllersValues() {
    dynamicFares.sort((first, next) {
      int firstValue = int.parse(first["key"].split("-")[0]);
      int nextValue = int.parse(next["key"].split("-")[0]);
      return firstValue.compareTo(nextValue);
    });

    dynamicControllers.clear();

    for (Map<String, dynamic> dynamicFare in dynamicFares) {
      dynamicControllers
          .add(TextEditingController(text: "${dynamicFare["client_fare"]}"));
      dynamicControllers
          .add(TextEditingController(text: "${dynamicFare["employee_fare"]}"));
    }
  }

  Column _buildNormalFare() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Normal",
              textAlign: isDesktop ? TextAlign.start : TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isDesktop ? 13 : 10,
              ),
            ),
            const SizedBox(width: 8),
            CustomTooltip(
              message: "Restablecer valores generales",
              child: InkWell(
                onTap: () {
                  normalControllers[0].text = countryInfo
                      .jobsFares[widget.fareData["value"]]["fares"]["normal"]
                          ["client_fare"]
                      .toString();
                  normalControllers[1].text = countryInfo
                      .jobsFares[widget.fareData["value"]]["fares"]["normal"]
                          ["employee_fare"]
                      .toString();
                  setState(() {});
                },
                child: const Icon(
                  Icons.history,
                  size: 20,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        OverflowBar(
          spacing: 15,
          overflowSpacing: 15,
          children: [
            Column(
              children: [
                Text(
                  "Tarifa cliente",
                  style: TextStyle(
                      fontSize: isDesktop ? 13 : 10, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                Container(
                  width: widget.screenSize.blockWidth * 0.13,
                  height: 35,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: UiVariables.lightBlueColor,
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                    child: Center(
                      child: TextField(
                        textAlign: TextAlign.center,
                        controller: normalControllers[0],
                        style: TextStyle(
                          fontSize: isDesktop ? 15 : 11,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.only(bottom: 10),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        keyboardType: TextInputType.number,
                        onChanged: (String value) {
                          if (value.isEmpty) {
                            setState(() {
                              normalControllers[0].text = "0";
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Column(
              children: [
                Text(
                  "Tarifa colaborador",
                  style: TextStyle(
                      fontSize: isDesktop ? 13 : 10, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                Container(
                  width: widget.screenSize.blockWidth * 0.13,
                  height: 35,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: UiVariables.lightBlueColor,
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                    child: Center(
                      child: TextField(
                        textAlign: TextAlign.center,
                        controller: normalControllers[1],
                        style: TextStyle(
                          fontSize: isDesktop ? 15 : 11,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.only(bottom: 10),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        keyboardType: TextInputType.number,
                        onChanged: (String value) {
                          if (value.isEmpty) {
                            setState(() {
                              normalControllers[1].text = "0";
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Column _buildHolidayFare() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Festiva",
              textAlign: isDesktop ? TextAlign.start : TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isDesktop ? 13 : 10,
              ),
            ),
            const SizedBox(width: 8),
            CustomTooltip(
              message: "Restablecer valores generales",
              child: InkWell(
                onTap: () {},
                child: const Icon(
                  Icons.history_rounded,
                  size: 20,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        OverflowBar(
          spacing: 15,
          overflowSpacing: 15,
          children: [
            Column(
              children: [
                Text(
                  "Tarifa cliente",
                  style: TextStyle(
                      fontSize: isDesktop ? 13 : 10, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                Container(
                  width: widget.screenSize.blockWidth * 0.13,
                  height: 35,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: UiVariables.lightBlueColor,
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                    child: Center(
                      child: TextField(
                        textAlign: TextAlign.center,
                        controller: holidayControllers[0],
                        style: TextStyle(
                          fontSize: isDesktop ? 15 : 11,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.only(bottom: 10),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        keyboardType: TextInputType.number,
                        onChanged: (String value) {
                          if (value.isEmpty) {
                            setState(() {
                              holidayControllers[0].text = "0";
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 15),
            Column(
              children: [
                Text(
                  "Tarifa colaborador",
                  style: TextStyle(
                      fontSize: isDesktop ? 13 : 10, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                Container(
                  width: widget.screenSize.blockWidth * 0.13,
                  height: 35,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: UiVariables.lightBlueColor,
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                    child: Center(
                      child: TextField(
                        textAlign: TextAlign.center,
                        controller: holidayControllers[1],
                        style: TextStyle(
                          fontSize: isDesktop ? 15 : 11,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.only(bottom: 10),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        keyboardType: TextInputType.number,
                        onChanged: (String value) {
                          if (value.isEmpty) {
                            setState(() {
                              holidayControllers[1].text = "0";
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Column _buildDynamicFares() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Dinámicas",
                textAlign: isDesktop ? TextAlign.start : TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isDesktop ? 13 : 10,
                ),
              ),
              const SizedBox(width: 8),
              CustomTooltip(
                message: (isAddingFare) ? "Cancelar" : "Agregar tarifa",
                child: InkWell(
                  onTap: () {
                    setState(() {
                      isAddingFare = !isAddingFare;
                    });
                  },
                  child: Icon(
                    (isAddingFare)
                        ? Icons.remove_circle
                        : Icons.add_circle_rounded,
                    size: 20,
                    color: (isAddingFare) ? Colors.red : Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        if (isAddingFare)
          NewDynamicFareWidget(
            screenSize: widget.screenSize,
            dynamicFares: dynamicFares,
            onAdd: (Map<String, dynamic> newFareInfo) {
              setState(() {
                dynamicFares.add(newFareInfo);
                resetDynamicControllersValues();
                isAddingFare = false;
              });
            },
          ),
        SizedBox(
          height: 130,
          child: ScrollConfiguration(
            behavior: CustomScrollBehavior(),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: dynamicFares.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (_, int index) {
                Map<String, dynamic> data = dynamicFares[index];
                return _buildDynamicItem(data, index);
              },
            ),
          ),
        )
      ],
    );
  }

  Container _buildDynamicItem(Map<String, dynamic> data, int fareIndex) {
    return Container(
      margin: const EdgeInsets.only(
        right: 40,
      ),
      width: isDesktop ? widget.screenSize.blockWidth * 0.275 : 165,
      child: Column(
        children: [
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "${data["name"]}",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isDesktop ? 14 : 10,
                ),
              ),
              const SizedBox(
                width: 3,
              ),
              CustomTooltip(
                message: "Eliminar tarifa",
                child: InkWell(
                  onTap: () {
                    if (dynamicFares.length == 1) {
                      LocalNotificationService.showSnackBar(
                        type: "fail",
                        message: "No puedes eliminar todas la tarifas",
                        icon: Icons.error_outline,
                      );
                      return;
                    }
                    setState(() {
                      dynamicFares.removeWhere(
                          (element) => element["key"] == data["key"]);
                      resetDynamicControllersValues();
                    });
                  },
                  child: const Icon(
                    Icons.delete,
                    size: 20,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          OverflowBar(
            spacing: 15,
            overflowSpacing: 15,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Text(
                        "Tarifa cliente",
                        style: TextStyle(
                            fontSize: isDesktop ? 13 : 10, color: Colors.grey),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: isDesktop
                            ? widget.screenSize.blockWidth * 0.13
                            : widget.screenSize.width * 0.06,
                        height: 35,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: UiVariables.lightBlueColor,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 0, horizontal: 8),
                          child: Center(
                            child: TextField(
                              textAlign: TextAlign.center,
                              controller:
                                  dynamicControllers[fareIndex + fareIndex],
                              style: TextStyle(
                                fontSize: isDesktop ? 15 : 11,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.only(bottom: 10),
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              keyboardType: TextInputType.number,
                              onChanged: (String value) {
                                if (value.isEmpty) {
                                  setState(() {
                                    dynamicControllers[fareIndex + fareIndex]
                                        .text = "0";
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        "Tarifa colaborador",
                        style: TextStyle(
                            fontSize: isDesktop ? 13 : 10, color: Colors.grey),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: isDesktop
                            ? widget.screenSize.blockWidth * 0.13
                            : widget.screenSize.width * 0.06,
                        height: 35,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: UiVariables.lightBlueColor,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 0, horizontal: 8),
                          child: Center(
                            child: TextField(
                              textAlign: TextAlign.center,
                              controller:
                                  dynamicControllers[fareIndex + fareIndex + 1],
                              style: TextStyle(
                                fontSize: isDesktop ? 15 : 11,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.only(bottom: 10),
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              keyboardType: TextInputType.number,
                              onChanged: (String value) {
                                if (value.isEmpty) {
                                  setState(() {
                                    dynamicControllers[
                                            fareIndex + fareIndex + 1]
                                        .text = "0";
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Align _buildSaveBtn() {
    return Align(
      alignment: Alignment.center,
      child: InkWell(
        onTap: () async {
          // if (normalControllers.any(
          //     (TextEditingController controller) => controller.text == "0")) {
          //   LocalNotificationService.showSnackBar(
          //     type: "fail",
          //     message: "Tienes campos con ceros en la tarifa normal",
          //     icon: Icons.error_outline,
          //   );
          //   return;
          // }
          // if (int.parse(normalControllers[0].text) <=
          //     int.parse(normalControllers[1].text)) {
          //   LocalNotificationService.showSnackBar(
          //     type: "fail",
          //     message:
          //         "En la tarifa normal, el valor para el cliente debe ser mayor al valor para el colaborador",
          //     icon: Icons.error_outline,
          //   );
          //   return;
          // }
          // if (holidayControllers.any(
          //     (TextEditingController controller) => controller.text == "0")) {
          //   LocalNotificationService.showSnackBar(
          //     type: "fail",
          //     message: "Tienes campos con ceros en la tarifa festiva",
          //     icon: Icons.error_outline,
          //   );
          //   return;
          // }
          // if (int.parse(holidayControllers[0].text) <=
          //     int.parse(holidayControllers[1].text)) {
          //   LocalNotificationService.showSnackBar(
          //     type: "fail",
          //     message:
          //         "En la tarifa festiva, el valor para el cliente debe ser mayor al valor para el colaborador",
          //     icon: Icons.error_outline,
          //   );
          //   return;
          // }
          // if (dynamicControllers.any(
          //     (TextEditingController controller) => controller.text == "0")) {
          //   LocalNotificationService.showSnackBar(
          //     type: "fail",
          //     message: "Tienes campos con ceros en la tarifa dinámica",
          //     icon: Icons.error_outline,
          //   );
          //   return;
          // }

          Map<String, dynamic> dynamicFaresMap = {};
          for (var i = 0; i < dynamicFares.length; i++) {
            Map<String, dynamic> dynamicFare = dynamicFares[i];

            if (int.parse(dynamicControllers[i + i].text) >
                int.parse(dynamicControllers[i + i + 1].text)) {
              dynamicFaresMap[dynamicFare["key"]] = {
                "name": dynamicFare["name"],
                "key": dynamicFare["key"],
                "client_fare": int.parse(dynamicControllers[i + i].text),
                "employee_fare": int.parse(dynamicControllers[i + i + 1].text),
              };
            }
            // else {
            //   LocalNotificationService.showSnackBar(
            //     type: "fail",
            //     message:
            //         "El valor de la tarifa dinámica para el cliente debe ser mayor al valor de la tarifa dinámica para colaborador",
            //     icon: Icons.error_outline,
            //   );
            //   return;
            // }
          }

          if (widget.fromClient) {
            await faresProvider.updateJobFares(
              {
                "type": "client",
                "client_id": widget.clientId,
                "job": widget.fareData["value"],
                'job_name': widget.fareData['name'],
                "normal": {
                  "name": "Normal",
                  "client_fare": int.parse(normalControllers[0].text),
                  "employee_fare": int.parse(normalControllers[1].text),
                },
                "holiday": {
                  "name": "Festiva",
                  "client_fare": int.parse(holidayControllers[0].text),
                  "employee_fare": int.parse(holidayControllers[1].text),
                },
                "dynamic": dynamicFaresMap,
              },
            );
          } else {
            await faresProvider.updateJobFares(
              {
                "type": "admin",
                "country": "costa_rica",
                "job": widget.fareData["value"],
                'job_name': widget.fareData['name'],
                "normal": {
                  "name": "Normal",
                  "client_fare": int.parse(normalControllers[0].text),
                  "employee_fare": int.parse(normalControllers[1].text),
                },
                "holiday": {
                  "name": "Festiva",
                  "client_fare": int.parse(holidayControllers[0].text),
                  "employee_fare": int.parse(holidayControllers[1].text),
                },
                "dynamic": dynamicFaresMap,
              },
            );
          }

          if (widget.onUpdate != null) {
            widget.onUpdate!();
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.green,
          ),
          padding: const EdgeInsets.all(10),
          child: const Text(
            "Actualizar valores",
            style: TextStyle(
              color: Colors.white,
              //  fontSize: isDesktop ? 16 : 12,
            ),
          ),
        ),
      ),
      //backgroundColor: UiVariables.primaryColor,
      // ),
    );
  }
}
