import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:huts_web/core/utils/ui/widgets/general/custom_date_selector.dart';
import 'package:huts_web/core/utils/ui/widgets/general/data_table_from_responsive.dart';
import 'package:huts_web/features/pre_registered/display/provider/pre_registered_provider.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/code/code_utils.dart';
import '../../../../core/utils/ui/ui_methods.dart';
import '../../../../core/utils/ui/ui_variables.dart';
import '../../../auth/domain/entities/screen_size_entity.dart';
import '../../../general_info/display/providers/general_info_provider.dart';
import '../widgets/pre_registered_data_table.dart';

class PreRegisteredScreen extends StatefulWidget {
  const PreRegisteredScreen({Key? key}) : super(key: key);

  @override
  State<PreRegisteredScreen> createState() => _PreRegisteredScreenState();
}

class _PreRegisteredScreenState extends State<PreRegisteredScreen> {
  bool isScreenLoaded = false;

  late ScreenSize screenSize;
  UiVariables uiVariables = UiVariables();
  late PreRegisteredProvider preRegisteredProvider;
  List<List<String>> dataTableFromResponsive = [];
  bool imageAvailable = false;
  Uint8List? imageFile;
  String imageUrl = '';

  List<Map<String, dynamic>> employeeInfoTabs = [
    {
      "name": "Información",
      "text": "Información general del colaborador",
      "value": "info",
      "is_selected": true,
    },
    {
      "name": "Documentos",
      "text": "Visualiza, aprueba o rechaza los documentos del colaborador",
      "value": "docs",
      "is_selected": false,
    },
    {
      "name": "Cargos",
      "text": "Visualiza y modifica los cargos del colaborador",
      "value": "jobs",
      "is_selected": false,
    },
  ];

  int selectedEmployeeTab = 0;
  final ScrollController _scrollController = ScrollController();
  ValueNotifier<bool> showDateWidget = ValueNotifier<bool>(true);

  @override
  void didChangeDependencies() {
    if (isScreenLoaded) return;
    isScreenLoaded = true;
    preRegisteredProvider = Provider.of<PreRegisteredProvider>(context);

    super.didChangeDependencies();
  }

  bool isDesktop = false;

  @override
  Widget build(BuildContext context) {
    screenSize = Provider.of<GeneralInfoProvider>(context).screenSize;
    isDesktop = screenSize.width >= 1120;

    return SizedBox(
      height: screenSize.height,
      width: screenSize.blockWidth,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            NotificationListener(
              onNotification: (Notification notification) {
                if (_scrollController.position.pixels > 20 &&
                    showDateWidget.value) {
                  showDateWidget.value = false;

                  return true;
                }

                if (_scrollController.position.pixels <= 30 &&
                    !showDateWidget.value) {
                  showDateWidget.value = true;
                }
                return true;
              },
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildTitle(),
                    buildEmployeesWidget(),
                  ],
                ),
              ),
            ),
            Positioned(
              top: screenSize.height * 0.01,
              right: screenSize.blockWidth >= 920
                  ? screenSize.width * 0.016
                  : screenSize.width * 0.005,
              child: ValueListenableBuilder(
                  valueListenable: showDateWidget,
                  builder: (_, bool isvisible, __) {
                    return CustomDateSelector(
                      isVisible: true,
                      onDateSelected:
                          (DateTime? startDate, DateTime? endDate) async {
                        await preRegisteredProvider.listenEmployees(
                            startDate, endDate);
                      },
                    );
                  }),
            )
          ],
        ),
      ),
    );
  }

  Column buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Pre inscritos",
          style: TextStyle(
            color: Colors.black,
            fontSize: screenSize.width * 0.016,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          "Lista de colaboradores pre inscritos en Huts.",
          style: TextStyle(
            color: Colors.black54,
            fontSize: screenSize.width * 0.01,
          ),
        ),
      ],
    );
  }

  Column buildEmployeesWidget() {
    dataTableFromResponsive.clear();
    if (preRegisteredProvider.filteredEmployees.isNotEmpty) {
      dataTableFromResponsive.clear();
      for (var preRegistered in preRegisteredProvider.filteredEmployees) {
        dataTableFromResponsive.add([
          "Imagen-${preRegistered.profileInfo.image}",
          "Nombre-${CodeUtils.getFormatedName(preRegistered.profileInfo.names, preRegistered.profileInfo.lastNames)}",
          "Documento-${preRegistered.profileInfo.docNumber}",
          "Teléfono-${preRegistered.profileInfo.phone}",
          "Nacimineto-${CodeUtils.formatDateWithoutHour(preRegistered.profileInfo.birthday)}",
          "País-Costa Rica",
          "Cargos-${UiMethods.getJobsNamesBykeys(preRegistered.jobs)}",
          "Estado docs-${preRegistered.docsStatus}",
          "Estado-${preRegistered.accountInfo.status}",
          "Registro-${CodeUtils.formatDate(preRegistered.accountInfo.registerDate)}",
          "Id-${preRegistered.id}",
          "Acciones-",
        ]);
      }
    }
    return Column(
      children: [
        const SizedBox(height: 30),
        Row(
          // overflowAlignment: OverflowBarAlignment.start,
          // alignment: MainAxisAlignment.spaceBetween,
          // overflowSpacing: 5,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Total pre inscritos: ${preRegisteredProvider.employees.length}",
              style: const TextStyle(fontSize: 16),
            ),
            buildSearchBar(),
          ],
        ),
        screenSize.blockWidth >= 920
            ? buildEmployees()
            : DataTableFromResponsive(
                listData: dataTableFromResponsive,
                screenSize: screenSize,
                type: 'pre-register'),
      ],
    );
  }

  Widget buildSearchBar() {
    return Container(
      width: screenSize.blockWidth * 0.3,
      height: screenSize.height * 0.055,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            offset: Offset(0, 2),
            color: Colors.black26,
            blurRadius: 2,
          )
        ],
      ),
      child: TextField(
        controller: preRegisteredProvider.searchController,
        decoration: InputDecoration(
          suffixIcon: const Icon(Icons.search),
          hintText: "Buscar colaborador",
          hintStyle: TextStyle(
            color: Colors.black54,
            fontSize: isDesktop ? 14 : 10,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
              horizontal: 20, vertical: screenSize.blockWidth >= 920 ? 12 : 8),
        ),
        onChanged: preRegisteredProvider.filterEmployees,
      ),
    );
  }

  Container buildEmployees() {
    return Container(
        margin: EdgeInsets.only(top: screenSize.height * 0.04),
        child: PreRegisteredDataTable(screenSize: screenSize));
  }
}
