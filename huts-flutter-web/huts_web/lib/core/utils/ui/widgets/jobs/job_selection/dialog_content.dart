import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../features/auth/domain/entities/screen_size_entity.dart';
import '../../../../../../features/general_info/display/providers/general_info_provider.dart';
import '../../../../../services/local_notification_service.dart';
import '../../../ui_variables.dart';
import '../../general/data_table_from_responsive.dart';

class JobDialogContent extends StatefulWidget {
  final List<Map<String, dynamic>> jobs;

  const JobDialogContent({
    required this.jobs,
    super.key,
  });

  @override
  State<JobDialogContent> createState() => _JobDialogContentState();
}

class _JobDialogContentState extends State<JobDialogContent> {
  ScreenSize? screenSize;
  List<List<String>> dataTableFromResponsive = [];
  List<Map<String, dynamic>> filteredJobs = [];
  TextEditingController searchController = TextEditingController();
  bool isFilteredJobs = false;
  @override
  Widget build(BuildContext context) {
    screenSize ??=
        Provider.of<GeneralInfoProvider>(context, listen: false).screenSize;

    if (widget.jobs.isNotEmpty) {
      dataTableFromResponsive.clear();
      for (int i = 0; i < widget.jobs.length; i++) {
        Map<String, dynamic> job = widget.jobs[i];
        dataTableFromResponsive.add([
          'Acciones-',
          'Nombre-${job['name']}',
          'Identificador-${job['value']}',
        ]);
        if (!isFilteredJobs) widget.jobs[i]['is_selected'] = false;
      }

      if (!isFilteredJobs) {
        filteredJobs = [...widget.jobs];
        isFilteredJobs = true;
      }
    }

    return Container(
      width: screenSize!.blockWidth >= 920
          ? screenSize!.blockWidth * 0.65
          : screenSize!.blockWidth * 0.8,
      height: screenSize!.height >= 840
          ? screenSize!.height * 0.6
          : screenSize!.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          SingleChildScrollView(
            controller: ScrollController(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              margin: EdgeInsets.symmetric(vertical: screenSize!.height * 0.09),
              child: Column(
                children: [
                  buildSearchBar(),
                  screenSize!.blockWidth >= 920
                      ? JobsDataTable(
                          jobs: filteredJobs,
                          allJobs: widget.jobs,
                          screenSize: screenSize!,
                        )
                      : DataTableFromResponsive(
                          listData: dataTableFromResponsive,
                          screenSize: screenSize!,
                          type: 'select-job'),
                ],
              ),
            ),
          ),
          _buildHeader(context),
          _buildAceptBtn(),
        ],
      ),
    );
  }

  void filterJobs(String query) {
    filteredJobs.clear();
    if (query.isEmpty) {
      filteredJobs = [...widget.jobs];
    } else {
      for (var element in widget.jobs) {
        String nameJob = element['name'];
        if (nameJob.toLowerCase().contains(query)) {
          // element.updateAll();
          filteredJobs.add(element);
          continue;
        }
      }
    }
    setState(() {});
  }

  Container _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: UiVariables.primaryColor.withOpacity(0.8),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              InkWell(
                onTap: () {
                  for (var i = 0; i < widget.jobs.length; i++) {
                    widget.jobs[i]['is_selected'] = false;
                  }
                  _TableSource.selectedIndexes.clear();

                  Navigator.of(context).pop(null);
                },
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: screenSize!.blockWidth >= 920 ? 20 : 15,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "Selecciona los cargos a agregar",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: screenSize!.blockWidth >= 920 ? 18 : 14),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSearchBar() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(top: 30),
        width: screenSize!.width >= 1120
            ? screenSize!.blockWidth * 0.3
            : screenSize!.blockWidth * 0.45,
        height: screenSize!.height * 0.055,
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
          controller: searchController,
          decoration: InputDecoration(
            suffixIcon: const Icon(Icons.search),
            hintText: "Buscar cargo a agregar",
            hintStyle: TextStyle(
              color: Colors.grey,
              fontSize: screenSize!.blockWidth >= 580 ? 14 : 10,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
          ),
          onChanged: ((value) {
            filterJobs(value.toLowerCase());
          }),
        ),
      ),
    );
  }

  Positioned _buildAceptBtn() {
    return Positioned(
      bottom: 20,
      right: 30,
      child: InkWell(
        onTap: () {
          if (_TableSource.selectedIndexes.isEmpty) {
            LocalNotificationService.showSnackBar(
              type: "fail",
              message: "Debes seleccionar al menos un cargo",
              icon: Icons.error_outline,
            );
            return;
          }

          List<Map<String, dynamic>> jobsToAdd = [];

          for (int indexToAdd in _TableSource.selectedIndexes) {
            jobsToAdd.add(widget.jobs[indexToAdd]);
          }
          Navigator.of(context).pop(jobsToAdd);
          for (var i = 0; i < widget.jobs.length; i++) {
            widget.jobs[i]['is_selected'] = false;
          }
          _TableSource.selectedIndexes.clear();
        },
        child: Container(
          width: screenSize!.blockWidth > 920
              ? screenSize!.blockWidth * 0.15
              : 150,
          height: screenSize!.blockWidth > 920
              ? screenSize!.height * 0.05
              : screenSize!.height * 0.03,
          decoration: BoxDecoration(
            color: UiVariables.primaryColor.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              "Aceptar",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: screenSize!.blockWidth >= 920 ? 15 : 12),
            ),
          ),
        ),
      ),
    );
  }
}

class JobsDataTable extends StatefulWidget {
  final ScreenSize screenSize;
  final List<Map<String, dynamic>> jobs;
  final List<Map<String, dynamic>> allJobs;

  const JobsDataTable({
    required this.screenSize,
    required this.jobs,
    required this.allJobs,
    Key? key,
  }) : super(key: key);

  @override
  State<JobsDataTable> createState() => _JobsDataTableState();
}

class _JobsDataTableState extends State<JobsDataTable> {
  List<String> headers = [
    "Acciones",
    "Nombre",
    "Identificador",
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.screenSize.blockWidth,
      height: widget.screenSize.height * 0.6,
      child: SelectionArea(
        child: PaginatedDataTable2(
          empty: const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: Text("No hay información"),
            ),
          ),
          horizontalMargin: 20,
          columnSpacing: 30,
          columns: _getColums(),
          source: _TableSource(
            jobs: widget.jobs,
            allJobs: widget.allJobs,
            onTapItem: (List<int> indexes) {
              _TableSource.selectedIndexes = indexes;
              for (int index in indexes) {
                widget.allJobs[index]['is_selected'] = true;
              }
              setState(() {});
            },
          ),
        ),
      ),
    );
  }

  List<DataColumn2> _getColums() {
    return headers.map(
      (String header) {
        return DataColumn2(
          label:
              Text(header, style: const TextStyle(fontWeight: FontWeight.bold)),
        );
      },
    ).toList();
  }
}

class _TableSource extends DataTableSource {
  final List<Map<String, dynamic>> jobs;
  final List<Map<String, dynamic>> allJobs;

  final Function onTapItem;
  _TableSource({
    required this.jobs,
    required this.onTapItem,
    required this.allJobs,
  });

  static List<int> selectedIndexes = [];

  @override
  DataRow? getRow(int index) =>
      DataRow2.byIndex(cells: getCells(index), index: index);

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => jobs.length;

  @override
  int get selectedRowCount => 0;

  List<DataCell> getCells(int index) {
    Map<String, dynamic> job = jobs[index];
    int generalIndex =
        allJobs.indexWhere((element) => element['value'] == job['value']);

    return <DataCell>[
      DataCell(
        Checkbox(
            value: selectedIndexes.contains(generalIndex) &&
                allJobs[generalIndex]['is_selected'],

            //selectedIndex == index,
            onChanged: (bool? newValue) {
              if (newValue!) {
                selectedIndexes.add(generalIndex);
              } else {
                selectedIndexes
                    .removeWhere((element) => element == generalIndex);
              }
              onTapItem(selectedIndexes);
            }),
      ),
      DataCell(Text(job["name"])),
      DataCell(Text(job["value"])),
    ];
  }
}
