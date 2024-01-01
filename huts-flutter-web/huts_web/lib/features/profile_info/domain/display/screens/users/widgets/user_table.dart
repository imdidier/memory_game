import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/general_info/display/providers/general_info_provider.dart';
import 'package:huts_web/features/profile_info/domain/display/providers/profile_provider.dart';
import 'package:huts_web/features/statistics/domain/entities/employee_fav.dart';
import 'package:provider/provider.dart';
import '../../../../../../../core/services/navigation_service.dart';
import '../../../../../../../core/utils/ui/ui_methods.dart';
import '../../../../../../../core/utils/ui/ui_variables.dart';
import '../../../../../../../core/utils/ui/widgets/general/custom_tooltip.dart';
import '../../../../../../auth/domain/entities/web_user_entity.dart';
import '../../../../../../clients/display/provider/clients_provider.dart';

class UserTableWidget extends StatefulWidget {
  final WebUser user;
  final List<ClientEmployee> userClient;

  final ScreenSize screenSize;
  final ProfileProvider profileProvider;
  final GeneralInfoProvider generalInfoProvider;

  const UserTableWidget(
      {Key? key,
      required this.userClient,
      required this.screenSize,
      required this.profileProvider,
      required this.generalInfoProvider,
      required this.user})
      : super(key: key);

  @override
  State<UserTableWidget> createState() => _UserTableWidgetState();
}

class _UserTableWidgetState extends State<UserTableWidget> {
  List<String> headers = [
    "Foto",
    "Nombre",
    "Id",
    "Acciones",
  ];

  @override
  Widget build(BuildContext context) {
    ClientsProvider provider = Provider.of<ClientsProvider>(context);
    return SizedBox(
      height: widget.screenSize.height * 0.6,
      width: widget.screenSize.blockWidth,
      child: SelectionArea(
        child: PaginatedDataTable2(
          empty: const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: Text("No hay información"),
            ),
          ),
          horizontalMargin: 20,
          columnSpacing: 30,
          columns: _getColums(),
          source: _FavsTableSource(
              user: widget.user,
              userClient: widget.userClient,
              provider: provider,
              profileProvider: widget.profileProvider,
              generalInfoProvider: widget.generalInfoProvider),
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

class _FavsTableSource extends DataTableSource {
  final List<ClientEmployee> userClient;
  final ClientsProvider provider;
  final WebUser user;
  final ProfileProvider profileProvider;
  final GeneralInfoProvider generalInfoProvider;

  _FavsTableSource({
    required this.user,
    required this.provider,
    required this.userClient,
    required this.generalInfoProvider,
    required this.profileProvider,
  });
  @override
  DataRow? getRow(int index) =>
      DataRow2.byIndex(cells: getCells(index), index: index);

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => userClient.length;

  @override
  int get selectedRowCount => 0;

  List<DataCell> getCells(int index) {
    List<ClientEmployee> webUser = userClient;

    return <DataCell>[
      DataCell(
        CircleAvatar(
          backgroundImage: NetworkImage(webUser[index].photo),
        ),
      ),
      DataCell(Text(webUser[index].fullname)),
      DataCell(Text(webUser[index].uid)),
      DataCell(
        Row(
          children: [
            CustomTooltip(
              message: "Eliminar usuario",
              child: InkWell(
                child: const Icon(
                  Icons.delete,
                  color: Colors.redAccent,
                ),
                onTap: () async {
                  BuildContext? context = NavigationService.getGlobalContext();
                  if (context == null) return;
                  bool itsConfirmed = await confirm(
                    context,
                    title: Text(
                      "Eliminar usuario",
                      style: TextStyle(
                        color: UiVariables.primaryColor,
                      ),
                    ),
                    content: RichText(
                      text: TextSpan(
                        text: '¿Quieres eliminar a ',
                        children: <TextSpan>[
                          TextSpan(
                            text: '${webUser[index].fullname}?',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
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
                  await provider.updateClientInfo(
                    {
                      "action": "delete",
                      "employee": {"uid": webUser[index].uid},
                    },
                    "locks",
                    false,
                    user,
                  );
                  await profileProvider.deleteUser(context, webUser[index].uid);
                  UiMethods().hideLoadingDialog(context: context);
                },
              ),
            ),
          ],
          //  InkWell(
          //     child: const Icon(
          //       Icons.delete,
          //       color: Colors.red,
          //       size: 20,
          //     ),
          //     onTap: () async {
          //       BuildContext? context = NavigationService.getGlobalContext();
          //       if (context == null) return;
          //       UiMethods().showLoadingDialog(context: context);
          //       await provider.updateClientInfo(
          //         {
          //           "action": "delete",
          //           "employee": {"uid": lock[index].uid},
          //         },
          //         "locks",
          //         false,
          //         user,
          //       );
          //       UiMethods().hideLoadingDialog(context: context);
          //     }),
        ),
      ),
    ];
  }
}
