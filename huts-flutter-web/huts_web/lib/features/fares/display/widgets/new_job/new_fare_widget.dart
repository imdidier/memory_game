import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:provider/provider.dart';
import '../../../../../core/services/local_notification_service.dart';
import '../../../../../core/utils/ui/ui_variables.dart';
import '../../../../../core/utils/ui/widgets/general/custom_scroll_behavior.dart';
import '../../../../../core/utils/ui/widgets/general/custom_tooltip.dart';
import '../../provider/fares_provider.dart';
import '../new_dynamic_fare.dart';

class NewFareWidget extends StatefulWidget {
  final ScreenSize screenSize;

  const NewFareWidget({required this.screenSize, Key? key}) : super(key: key);

  @override
  State<NewFareWidget> createState() => _NewFareWidgetState();
}

class _NewFareWidgetState extends State<NewFareWidget> {
  bool isWidgetLoaded = false;
  bool isAddingFare = false;

  late FaresProvider faresProvider;

  @override
  void didChangeDependencies() {
    if (isWidgetLoaded) return;
    faresProvider = Provider.of<FaresProvider>(context);
    _setControllersValues();
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(offset: Offset(0, 2), color: Colors.black12, blurRadius: 2)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: widget.screenSize.blockWidth >= 920
                ? widget.screenSize.blockWidth * 0.6
                : widget.screenSize.blockWidth - 40,
            child: widget.screenSize.blockWidth <= 920
                ? OverflowBar(
                    spacing: 20,
                    overflowSpacing: 20,
                    alignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildNormalFare(),
                      _buildHolidayFare(),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildNormalFare(),
                      _buildHolidayFare(),
                    ],
                  ),
          ),
          _buildDynamicFares(),
        ],
      ),
    );
  }

  Column _buildNormalFare() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 10),
        Text(
          "Normal",
          textAlign: widget.screenSize.blockWidth >= 920
              ? TextAlign.start
              : TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: widget.screenSize.blockWidth >= 920 ? 13 : 10,
          ),
        ),
        const SizedBox(height: 8),
        OverflowBar(
          overflowAlignment: OverflowBarAlignment.center,
          spacing: 15,
          overflowSpacing: 15,
          children: [
            Column(
              children: [
                Text(
                  "Tarifa cliente",
                  style: TextStyle(
                      fontSize: widget.screenSize.blockWidth >= 920 ? 13 : 10,
                      color: Colors.grey),
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
                        controller: faresProvider.normalControllers[0],
                        style: TextStyle(
                          fontSize:
                              widget.screenSize.blockWidth >= 920 ? 15 : 11,
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
                              faresProvider.normalControllers[0].text = "0";
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
                      fontSize: widget.screenSize.blockWidth >= 920 ? 13 : 10,
                      color: Colors.grey),
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
                        controller: faresProvider.normalControllers[1],
                        style: TextStyle(
                          fontSize:
                              widget.screenSize.blockWidth >= 920 ? 15 : 11,
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
                              faresProvider.normalControllers[1].text = "0";
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 10),
        Text(
          "Festiva",
          textAlign: widget.screenSize.blockWidth >= 920
              ? TextAlign.start
              : TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: widget.screenSize.blockWidth >= 920 ? 13 : 10,
          ),
        ),
        const SizedBox(height: 15),
        OverflowBar(
          overflowAlignment: OverflowBarAlignment.center,
          spacing: 15,
          overflowSpacing: 15,
          children: [
            Column(
              children: [
                Text(
                  "Tarifa cliente",
                  style: TextStyle(
                      fontSize: widget.screenSize.blockWidth >= 920 ? 13 : 10,
                      color: Colors.grey),
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
                        controller: faresProvider.holidayControllers[0],
                        style: TextStyle(
                          fontSize:
                              widget.screenSize.blockWidth >= 920 ? 15 : 11,
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
                              faresProvider.holidayControllers[0].text = "0";
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
                      fontSize: widget.screenSize.blockWidth >= 920 ? 13 : 10,
                      color: Colors.grey),
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
                        controller: faresProvider.holidayControllers[1],
                        style: TextStyle(
                          fontSize:
                              widget.screenSize.blockWidth >= 920 ? 15 : 11,
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
                              faresProvider.holidayControllers[1].text = "0";
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Row(
            children: [
              Text(
                "Dinámicas",
                textAlign: widget.screenSize.blockWidth >= 920
                    ? TextAlign.start
                    : TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: widget.screenSize.blockWidth >= 920 ? 13 : 10,
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
            dynamicFares: faresProvider.dynamicFares,
            onAdd: (Map<String, dynamic> newFareInfo) {
              setState(() {
                faresProvider.dynamicFares.add(newFareInfo);
                resetDynamicControllersValues();
                isAddingFare = false;
              });
            },
          ),
        SizedBox(
          height: 120,
          child: ScrollConfiguration(
            behavior: CustomScrollBehavior(),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: faresProvider.dynamicFares.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (_, int index) {
                Map<String, dynamic> data = faresProvider.dynamicFares[index];
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
      margin: const EdgeInsets.only(right: 35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 5),
          Row(
            children: [
              Text(
                "${data["name"]}",
                style: TextStyle(
                  fontSize: widget.screenSize.blockWidth >= 920 ? 14 : 10,
                ),
              ),
              const SizedBox(width: 3),
              CustomTooltip(
                message: "Eliminar tarifa",
                child: InkWell(
                  onTap: () {
                    if (faresProvider.dynamicFares.length == 1) {
                      LocalNotificationService.showSnackBar(
                        type: "fail",
                        message: "No puedes eliminar todas la tarifas",
                        icon: Icons.error_outline,
                      );
                      return;
                    }
                    setState(() {
                      faresProvider.dynamicFares.removeWhere(
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
                            fontSize:
                                widget.screenSize.blockWidth >= 920 ? 13 : 10,
                            color: Colors.grey),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: widget.screenSize.blockWidth >= 920
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
                              controller: faresProvider
                                  .dynamicControllers[fareIndex + fareIndex],
                              style: TextStyle(
                                fontSize: widget.screenSize.blockWidth >= 920
                                    ? 15
                                    : 11,
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
                                    faresProvider
                                        .dynamicControllers[
                                            fareIndex + fareIndex]
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
              const SizedBox(width: 15),
              Column(
                children: [
                  Text(
                    "Tarifa colaborador",
                    style: TextStyle(
                        fontSize: widget.screenSize.blockWidth >= 920 ? 13 : 10,
                        color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: widget.screenSize.blockWidth >= 920
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
                          controller: faresProvider
                              .dynamicControllers[fareIndex + fareIndex + 1],
                          style: TextStyle(
                            fontSize:
                                widget.screenSize.blockWidth >= 920 ? 15 : 11,
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
                                faresProvider
                                    .dynamicControllers[
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
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  void resetDynamicControllersValues() {
    faresProvider.dynamicFares.sort((first, next) {
      int firstValue = int.parse(first["key"].split("-")[0]);
      int nextValue = int.parse(next["key"].split("-")[0]);
      return firstValue.compareTo(nextValue);
    });

    faresProvider.dynamicControllers.clear();

    for (Map<String, dynamic> dynamicFare in faresProvider.dynamicFares) {
      faresProvider.dynamicControllers
          .add(TextEditingController(text: "${dynamicFare["client_fare"]}"));
      faresProvider.dynamicControllers
          .add(TextEditingController(text: "${dynamicFare["employee_fare"]}"));
    }
  }

  void _setControllersValues() {
    faresProvider.normalControllers = [
      TextEditingController(
        text: "0",
      ),
      TextEditingController(
        text: "0",
      ),
    ];

    faresProvider.holidayControllers = [
      TextEditingController(
        text: "0",
      ),
      TextEditingController(
        text: "0",
      ),
    ];

    faresProvider.dynamicFares = [
      {
        "key": "1-299",
        "client_fare": 0,
        "employee_fare": 0,
        "name": "Dinámica entre 1 y 299 horas",
      },
      {
        "key": "300-599",
        "client_fare": 0,
        "employee_fare": 0,
        "name": "Dinámica entre 300 y 599 horas",
      },
      {
        "key": "600-999",
        "client_fare": 0,
        "employee_fare": 0,
        "name": "Dinámica entre 600 y 999 horas",
      },
      {
        "key": "1000",
        "client_fare": 0,
        "employee_fare": 0,
        "name": "Dinámica más de 1000 horas",
      },
    ];

    faresProvider.dynamicFares.sort((first, next) {
      int firstValue = int.parse(first["key"].split("-")[0]);
      int nextValue = int.parse(next["key"].split("-")[0]);
      return firstValue.compareTo(nextValue);
    });

    faresProvider.dynamicControllers.clear();

    for (Map<String, dynamic> dynamicFare in faresProvider.dynamicFares) {
      faresProvider.dynamicControllers
          .add(TextEditingController(text: "${dynamicFare["client_fare"]}"));
      faresProvider.dynamicControllers
          .add(TextEditingController(text: "${dynamicFare["employee_fare"]}"));
    }
  }
}
