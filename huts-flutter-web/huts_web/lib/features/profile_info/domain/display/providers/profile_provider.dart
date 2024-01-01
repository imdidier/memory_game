import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/errors/failures.dart';
import 'package:huts_web/core/services/local_notification_service.dart';
import 'package:huts_web/core/utils/ui/ui_methods.dart';
import 'package:huts_web/features/auth/display/providers/auth_provider.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/profile_info/data/datasources/local_data_sources.dart';
import 'package:huts_web/features/profile_info/data/datasources/remote_profile_data_sources.dart';
import 'package:huts_web/features/profile_info/data/repositories/profile_repository_impl.dart';
import 'package:huts_web/features/profile_info/domain/use_cases/add_new_user.dart';
import 'package:huts_web/features/profile_info/domain/use_cases/delete_user.dart';
import 'package:huts_web/features/profile_info/domain/use_cases/disable_user.dart';
import 'package:huts_web/features/profile_info/domain/use_cases/get_client_users.dart';
import 'package:huts_web/features/profile_info/domain/use_cases/get_states.dart';
import 'package:huts_web/features/profile_info/domain/use_cases/update_client_address.dart';
import 'package:provider/provider.dart';

import '../../../../../core/services/client_services/client_services.dart';
import '../../../../../core/services/navigation_service.dart';
import '../../../../../core/utils/code/code_utils.dart';
import '../../../../auth/domain/entities/web_user_entity.dart';
import '../../entities/state_country.dart';
import '../../use_cases/edit_user_info.dart';
import '../../use_cases/update_info_by_admin.dart';

class ProfileProvider with ChangeNotifier {
  List<String> citiesName = [];
  List<String> statesName = [];
  List<WebUser> userList = [];
  String? clientState;
  String? clientCity;
  String? userSubType;
  String? usercountryPrefix;
  String newCity = '';
  String newState = '';
  String userImage = '';
  String newUserSubtype = '';
  bool isEditing = false;
  bool isUserDisable = false;
  bool isMobilView = false;
  List<StateCountry> statesCountry = [];
  List<String> countryPrefix = ['CR', 'COL'];
  Map<String, dynamic> infoToUpdate = {};
  Map<String, dynamic> infoAdminToUpdate = {};
  Map<String, dynamic> updatedSubtype = {};
  Map<String, dynamic> addressToUpdate = {};
  Map<String, dynamic> userToAdd = {};

  TextEditingController phoneEdtiController = TextEditingController();
  TextEditingController emailEditController = TextEditingController();
  TextEditingController passEditController = TextEditingController();
  TextEditingController namesEditController = TextEditingController();
  TextEditingController lastNamesEditController = TextEditingController();
  TextEditingController rollEditController = TextEditingController();
  TextEditingController adminEmailEditController = TextEditingController();

  Map<String, dynamic> selectedProfileTab = {
    'name': 'Información',
    'value': 0,
    'isSelectedTab': true,
  };
  List<Map<String, dynamic>> profileTabs = [
    {
      'name': 'Información',
      'value': 0,
      'isSelectedTab': true,
    },
    {
      'name': 'Dirección',
      'value': 1,
      'isSelectedTab': false,
    },
    {
      'name': 'Usuarios',
      'value': 2,
      'isSelectedTab': false,
    },
    {
      'name': 'Favoritos',
      'value': 3,
      'isSelectedTab': false,
    },
    {
      'name': 'Bloqueados',
      'value': 4,
      'isSelectedTab': false,
    },
    {
      'name': 'Actividad',
      'value': 5,
      'isSelectedTab': false,
    }
  ];
  selectProfileTab({required newTabSelected}) {
    int lastTabSelected =
        profileTabs.indexWhere((element) => element['isSelectedTab']);
    if (lastTabSelected == newTabSelected) return;

    if (lastTabSelected != -1) {
      profileTabs[lastTabSelected]['isSelectedTab'] = false;
    }
    profileTabs[newTabSelected]['isSelectedTab'] = true;
    selectedProfileTab = profileTabs[newTabSelected];

    notifyListeners();
  }

  // addwebUserSubtypes(Map<String, dynamic> subtypes){
  //   subtypes.entries.toList()
  // }

  DropdownButton<Object> dropdownButton({
    required BuildContext context,
    required String? updateValue,
    required List<String> items,
    required String hintText,
    required Function onChange,
    required ScreenSize size,
  }) {
    return DropdownButton(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        underline: const SizedBox(),
        hint: Text(hintText),
        value: updateValue,
        isExpanded: true,
        menuMaxHeight: size.absoluteHeight * 0.2,
        items: items.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem(value: value, child: Text(value));
        }).toList(),
        onChanged: (selectedValue) {
          onChange(selectedValue);
          notifyListeners();
        });
  }

  Future<void> eitherFailOrCountries(BuildContext context, WebUser user) async {
    ProfileRepositoryImpl repositoryImpl = ProfileRepositoryImpl(
        profileLocalDataSources: ProfileLocalDataSourcesImpl());
    final failOrCountries = await GetCountries(repositoryImpl)
        .call(context, user.profileInfo.countryPrefix);
    failOrCountries.fold((Failure failure) async {
      LocalNotificationService.showSnackBar(
          type: 'error',
          message: failure.errorMessage!,
          icon: Icons.error_outline);
    }, (states) {
      statesCountry = [...states!];
      statesName.clear();
      for (var state in statesCountry) {
        statesName.add(state.name);
      }
    });
  }

  getCitiesStates() {
    try {
      int index =
          statesCountry.indexWhere((state) => state.name == clientState);
      citiesName.clear();
      for (var city in statesCountry[index].cities) {
        citiesName.add(city.toString());
      }
    } catch (e) {
      log('Error profileProvider, getCities $e');
    }
    notifyListeners();
  }

  Future<void> eitherOrFailClientUsers(
      BuildContext context, String companyId) async {
    try {
      ProfileRepositoryImpl repositoryImpl = ProfileRepositoryImpl(
          remoteProfileDatasurces: RemoteProfileDatasurcesImpl());
      final usersOrfail =
          await GetClientUsers(repositoryImpl).call(context, companyId);
      usersOrfail.fold((Failure failure) async {
        LocalNotificationService.showSnackBar(
            type: 'error',
            message: failure.errorMessage!,
            icon: Icons.error_outline);
      }, (users) {
        userList = [...users!];

        userList.removeWhere(
          (element) =>
              element.uid ==
              Provider.of<AuthProvider>(context, listen: false).webUser.uid,
        );
        // userList.clear();
        notifyListeners();
      });
    } catch (e) {
      if (kDebugMode) {
        print('ProfileProvider FailOrUsers error: $e');
      }
    }
  }

  Future<void> editUserInfo(WebUser user) async {
    try {
      infoToUpdate['profile_info'] = {
        'country_prefix': user.profileInfo.countryPrefix,
        'image': user.profileInfo.image,
        'names': user.profileInfo.names,
        'last_names': user.profileInfo.lastNames,
        'email': emailEditController.text,
        'phone': phoneEdtiController.text
      };
      ProfileRepositoryImpl repositoryImpl = ProfileRepositoryImpl(
          remoteProfileDatasurces: RemoteProfileDatasurcesImpl());
      await EditUserInfo(repositoryImpl).call(infoToUpdate);
      if (kDebugMode) {
        print(infoToUpdate);
      }
      LocalNotificationService.showSnackBar(
          type: 'success',
          message: 'Se han realizado los cambios',
          icon: Icons.check);
      // emailEditController.clear();
      // phoneEdtiController.clear();
    } catch (e) {
      if (kDebugMode) {
        print('ProfileProvider editUserInfo, Error $e');
      }
    }
    notifyListeners();
  }

  Future<bool> validateInformationFields(
      WebUser user, Map<String, dynamic> updateData) async {
    BuildContext? globalContext = NavigationService.getGlobalContext();

    if (globalContext == null) return false;
    if (emailEditController.text.isEmpty) {
      LocalNotificationService.showSnackBar(
          type: 'error',
          message: 'Debes ingresar una dirección de correo',
          icon: Icons.error_outline);
      return false;
    }
    if (!CodeUtils.checkValidEmail(emailEditController.text.trim())) {
      LocalNotificationService.showSnackBar(
        type: "error",
        message: "Debes ingresar un correo válido",
        icon: Icons.error_outline,
      );
      return false;
    }
    if (phoneEdtiController.text.isEmpty) {
      LocalNotificationService.showSnackBar(
          type: 'error',
          message: 'Debes ingresar un número de telefono',
          icon: Icons.error_outline);
      return false;
    }
    user.profileInfo.phone = updateData["phone"];
    user.profileInfo.email = updateData["email"];
    UiMethods().showLoadingDialog(context: globalContext);
    if (passEditController.text.isNotEmpty ||
        emailEditController.text.isNotEmpty) {
      if (passEditController.text.length < 6 &&
          passEditController.text.isNotEmpty) {
        LocalNotificationService.showSnackBar(
          type: 'error',
          message: 'La contraseña debe tener mínimo 6 carácteres',
          icon: Icons.error_outline,
        );
        return false;
      }
      bool itsOk = await ClientServices.updateClientUser(
        updateData: updateData,
      );
      if (!itsOk) {
        LocalNotificationService.showSnackBar(
          type: "fail",
          message: "Ocurrió un error al actualizar la información",
          icon: Icons.error_outline,
        );
        UiMethods().hideLoadingDialog(context: globalContext);
        return false;
      }
      LocalNotificationService.showSnackBar(
        type: "success",
        message: "Usuario actualizado correctamente",
        icon: Icons.check,
      );
      // user.isClicked = false;
      // UiMethods().hideLoadingDialog(context: globalContext);
      // Navigator.pop(globalContext);
    }
    user.isClicked = false;
    await editUserInfo(user);

    UiMethods().hideLoadingDialog(context: globalContext);
    Navigator.pop(globalContext);

    return true;
  }

  Future<bool> updateClientAddress(WebUser user, String idClient,
      String newAddress, GeoPoint newPosition) async {
    try {
      BuildContext? globalContext = NavigationService.getGlobalContext();

      if (globalContext == null) return false;
      UiMethods().showLoadingDialog(context: globalContext);

      addressToUpdate['location'] = {
        'state': newState,
        'city': newCity,
        'address': newAddress,
        'position': newPosition
      };
      if (addressToUpdate.isNotEmpty) {
        ProfileRepositoryImpl repositoryImpl = ProfileRepositoryImpl(
            remoteProfileDatasurces: RemoteProfileDatasurcesImpl());
        final boolOrfail = await UpdateClientAddress(repositoryImpl)
            .call(addressToUpdate, idClient);

        boolOrfail!.fold(
          (Failure failure) {
            LocalNotificationService.showSnackBar(
              type: 'fail',
              message: 'Error al intentar actualizar la dirección',
              icon: Icons.error_outline,
            );
            return false;
          },
          (bool itsOk) {
            user.isClicked = false;
            UiMethods().hideLoadingDialog(context: globalContext);
            Navigator.pop(globalContext);
            LocalNotificationService.showSnackBar(
              type: 'success',
              message: 'Se ha modificado la dirección con éxito',
              icon: Icons.check,
            );
          },
        );
        if (kDebugMode) {
          print(addressToUpdate);
          print(idClient);
        }
      }
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('ProfileProvider UpdateClientAddress, Error: $e');
      }
      return false;
    }
  }

  Future<void> eitherFailOrupdateInfoUserByClient(String idToUpdate) async {
    try {
      infoAdminToUpdate = {
        'names': namesEditController.text,
        'last_names': lastNamesEditController.text,
        'email': adminEmailEditController.text,
      };
      updatedSubtype = {'subtype': newUserSubtype};
      ProfileRepositoryImpl repositoryImpl = ProfileRepositoryImpl(
          remoteProfileDatasurces: RemoteProfileDatasurcesImpl());
      final failOrUpdate = await UpdateInfoByAdmin(repositoryImpl)
          .call(idToUpdate, infoAdminToUpdate, updatedSubtype);
      failOrUpdate!.fold((Failure failure) async {
        LocalNotificationService.showSnackBar(
            type: 'error',
            message: failure.errorMessage!,
            icon: Icons.error_outline);
      }, (update) async {
        update = true;
        LocalNotificationService.showSnackBar(
            type: 'success',
            message: 'Datos modificados con éxito',
            icon: Icons.check);
      });
    } catch (e) {
      LocalNotificationService.showSnackBar(
          type: 'fail',
          message: 'Error al intentar actualizar la información',
          icon: Icons.error_outline);
      if (kDebugMode) {
        print('ProfileProvider eitherFailOrupdateInfoUserByClient, Error: $e');
      }
    }
    notifyListeners();
  }

  Future<void> deleteUser(BuildContext context, String keyUserDelete) async {
    try {
      ProfileRepositoryImpl repositoryImpl = ProfileRepositoryImpl(
          remoteProfileDatasurces: RemoteProfileDatasurcesImpl());
      DeleteUser(repositoryImpl).call(context, keyUserDelete);
      LocalNotificationService.showSnackBar(
          type: 'success',
          message: 'Se ha eliminado el usuario',
          icon: Icons.error_outline);
      log('se ha eliminado el usuario $keyUserDelete');
    } catch (e) {
      LocalNotificationService.showSnackBar(
          type: 'fail',
          message: 'Error al intentar eliminar el usuario',
          icon: Icons.error_outline);
      if (kDebugMode) {
        print('ProfileProvider deleteUser, Error: $e');
      }
    }
    notifyListeners();
  }

  Future<void> eitherFailOrAddNewUser(
      BuildContext context, String clientId) async {
    try {
      ProfileRepositoryImpl repositoryImpl = ProfileRepositoryImpl(
          remoteProfileDatasurces: RemoteProfileDatasurcesImpl());
      final failOrAdd =
          await AddNewUser(repositoryImpl).call(context, clientId);
      failOrAdd!.fold((Failure failure) {
        LocalNotificationService.showSnackBar(
            type: 'error',
            message: failure.errorMessage!,
            icon: Icons.error_outline);
      }, (succes) {
        LocalNotificationService.showSnackBar(
            type: 'success',
            message: 'Usuario agregado con exito',
            icon: Icons.check);
      });
    } catch (e) {
      log('ProfileProvider, FailOrAddNewUser Error: $e');
    }
  }

  Future<void> disbleUser(WebUser user) async {
    try {
      bool isEnabled = !isUserDisable;
      ProfileRepositoryImpl repositoryImpl = ProfileRepositoryImpl(
          remoteProfileDatasurces: RemoteProfileDatasurcesImpl());
      await DisableUser(repositoryImpl).call(user.uid, isEnabled);

      LocalNotificationService.showSnackBar(
          type: 'success',
          message: (isEnabled == false)
              ? 'Usuario bloquedo con éxito'
              : 'Usuario desbloquedo con éxito',
          icon: Icons.check);
    } catch (e) {
      LocalNotificationService.showSnackBar(
          type: 'fail',
          message: 'Fallo al intentar bloquear al usuario',
          icon: Icons.error_outline);
    }
    notifyListeners();
  }

  clearControllers() {
    namesEditController.clear();
    lastNamesEditController.clear();
    adminEmailEditController.clear();
    phoneEdtiController.clear();
    notifyListeners();
  }

  validateMobilView(double screenSize) {
    if (screenSize < 800) {
      isMobilView = true;
    }
    notifyListeners();
  }
}
