// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:huts_web/features/auth/display/providers/auth_provider.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/clients/display/provider/clients_provider.dart';
import 'package:huts_web/features/employees/display/provider/employees_provider.dart';
import 'package:huts_web/features/general_info/display/providers/general_info_provider.dart';
import 'package:huts_web/features/profile_info/domain/display/providers/profile_provider.dart';
import 'package:provider/provider.dart';

import '../../../../../../../core/services/employee_services/employee_services.dart';
import '../../../../../../../core/services/local_notification_service.dart';
import '../../../../../../../core/utils/code/code_utils.dart';
import '../../../../../../../core/utils/ui/ui_methods.dart';
import '../../../../../../../core/utils/ui/ui_variables.dart';
import '../../../../../../../core/utils/ui/widgets/employees/employee_selection/dialog.dart';
import '../../../../../../../core/utils/ui/widgets/general/data_table_from_responsive.dart';
import '../../../../../../auth/domain/entities/web_user_entity.dart';
import '../../../../../../employees/domain/entities/employee_entity.dart';
import 'widgets/favorite_table.dart';

class FavoritesScreen extends StatelessWidget {
  final ScreenSize screenSize;
  final WebUser user;
  final ClientsProvider clientsProvider;
  const FavoritesScreen(
      {Key? key,
      required this.screenSize,
      required this.user,
      required this.clientsProvider})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    AuthProvider authProvider = Provider.of<AuthProvider>(context);

    // print(authProvider.webUser.company.favoriteEmployees);
    ProfileProvider profileProvider = Provider.of<ProfileProvider>(context);
    GeneralInfoProvider generalInfoProvider =
        Provider.of<GeneralInfoProvider>(context);
    List<List<String>> dataTableFromResponsive = [];

    dataTableFromResponsive.clear();
    if (authProvider.webUser.company.favoriteEmployees.isNotEmpty) {
      dataTableFromResponsive.clear();
      for (var clientFav in authProvider.webUser.company.favoriteEmployees) {
        dataTableFromResponsive.add([
          "Foto-${clientFav.photo}",
          "Nombre-${clientFav.fullname}",
          "Id-${clientFav.uid}",
          "Acciones-",
        ]);
      }
    }
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.03),
          child: generalInfoProvider.screenSize.blockWidth < 800
              ? buildColumnSubtitle(
                  profileProvider, context, generalInfoProvider)
              : buildRowSubtitle(profileProvider, context, generalInfoProvider),
        ),
        SizedBox(height: screenSize.height * 0.03),
        Container(
          padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.02),
          child: Padding(
            padding: EdgeInsets.only(top: screenSize.height * 0.02),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                        'Usuarios totales: ${authProvider.webUser.company.favoriteEmployees.length}')
                  ],
                ),
                SizedBox(height: screenSize.height * 0.018),
                SizedBox(
                  height: screenSize.height * 0.45,
                  width: screenSize.width * 0.90,
                  child: screenSize.blockWidth >= 920
                      ? FavoriteTableWidet(
                          screenSize: screenSize,
                          userClient:
                              authProvider.webUser.company.favoriteEmployees,
                          user: user,
                        )
                      : SingleChildScrollView(
                          child: DataTableFromResponsive(
                            listData: dataTableFromResponsive,
                            screenSize: screenSize,
                            type: 'fav-client',
                          ),
                        ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  buildColumnSubtitle(ProfileProvider profileProvider, BuildContext context,
      GeneralInfoProvider generalInfoProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Usuarios marcados como favoritos',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        buildAddBtn(profileProvider, context),
      ],
    );
  }

  buildAddBtn(ProfileProvider profileProvider, BuildContext context) {
    return InkWell(
      onTap: () async {
        profileProvider.clearControllers();
        UiMethods().showLoadingDialog(context: context);
        List<Employee>? gottenEmployees =
            await EmployeeServices.getClientEmployees(
          user.accountInfo.companyId,
        );

        UiMethods().hideLoadingDialog(context: context);
        if (gottenEmployees!.isEmpty) {
          LocalNotificationService.showSnackBar(
            type: "fail",
            message: "No tiene empleados para marcar como favorito",
            icon: Icons.error_outline,
          );
          return;
        }
        for (var element in user.company.favoriteEmployees) {
          gottenEmployees.removeWhere(
              (elementEmployee) => elementEmployee.id == element.uid);
        }

        for (var element in user.company.blockedEmployees) {
          gottenEmployees.removeWhere(
              (elementEmployee) => elementEmployee.id == element.uid);
        }
        EmployeesProvider employeeProvider = context.read<EmployeesProvider>();
        List<Employee?> selectedEmployees = await EmployeeSelectionDialog.show(
          employees: gottenEmployees,
          indexesList: employeeProvider.locksOrFavsToEditIndexes,
          isAddFavOrLocks: true,
        );

        if (selectedEmployees.isEmpty) return;

        Map<String, dynamic> employees = {};
        for (Employee? employee in selectedEmployees) {
          employees[employee!.id] = {
            "fullname": CodeUtils.getFormatedName(
              employee.profileInfo.names,
              employee.profileInfo.lastNames,
            ),
            "phone": employee.profileInfo.phone,
            "jobs": employee.jobs,
            "photo": employee.profileInfo.image,
            "uid": employee.id,
          };
        }

        UiMethods().showLoadingDialog(context: context);
        await clientsProvider.updateClientInfo(
          {
            "action": "add",
            "employees": employees,
          },
          "favs",
          false,
          user,
          // selectedEmployee as ClientEmployee,
        );
        UiMethods().hideLoadingDialog(context: context);
      },
      child: Container(
        height: screenSize.height * 0.045,
        width: screenSize.blockWidth * 0.1,
        decoration: BoxDecoration(
          color: UiVariables.primaryColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            'AÑADIR',
            style: TextStyle(
              color: Colors.white,
              fontSize: screenSize.blockWidth >= 920 ? 15 : 12,
            ),
          ),
        ),
      ),
    );
  }

  buildRowSubtitle(ProfileProvider profileProvider, BuildContext context,
      GeneralInfoProvider generalInfoProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Usuarios marcados como favoritos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(width: screenSize.width * 0.09),
        buildAddBtn(profileProvider, context),
      ],
    );
  }
}
