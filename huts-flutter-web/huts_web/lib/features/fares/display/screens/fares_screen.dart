import 'package:flutter/material.dart';
import 'package:huts_web/core/utils/ui/widgets/fares/night_surcharge_dialog.dart';
import 'package:huts_web/features/fares/display/widgets/create_doc_dialog.dart';
import 'package:huts_web/features/fares/display/widgets/new_job/create_job_dialog.dart';
import 'package:huts_web/features/fares/display/widgets/job_fare_widget.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/ui/ui_variables.dart';
import '../../../auth/domain/entities/screen_size_entity.dart';
import '../../../general_info/display/providers/general_info_provider.dart';

class FaresScreen extends StatefulWidget {
  const FaresScreen({Key? key}) : super(key: key);

  @override
  State<FaresScreen> createState() => _FaresScreenState();
}

class _FaresScreenState extends State<FaresScreen> {
  late ScreenSize screenSize;
  late GeneralInfoProvider generalInfoProvider;
  bool isScreeLoaded = false;
  bool isDesktop = false;
  @override
  void didChangeDependencies() async {
    if (isScreeLoaded) return;
    isScreeLoaded = true;
    generalInfoProvider = Provider.of<GeneralInfoProvider>(context);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    screenSize =
        Provider.of<GeneralInfoProvider>(context, listen: false).screenSize;
    isDesktop = screenSize.width >= 1020;
    return SizedBox(
      height: screenSize.height,
      width: screenSize.blockWidth,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OverflowBar(
                alignment: MainAxisAlignment.spaceBetween,
                overflowSpacing: 15,
                children: [
                  _buildTitle(),
                  OverflowBar(
                    overflowSpacing: 20,
                    spacing: 30,
                    children: [
                      _buildCreateDocBtn(),
                      _buildCreateJobBtn(),
                      _buildEditSurchargeBtn(),
                    ],
                  ),
                ],
              ),
              _buildFares(),
            ],
          ),
        ),
      ),
    );
  }

  InkWell _buildCreateDocBtn() {
    return InkWell(
      onTap: () async => await CreateDocDialog.show(), //CreateJobDialog.show(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 25),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: UiVariables.primaryColor,
          boxShadow: const [
            BoxShadow(
              offset: Offset(0, 2),
              blurRadius: 2,
              color: Colors.black12,
            ),
          ],
        ),
        child: const Text(
          "Agregar documento",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  InkWell _buildEditSurchargeBtn() {
    return InkWell(
      onTap: () => NightSurchargeDialog.show(
        data: generalInfoProvider.generalInfo.countryInfo.nightWorkshift,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 25),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: UiVariables.primaryColor,
          boxShadow: const [
            BoxShadow(
              offset: Offset(0, 2),
              blurRadius: 2,
              color: Colors.black12,
            ),
          ],
        ),
        child: const Text(
          "Editar recargo nocturno",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // InkWell _buildViewDocBtn() {
  //   return InkWell(
  //     onTap: () async => await DeleteDocDialog.show(), //CreateJobDialog.show(),
  //     child: Container(
  //       padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 25),
  //       decoration: BoxDecoration(
  //         borderRadius: BorderRadius.circular(10),
  //         color: UiVariables.primaryColor,
  //         boxShadow: const [
  //           BoxShadow(
  //             offset: Offset(0, 2),
  //             blurRadius: 2,
  //             color: Colors.black12,
  //           ),
  //         ],
  //       ),
  //       child: const Text(
  //         "Eliminar documento",
  //         style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
  //       ),
  //     ),
  //   );
  // }

  InkWell _buildCreateJobBtn() {
    return InkWell(
      onTap: () => CreateJobDialog.show(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 25),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: UiVariables.primaryColor,
          boxShadow: const [
            BoxShadow(
              offset: Offset(0, 2),
              blurRadius: 2,
              color: Colors.black12,
            ),
          ],
        ),
        child: const Text(
          "Agregar cargo",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Container _buildFares() {
    // generalInfoProvider.jobsFares.sort(
    //   (a, b) => a["name"].toLowerCase().compareTo(
    //         b["name"].toLowerCase(),
    //       ),
    // );
    return Container(
      margin: const EdgeInsets.only(top: 25),
      width: screenSize.blockWidth,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: 10,
        runSpacing: 10,
        direction: isDesktop ? Axis.horizontal : Axis.vertical,
        children: generalInfoProvider.jobsFares.map((info) {
          return OverflowBar(
            children: [
              JobFareWidget(
                screenSize: screenSize,
                fareData: info,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Column _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Tarifas",
          style: TextStyle(
            color: Colors.black,
            fontSize: screenSize.width * 0.016,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          "Tarifas por defecto de Huts.",
          style: TextStyle(
            color: Colors.black54,
            fontSize: screenSize.width * 0.01,
          ),
        ),
      ],
    );
  }
}
