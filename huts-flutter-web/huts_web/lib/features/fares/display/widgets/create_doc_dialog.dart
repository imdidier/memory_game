import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/features/fares/display/provider/fares_provider.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/local_notification_service.dart';
import '../../../../core/services/navigation_service.dart';
import '../../../../core/utils/ui/ui_variables.dart';
import '../../../auth/domain/entities/screen_size_entity.dart';
import '../../../general_info/display/providers/general_info_provider.dart';

class CreateDocDialog {
  static Future<void> show() async {
    BuildContext? globalContext = NavigationService.getGlobalContext();
    if (globalContext == null) return;

    showDialog(
      context: globalContext,
      barrierDismissible: false,
      builder: (_) {
        return SingleChildScrollView(
          child: WillPopScope(
            onWillPop: () async => false,
            child: const AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(15),
                ),
              ),
              titlePadding: EdgeInsets.zero,
              title: _DialogContent(),
            ),
          ),
        );
      },
    );
  }
}

class _DialogContent extends StatefulWidget {
  const _DialogContent({Key? key}) : super(key: key);

  @override
  State<_DialogContent> createState() => __DialogContentState();
}

class __DialogContentState extends State<_DialogContent> {
  bool isWidgetLoaded = false;
  late ScreenSize screenSize;
  late GeneralInfoProvider generalInfoProvider;
  TextEditingController docNameController = TextEditingController();
  bool isRequired = true;
  bool canExpire = false;
  List<Map<String, dynamic>> systemJobs = [];
  List<String> systemDocsKeys = [];

  bool isDesktop = false;

  @override
  void didChangeDependencies() {
    if (isWidgetLoaded) return;
    isWidgetLoaded = true;
    generalInfoProvider = Provider.of<GeneralInfoProvider>(context);
    systemDocsKeys =
        generalInfoProvider.generalInfo.countryInfo.requiredDocs.keys.toList();
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
            _buildFooter(),
            _buildHeader(),
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
              if (docNameController.text.isEmpty) {
                LocalNotificationService.showSnackBar(
                  type: "fail",
                  message: "Debes agregar el nombre del documento",
                  icon: Icons.error_outline,
                );
                return;
              }
              String docKey = docNameController.text
                  .trim()
                  .toLowerCase()
                  .replaceAll(" ", "_");

              if (systemDocsKeys.contains(docKey)) {
                LocalNotificationService.showSnackBar(
                  type: "fail",
                  message: "Ya existe un documento con el nombre ingresado",
                  icon: Icons.error_outline,
                );
                return;
              }

              if (systemJobs.every((element) => !element["is_selected"])) {
                LocalNotificationService.showSnackBar(
                  type: "fail",
                  message: "Debes seleccionar al menos un cargo",
                  icon: Icons.error_outline,
                );
                return;
              }

              Map<String, dynamic> docData = {
                "key": docKey,
                "doc_name": docNameController.text,
                "required": isRequired,
                "can_expire": canExpire,
                "jobs": systemJobs
                    .expand(
                      (element) => [
                        if (element["is_selected"]) element["key"],
                      ],
                    )
                    .toList()
              };

              await Provider.of<FaresProvider>(context, listen: false)
                  .createDoc(docData);
            },
            child: Container(
              width: 150,
              height: 35,
              decoration: BoxDecoration(
                color: UiVariables.primaryColor.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  "Crear documento",
                  style: TextStyle(
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
            Text(
              " Agregar nuevo documento a Huts",
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style:
                  TextStyle(color: Colors.white, fontSize: isDesktop ? 20 : 16),
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
          alignment: MainAxisAlignment.spaceBetween,
          spacing: 15,
          overflowSpacing: 15,
          children: [
            _buildOptionsSection(),
            _buildNameField(),
            _buildJobsSection()
          ],
        ),
      ),
    );
  }

  Column _buildJobsSection() {
    if (systemJobs.isEmpty) {
      generalInfoProvider.generalInfo.countryInfo.jobsFares
          .forEach((key, value) {
        value["key"] = key;
        value["is_selected"] = false;
        systemJobs.add(value);
      });
    }

    return Column(
      children: [
        const Text(
          "Cargos para este documento",
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        Wrap(
          spacing: 15,
          runSpacing: 10,
          direction:
              screenSize.blockWidth >= 920 ? Axis.horizontal : Axis.vertical,
          children: systemJobs
              .map(
                (jobData) => Container(
                  margin: const EdgeInsets.only(top: 20, bottom: 20),
                  padding: const EdgeInsets.all(10),
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    // crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: Transform.scale(
                          scale: 0.6,
                          child: CupertinoSwitch(
                            value: jobData["is_selected"],
                            onChanged: (bool newValue) {
                              setState(() {
                                jobData["is_selected"] = newValue;
                              });
                            },
                          ),
                        ),
                      ),
                      SizedBox(
                        width: screenSize.blockWidth >= 920
                            ? screenSize.blockWidth * 0.095
                            : screenSize.blockWidth * 0.43,
                        child: Text(
                          "${jobData["name"]}",
                          style: const TextStyle(
                            overflow: TextOverflow.ellipsis,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        )
      ],
    );
  }

  Column _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Nombre del documento",
          style: TextStyle(
            fontSize: 16,
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
              keyboardType: TextInputType.text,
              controller: docNameController,
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

  OverflowBar _buildOptionsSection() {
    return OverflowBar(
      // mainAxisAlignment: MainAxisAlignment.spaceBetween,
      // alignment: MainAxisAlignment.spaceBetween,
      children: [
        buildRequiredOption(),
        const SizedBox(width: 30),
        buildExpireOption(),
      ],
    );
  }

  OverflowBar buildRequiredOption() {
    return OverflowBar(
      spacing: 10,
      overflowSpacing: 10,
      children: [
        const Text(
          "¿Documento obligatorio?",
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        const SizedBox(width: 5),
        Checkbox(
          activeColor: Colors.green,
          value: isRequired,
          onChanged: (bool? newValue) {
            setState(() {
              isRequired = newValue!;
            });
          },
        )
      ],
    );
  }

  OverflowBar buildExpireOption() {
    return OverflowBar(
      children: [
        const Text(
          "¿Documento con expiración?",
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        const SizedBox(width: 5),
        Checkbox(
          activeColor: Colors.green,
          value: canExpire,
          onChanged: (bool? newValue) {
            setState(() {
              canExpire = newValue!;
            });
          },
        )
      ],
    );
  }
}
