import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/navigation_service.dart';
import '../../../../core/utils/ui/ui_variables.dart';
import '../../../auth/domain/entities/screen_size_entity.dart';
import '../../../general_info/display/providers/general_info_provider.dart';

class DeleteDocDialog {
  static Future<void> show() async {
    BuildContext? globalContext = NavigationService.getGlobalContext();
    if (globalContext == null) return;

    showDialog(
      context: globalContext,
      barrierDismissible: false,
      builder: (_) {
        return WillPopScope(
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
  bool isRequired = true;
  bool canExpire = false;
  List<String> systemDocsKeys = [];
  List<Map<String, dynamic>> systemDocs = [];

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
    return Container(
      width: screenSize.blockWidth * 0.4,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: const [
          //_buildBody(),
          //_buildHeader(),
          // _buildFooter(),
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
              // await Provider.of<FaresProvider>(context, listen: false)
              //     .deleteDoc(docData);
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
                  "Eliminar documento",
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

  Widget _buildDocsSelection() {
    if (generalInfoProvider.generalInfo.countryInfo.requiredDocs.isEmpty) {
      return const SizedBox();
    }
    if (systemDocs.isEmpty) {
      generalInfoProvider.generalInfo.countryInfo.requiredDocs.forEach(
        ((key, value) {
          value["key"] = key;
          value["is_selected"] = false;
          systemDocs.add(value);
        }),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 10),
        const Text(
          "Documentos",
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        Wrap(
          spacing: 20,
          runSpacing: 20,
          direction: Axis.horizontal,
          children: systemDocs
              .map(
                (docData) => Container(
                  margin: const EdgeInsets.only(top: 20, bottom: 20),
                  padding: const EdgeInsets.all(10),
                  width: screenSize.blockWidth * 0.16,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Text(
                            "Expira",
                            style: TextStyle(fontSize: 12),
                          ),
                          Checkbox(
                            activeColor: Colors.grey,
                            value: docData["can_expire"],
                            onChanged: (bool? newValue) {
                              return;
                            },
                          ),
                          const Text(
                            "Requerido",
                            style: TextStyle(fontSize: 12),
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
        )
      ],
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
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              "Eliminar documento de Huts",
              style: TextStyle(color: Colors.white),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 15),
            _buildDocsSelection(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
