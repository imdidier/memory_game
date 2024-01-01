import 'package:flutter/material.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/clients/display/provider/clients_provider.dart';
import 'package:huts_web/features/general_info/display/providers/general_info_provider.dart';
import 'package:provider/provider.dart';

import '../../../../../core/utils/ui/ui_variables.dart';
import '../../../../../core/utils/ui/widgets/general/data_table_from_responsive.dart';
import '../../provider/user_provider.dart';
import 'users_data_table.dart';

class ClientUsers extends StatefulWidget {
  final ClientsProvider clientsProvider;
  const ClientUsers({Key? key, required this.clientsProvider})
      : super(key: key);

  @override
  State<ClientUsers> createState() => _ClientUsersState();
}

class _ClientUsersState extends State<ClientUsers> {
  late UsersProvider webUserProvider;

  List<List<String>> dataTableFromResponsive = [];
  late ScreenSize screenSize;

  @override
  void didChangeDependencies() {
    webUserProvider = Provider.of<UsersProvider>(context);

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    screenSize = Provider.of<GeneralInfoProvider>(context).screenSize;
    dataTableFromResponsive.clear();

    if (widget.clientsProvider.filteredWebUsers.isNotEmpty) {
      dataTableFromResponsive.clear();

      for (var webUser in widget.clientsProvider.filteredWebUsers) {
        dataTableFromResponsive.add([
          'Foto-${webUser['image']}',
          'Nombre-${webUser['full_name']}',
          'Teléfono-${webUser['phone']}',
          'Tipo-${webUser['type']}',
          'SubTipo-${webUser['subtype']}',
          'Estado-${webUser['enable']}',
          'Correo-${webUser['email']}',
          'Acciones-'
        ]);
      }
    }

    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OverflowBar(
            alignment: MainAxisAlignment.spaceBetween,
            overflowSpacing: 10,
            overflowAlignment: OverflowBarAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Usuarios",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: screenSize.width * 0.016,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "Información de usuarios del cliente",
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: screenSize.width * 0.01,
                    ),
                  ),
                ],
              ),
              buildAddBtn()
            ],
          ),
          const SizedBox(
            height: 30,
          ),
          screenSize.blockWidth >= 920
              ? _buildUsers()
              : DataTableFromResponsive(
                  listData: dataTableFromResponsive,
                  screenSize: screenSize,
                  type: 'admin-web-users-client',
                ),
        ],
      ),
    );
  }

  Widget _buildUsers() => ClientUsersDataTable(screenSize: screenSize);

  InkWell buildAddBtn() {
    return InkWell(
      onTap: () {
        webUserProvider.showCreateWebUserDialog(context, screenSize);
      },
      child: Container(
        height: screenSize.height * 0.045,
        width: screenSize.blockWidth > 1194
            ? screenSize.blockWidth * 0.2
            : screenSize.blockWidth * 0.35,
        decoration: BoxDecoration(
          color: UiVariables.primaryColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            "Crear usuario",
            style: TextStyle(
              color: Colors.white,
              fontSize: screenSize.blockWidth >= 920 ? 15 : 12,
            ),
          ),
        ),
      ),
    );
  }
}
