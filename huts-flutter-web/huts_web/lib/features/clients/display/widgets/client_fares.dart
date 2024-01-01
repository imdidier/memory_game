// ignore_for_file: use_build_context_synchronously

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/utils/ui/widgets/fares/night_surcharge_dialog.dart';
import 'package:huts_web/core/utils/ui/widgets/jobs/job_selection/dialog.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/clients/display/provider/clients_provider.dart';
import 'package:huts_web/features/fares/display/widgets/job_fare_widget.dart';
import 'package:huts_web/features/general_info/display/providers/general_info_provider.dart';
import 'package:huts_web/features/general_info/domain/entities/general_info_entity.dart';
import 'package:provider/provider.dart';
import 'package:confirm_dialog/confirm_dialog.dart';

import '../../../../core/services/local_notification_service.dart';
import '../../../../core/utils/ui/ui_methods.dart';
import '../../../../core/utils/ui/ui_variables.dart';

class ClientFares extends StatefulWidget {
  final ClientsProvider clientsProvider;
  const ClientFares({Key? key, required this.clientsProvider})
      : super(key: key);

  @override
  State<ClientFares> createState() => _ClientFaresState();
}

class _ClientFaresState extends State<ClientFares> {
  bool isWidgetLoaded = false;
  ScreenSize? screenSize;
  GeneralInfo? generalInfo;
  bool isDynamicFareEnabled = false;
  List<JobFareWidget> jobsFares = [];
  bool isDesktop = false;

  @override
  void didChangeDependencies() {
    if (isWidgetLoaded) return;
    isWidgetLoaded = true;
    isDynamicFareEnabled =
        widget.clientsProvider.selectedClient!.accountInfo.hasDynamicFare;
    screenSize ??= Provider.of<GeneralInfoProvider>(context).screenSize;
    generalInfo ??= Provider.of<GeneralInfoProvider>(context).generalInfo;

    _getFareWidgets();
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    screenSize ??= Provider.of<GeneralInfoProvider>(context).screenSize;
    isDesktop = screenSize!.width >= 1300;
    return Container(
      padding: const EdgeInsets.all(5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Tarifas",
            style: TextStyle(
                color: Colors.black,
                fontSize: screenSize!.width * 0.016,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 3),
          Text(
            "Información de tarifas del cliente",
            style: TextStyle(
              color: Colors.black54,
              fontSize: screenSize!.width * 0.01,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            // alignment: MainAxisAlignment.spaceBetween,
            // overflowSpacing: 10,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () async {
                      List<Map<String, dynamic>> generalJobs = [
                        ...Provider.of<GeneralInfoProvider>(context,
                                listen: false)
                            .generalInfo
                            .countryInfo
                            .jobsFares
                            .values
                            .toList(),
                      ];

                      widget.clientsProvider.selectedClient!.jobs
                          .forEach((key, value) {
                        generalJobs
                            .removeWhere((element) => element["value"] == key);
                      });
                      generalJobs.sort((a, b) => a["name"]
                          .toLowerCase()
                          .compareTo(b["name"].toLowerCase()));

                      List<Map<String, dynamic>>? selectedJobs =
                          await JobSelectionDialog.show(jobs: generalJobs);

                      if (selectedJobs == null) return;

                      UiMethods().showLoadingDialog(context: context);
                      await Future.forEach(
                        selectedJobs,
                        (Map<String, dynamic> selectedJob) async {
                          selectedJob.remove("is_expanded");
                          await widget.clientsProvider.updateClientInfo(
                            {
                              "type": "add",
                              "job_info": selectedJob,
                            },
                            "jobs",
                            true,
                          );
                        },
                      );

                      UiMethods().hideLoadingDialog(context: context);

                      LocalNotificationService.showSnackBar(
                        type: "success",
                        message: "Información actualizada correctamente",
                        icon: Icons.check,
                      );
                      _getFareWidgets();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      height: screenSize!.height * 0.042,
                      decoration: BoxDecoration(
                        color: UiVariables.primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          "Agregar cargos",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenSize!.blockWidth >= 920 ? 13 : 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  InkWell(
                    onTap: () => NightSurchargeDialog.show(
                      data:
                          widget.clientsProvider.selectedClient!.nightWorkShift,
                      clientId:
                          widget.clientsProvider.selectedClient!.accountInfo.id,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      height: screenSize!.height * 0.042,
                      decoration: BoxDecoration(
                        color: UiVariables.primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          "Editar recargo nocturno",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenSize!.blockWidth >= 920 ? 13 : 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    "¿Usar tarifa dinámica?",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: screenSize!.blockWidth >= 920 ? 15 : 12,
                    ),
                  ),
                  Transform.scale(
                    scale: 0.8,
                    child: CupertinoSwitch(
                      value: widget.clientsProvider.selectedClient!.accountInfo
                          .hasDynamicFare,
                      onChanged: (newValue) async {
                        bool itsConfirmed = await confirm(
                          context,
                          title: Text(
                            "Cambiar tarifa dinámica",
                            style: TextStyle(
                              color: UiVariables.primaryColor,
                            ),
                          ),
                          content: Text(
                            newValue
                                ? "¿Quieres habilitar la tarifa dinámica para este cliente?"
                                : "¿Quieres deshabilitar la tarifa dinámica para este cliente?",
                          ),
                          textCancel: const Text(
                            "Cancelar",
                            style: TextStyle(color: Colors.grey),
                          ),
                          textOK: const Text(
                            "Aceptar",
                            style: TextStyle(color: Colors.blue),
                          ),
                        );

                        if (!itsConfirmed) return;

                        UiMethods().showLoadingDialog(context: context);
                        await widget.clientsProvider.updateClientInfo(
                          {"new_value": newValue},
                          "dynamic_fare",
                          true,
                        );
                        UiMethods().hideLoadingDialog(context: context);
                      },
                    ),
                  ),
                ],
              )
            ],
          ),
          Container(
            margin: const EdgeInsets.only(top: 45),
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceEvenly,
              spacing: 10,
              runSpacing: 10,
              direction: Axis.horizontal,
              children: jobsFares,
            ),
          ),
          // _buildUpdateBtn(),
        ],
      ),
    );
  }

  void _getFareWidgets() {
    jobsFares.clear();

    widget.clientsProvider.selectedClient!.jobs = Map.fromEntries(
      widget.clientsProvider.selectedClient!.jobs.entries.toList()
        ..sort(
          (e1, e2) => e1.value["name"].toLowerCase().compareTo(
                e2.value["name"].toLowerCase(),
              ),
        ),
    );

    widget.clientsProvider.selectedClient!.jobs.values.toList().forEach(
      (info) {
        info["is_expanded"] = false;
        jobsFares.add(
          JobFareWidget(
            screenSize: screenSize!,
            fareData: info,
            fromClient: true,
            clientId: widget.clientsProvider.selectedClient!.accountInfo.id,
            onDelete: () => _getFareWidgets(),
            onUpdate: () => _getFareWidgets(),
          ),
        );
      },
    );
    if (mounted) setState(() {});
  }
}
