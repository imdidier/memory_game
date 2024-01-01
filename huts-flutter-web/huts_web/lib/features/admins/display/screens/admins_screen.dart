import 'package:flutter/material.dart';
import 'package:huts_web/core/utils/ui/ui_variables.dart';
import 'package:huts_web/core/utils/ui/widgets/general/data_table_from_responsive.dart';
import 'package:huts_web/features/admins/display/widgets/create_admin_dialog.dart';
import 'package:huts_web/features/auth/display/providers/auth_provider.dart';
import 'package:huts_web/features/admins/display/providers/admin_provider.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/code/code_utils.dart';
import '../../../auth/domain/entities/screen_size_entity.dart';
import '../../../general_info/display/providers/general_info_provider.dart';

import '../widgets/admins_data_table.dart';

class AdminsScreen extends StatefulWidget {
  const AdminsScreen({Key? key}) : super(key: key);

  @override
  AdminsScreenState createState() => AdminsScreenState();
}

class AdminsScreenState extends State<AdminsScreen> {
  bool isScreenLoaded = false;
  late ScreenSize screenSize;
  late AdminProvider adminProvider;
  late AuthProvider authProvider;
  UiVariables uiVariables = UiVariables();

  @override
  void didChangeDependencies() async {
    if (isScreenLoaded) return;
    isScreenLoaded = true;
    adminProvider = Provider.of<AdminProvider>(context);
    authProvider = Provider.of<AuthProvider>(context, listen: false);
    await adminProvider.eitherFailOrGetAdmins(authProvider.webUser.uid);
    super.didChangeDependencies();
  }

  List<List<String>> dataTableFromResponsive = [];

  @override
  Widget build(BuildContext context) {
    screenSize = Provider.of<GeneralInfoProvider>(context).screenSize;
    return SizedBox(
      height: screenSize.height,
      width: screenSize.width,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitle(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 35),
                    child: Text(
                      "Total admins: ${adminProvider.filteredAdmins.length}",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  buildSearchBar(),
                ],
              ),
              _buildAdmins()
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
        height: screenSize.blockWidth >= 920 ? screenSize.height * 0.055 : 30,
        width: screenSize.blockWidth >= 920
            ? screenSize.blockWidth * 0.3
            : screenSize.blockWidth * 0.35,
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
          controller: adminProvider.searchController,
          decoration: InputDecoration(
            suffixIcon: Icon(
              Icons.search,
              size: screenSize.blockWidth >= 920 ? 16 : 12,
            ),
            hintText: "Buscar Admin",
            hintStyle: TextStyle(
              color: Colors.grey,
              fontSize: screenSize.blockWidth >= 920 ? 14 : 10,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: screenSize.blockWidth >= 920 ? 12 : 4),
          ),
          onChanged: adminProvider.filterAdmins,
        ),
      ),
    );
  }

  Row _buildTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Administradores",
              style: TextStyle(
                color: Colors.black,
                fontSize: screenSize.width * 0.016,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              "Lista de administradores registrados en Huts.",
              style: TextStyle(
                color: Colors.black54,
                fontSize: screenSize.width * 0.01,
              ),
            ),
          ],
        ),
        Row(
          children: [
            InkWell(
              onTap: () async => await CreateAdminDialog.show(),
              child: Container(
                width: screenSize.blockWidth >= 920
                    ? screenSize.blockWidth * 0.1
                    : 100,
                height: screenSize.height * 0.045,
                decoration: BoxDecoration(
                  color: UiVariables.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    "Agregar Admin",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenSize.blockWidth >= 920 ? 15 : 11,
                    ),
                  ),
                ),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildAdmins() {
    if (adminProvider.allAdmins.isEmpty) return const SizedBox();
    dataTableFromResponsive.clear();

    if (adminProvider.filteredAdmins.isNotEmpty) {
      dataTableFromResponsive.clear();

      for (var admin in adminProvider.filteredAdmins) {
        dataTableFromResponsive.add([
          "Nombres-${admin.profileInfo.names}",
          "Apellidos-${admin.profileInfo.lastNames}",
          "Correo-${admin.profileInfo.email}",
          "Teléfono-${admin.profileInfo.phone}",
          "Tipo-${CodeUtils.getWebUserSubtypeName(admin.accountInfo.subtype)}",
          "Estado-${admin.accountInfo.enabled}",
          "Id-${admin.uid}",
          "Acciones-",
        ]);
      }
    }
    return Container(
      margin: const EdgeInsets.only(top: 30),
      child: screenSize.blockWidth >= 920
          ? AdminsDataTable(screenSize: screenSize)
          : DataTableFromResponsive(
              listData: dataTableFromResponsive,
              screenSize: screenSize,
              type: 'admin',
            ),
    );
  }
}
