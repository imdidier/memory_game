import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huts_web/core/services/local_notification_service.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';

import '../../../../core/utils/ui/ui_variables.dart';

class NewDynamicFareWidget extends StatefulWidget {
  final ScreenSize screenSize;
  final List<Map<String, dynamic>> dynamicFares;
  final Function onAdd;
  const NewDynamicFareWidget({
    required this.screenSize,
    required this.dynamicFares,
    required this.onAdd,
    Key? key,
  }) : super(key: key);

  @override
  State<NewDynamicFareWidget> createState() => _NewDynamicFareWidgetState();
}

class _NewDynamicFareWidgetState extends State<NewDynamicFareWidget> {
  TextEditingController newFareIRContoller = TextEditingController();
  TextEditingController newFareFRContoller = TextEditingController();
  TextEditingController newFareCFContoller = TextEditingController();
  TextEditingController newFareEFContoller = TextEditingController();
  bool isDesktop = false;
  @override
  Widget build(BuildContext context) {
    isDesktop = widget.screenSize.width >= 1100;
    return Column(
      children: [
        const SizedBox(height: 15),
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                buildTextFieldItem(
                  title: "Rango inicial",
                  controller: newFareIRContoller,
                ),
                buildTextFieldItem(
                  title: "Rango final",
                  controller: newFareFRContoller,
                )
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                buildTextFieldItem(
                  title: "Tarifa cliente",
                  controller: newFareCFContoller,
                ),
                buildTextFieldItem(
                  title: "Tarifa colaborador",
                  controller: newFareEFContoller,
                ),
              ],
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 20, right: 10),
            child: InkWell(
              onTap: () {
                String resp = validateFields();

                if (resp != "isValid") {
                  LocalNotificationService.showSnackBar(
                    type: "fail",
                    message: resp,
                    icon: Icons.error_outline,
                  );
                  return;
                }

                bool isSameRange =
                    newFareIRContoller.text == newFareFRContoller.text;

                String fareName = isSameRange
                    ? "Dinámica más de ${newFareIRContoller.text} horas"
                    : "Dinámica entre ${newFareIRContoller.text} y ${newFareFRContoller.text} horas";

                String fareKey = isSameRange
                    ? newFareIRContoller.text
                    : "${newFareIRContoller.text}-${newFareFRContoller.text}";

                widget.onAdd(
                  {
                    "key": fareKey,
                    "name": fareName,
                    "client_fare": int.parse(newFareCFContoller.text),
                    "employee_fare": int.parse(newFareEFContoller.text),
                  },
                );
              },
              child: Text(
                "Agregar Tarifa",
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                  fontSize: isDesktop ? 16 : 12,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 45),
      ],
    );
  }

  Column buildTextFieldItem(
      {required String title, required TextEditingController controller}) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(fontSize: isDesktop ? 13 : 10, color: Colors.grey),
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
            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
            child: Center(
              child: TextField(
                textAlign: TextAlign.center,
                controller: controller,
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
                      controller.text = "0";
                    });
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  String validateFields() {
    String message = "Hay campos vacíos o con ceros";

    if (newFareCFContoller.text.isEmpty || newFareCFContoller.text == "0") {
      return message;
    }
    if (newFareEFContoller.text.isEmpty || newFareEFContoller.text == "0") {
      return message;
    }
    if (newFareIRContoller.text.isEmpty || newFareIRContoller.text == "0") {
      return message;
    }
    if (newFareFRContoller.text.isEmpty || newFareFRContoller.text == "0") {
      return message;
    }

    int newInitialRange = int.parse(newFareIRContoller.text);
    int newFinalRange = int.parse(newFareFRContoller.text);

    if (newInitialRange > newFinalRange) {
      return "El rango inicial debe ser mayor al final";
    }

    message =
        "Los rangos de la nueva tarifa se cruzan con los actualmente registrados";

    for (Map<String, dynamic> fareItem in widget.dynamicFares) {
      //If current fare has two ranges//
      if (fareItem["key"].contains("-")) {
        int currentInitialRange = int.parse(fareItem["key"].split("-")[0]);
        int currentFinalRange = int.parse(fareItem["key"].split("-")[1]);

        //If new fare has two ranges//
        if (newInitialRange != newFinalRange) {
          //When new ranges are inside current ranges//
          if (newInitialRange >= currentInitialRange &&
              newInitialRange <= currentFinalRange &&
              newFinalRange >= currentInitialRange &&
              newFinalRange <= currentFinalRange) {
            return message;
          }

          //When current ranges  are inside new ranges//
          if (currentInitialRange >= newInitialRange &&
              currentInitialRange <= newFinalRange &&
              currentFinalRange >= newInitialRange &&
              currentFinalRange <= newFinalRange) {
            return message;
          }

          //When they are crossed starting with current//
          if (newInitialRange >= currentInitialRange &&
              newInitialRange <= currentFinalRange &&
              currentFinalRange >= newInitialRange &&
              currentFinalRange <= newFinalRange) {
            return message;
          }

          //When they are crossed starting with new//
          if (currentInitialRange >= newInitialRange &&
              currentInitialRange <= newFinalRange &&
              newFinalRange >= currentInitialRange &&
              newFinalRange <= currentFinalRange) {
            return message;
          }
        }
        //If new fare has one range//
        else {
          if (newInitialRange >= currentInitialRange &&
              newInitialRange <= currentFinalRange) {
            return message;
          }
        }
      }
      //If current fare has one range//
      else {
        int currenRange = int.parse(fareItem["key"]);
        //If new fare has two ranges//
        if (newInitialRange != newFinalRange) {
          if (currenRange >= newInitialRange && currenRange <= newFinalRange) {
            return message;
          }
        }
        //If new fare has one range//
        else {
          if (currenRange >= newInitialRange ||
              newInitialRange >= currenRange) {
            return message;
          }
        }
      }
    }

    return "isValid";
  }
}
