import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:huts_web/core/errors/exceptions.dart';
import 'package:huts_web/core/firebase_config/firebase_services.dart';
import 'package:huts_web/features/auth/data/models/company_model.dart';
import 'package:huts_web/features/auth/domain/entities/company.dart';
import 'package:huts_web/features/profile_info/domain/display/providers/profile_provider.dart';
import 'package:huts_web/features/statistics/domain/entities/employee_fav.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/activity_service.dart';
import '../../../../core/services/navigation_service.dart';
import '../../../../core/use_cases_params/activity_params.dart';
import '../../../../core/utils/code/code_utils.dart';
import '../../../auth/data/models/web_user_model.dart';
import '../../../auth/display/providers/auth_provider.dart';
import '../../../auth/domain/entities/web_user_entity.dart';
import '../../../statistics/data/models/employee_fav_model.dart';

abstract class RemoteProfileDatasurces {
  Future<List<WebUserModel>?> getClientUsers(
      BuildContext context, String companyId);
  Future<void> editUserInfo(Map<String, dynamic> infoToUpdate);
  Future<bool> editClientAddress(
      Map<String, dynamic> addressToUpdate, String clientId);
  Future<bool> updateInfo(
      String idToUpdate,
      Map<String, dynamic> adminInfoToUpdate,
      Map<String, dynamic> updatedSubtype);

  Future<void> deleteUser(BuildContext context, String keyUserDelete);
  Future<bool> addNewUser(BuildContext context, String idClient);
  Future<void> disableUser(String userId, bool isEnabled);
}

class RemoteProfileDatasurcesImpl implements RemoteProfileDatasurces {
  @override
  Future<List<WebUserModel>?> getClientUsers(
      BuildContext context, String companyId) async {
    try {
      List<WebUserModel> usersList = [];
      await FirebaseServices.db
          .collection('web_users')
          .where('account_info.company_id', isEqualTo: companyId)
          .get()
          .then((queryUsers) async {
        for (var userDoc in queryUsers.docs) {
          Map<String, dynamic> clientData = userDoc.data();
          if (clientData['id'] == userDoc.id) continue;
          clientData['id'] = userDoc.id;
          Map<String, dynamic> companyInfo = {};
          if (clientData['account_info']['type'] == 'client') {
            DocumentSnapshot companydocs = await FirebaseServices.db
                .collection('clients')
                .doc(clientData['account_info']['company_id'])
                .get();
            companyInfo = companydocs.data() as Map<String, dynamic>;
            companyInfo['id'] = companydocs.id;
          }
          clientData['company_info'] = companyInfo;
          WebUserModel users = WebUserModel.fromMap(clientData);
          usersList.add(users);
        }
      });
      return usersList;
    } catch (e) {
      if (kDebugMode) {
        print(
            'remoteProfileDatasources, getClientUsers error: ${e.toString()}');
        throw ServerException('$e');
      }
    }
    return null;
  }

  @override
  Future<void> editUserInfo(Map<String, dynamic> infoToUpdate) async {
    try {
      await FirebaseServices.db
          .collection('web_users')
          .doc(FirebaseServices.auth.currentUser!.uid)
          .update(infoToUpdate);
      BuildContext? context = NavigationService.getGlobalContext();
      if (context == null) return;
      WebUser webUser =
          Provider.of<AuthProvider>(context, listen: false).webUser;

      ActivityParams params = ActivityParams(
        description:
            'Se modificó la información general de un usuario del cliente ${webUser.company.name}',
        category: {
          "key": "client",
          "name": "Clientes",
        },
        personInCharge: {
          "name": CodeUtils.getFormatedName(
              webUser.profileInfo.names, webUser.profileInfo.lastNames),
          "type_key": webUser.accountInfo.type,
          "type_name": CodeUtils.getWebUserTypeName(webUser.accountInfo.type),
          "id": webUser.uid,
          "company_id": webUser.accountInfo.companyId
        },
        affectedUser: {"id": "", "name": "", "type_key": "", "type_name": ""},
        date: DateTime.now(),
      );

      await ActivityService.saveChange(params);
    } catch (e) {
      if (kDebugMode) {
        print('RemoteProfileDatasource, editUserInfo Error: $e');
        throw ServerException('$e');
      }
    }
  }

  @override
  Future<bool> editClientAddress(
      Map<String, dynamic> addressToUpdate, String clientId) async {
    try {
      await FirebaseServices.db
          .collection('clients')
          .doc(clientId)
          .update(addressToUpdate);
      BuildContext? context = NavigationService.getGlobalContext();
      if (context == null) return false;
      WebUser webUser =
          Provider.of<AuthProvider>(context, listen: false).webUser;

      ActivityParams params = ActivityParams(
        description:
            'Se modifcó la ubicación del cliente ${webUser.company.name}',
        category: {
          "key": "client",
          "name": "Clientes",
        },
        personInCharge: {
          "name": CodeUtils.getFormatedName(
              webUser.profileInfo.names, webUser.profileInfo.lastNames),
          "type_key": webUser.accountInfo.type,
          "type_name": CodeUtils.getWebUserTypeName(webUser.accountInfo.type),
          "id": webUser.uid,
          "company_id": webUser.accountInfo.companyId
        },
        affectedUser: {"id": "", "name": "", "type_key": "", "type_name": ""},
        date: DateTime.now(),
      );

      await ActivityService.saveChange(params);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('RemoteProfileDatasource, editClientAddress Error: $e');
      }
      return false;
    }
  }

  @override
  Future<bool> updateInfo(
      String idToUpdate,
      Map<String, dynamic> adminInfoToUpdate,
      Map<String, dynamic> updatedSubtype) async {
    try {
      await FirebaseServices.db.collection('web_users').doc(idToUpdate).update({
        'profile_info.names': adminInfoToUpdate['names'],
        'profile_info.last_names': adminInfoToUpdate['last_names'],
        'profile_info.email': adminInfoToUpdate['email'],
        'account_info.subtype': updatedSubtype['subtype']
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('RemoteProfileDatasource, updateInfo Error: $e');
      }
      return false;
    }
  }

  @override
  Future<void> deleteUser(BuildContext context, String keyUserDelete) async {
    var queryUsers = FirebaseServices.db
        .collection('web_users')
        .where('id', isEqualTo: keyUserDelete);
    queryUsers.get().then((value) {
      for (var element in value.docs) {
        log(keyUserDelete);
        element.reference.delete();
      }
    });
    throw UnimplementedError();
  }

  @override
  Future<bool> addNewUser(BuildContext context, String idClient) async {
    try {
      ProfileProvider profileProvider =
          Provider.of<ProfileProvider>(context, listen: false);

      ProfileInfoModel profileInfoToAdd = ProfileInfoModel(
          countryPrefix: profileProvider.usercountryPrefix!,
          email: profileProvider.adminEmailEditController.text,
          image:
              profileProvider.userImage == '' ? '' : profileProvider.userImage,
          lastNames: profileProvider.lastNamesEditController.text,
          names: profileProvider.namesEditController.text,
          phone: profileProvider.phoneEdtiController.text);
      AccountInfoModel accountInfoToAdd = AccountInfoModel(
        companyId: idClient,
        creationDate: DateTime.now(),
        enabled: true,
        subtype: profileProvider.newUserSubtype,
        type: 'client',
      );
      Map<String, dynamic> companyInfo = {};
      DocumentSnapshot snapshot =
          await FirebaseServices.db.collection('clients').doc(idClient).get();
      companyInfo = snapshot.data() as Map<String, dynamic>;
      companyInfo['id'] = snapshot.id;
      List<ClientEmployee> finalEmployeeFavs = [];
      List<ClientEmployee> finalBlockedEmployees = [];
      List<Map<String, dynamic>> finalWebUsers = [];

      if (companyInfo['favorites'] != null) {
        companyInfo['favorites'].forEach((key, value) {
          ClientEmployee newFav = ClientEmployeeModel.fromMap(value);
          finalEmployeeFavs.add(newFav);
        });
      }

      if (companyInfo['web_users'] != null) {
        companyInfo['web_users'].forEach((key, value) {
          Map<String, dynamic> newWebUser = value;
          finalWebUsers.add(newWebUser);
        });
      }

      if (companyInfo['blocked_employees'] != null) {
        companyInfo['blocked_employees'].forEach((key, value) {
          ClientEmployee newBlocked = ClientEmployeeModel.fromMap(value);
          finalBlockedEmployees.add(newBlocked);
        });
      }

      CompanyModel finalCompanyInfo = CompanyModel(
        id: companyInfo['id'],
        accountInfo: companyInfo['account_info'],
        legalInfo: companyInfo['legal_info'],
        country: companyInfo['country'],
        image: companyInfo['image'],
        description: companyInfo['description'],
        name: companyInfo['name'],
        favoriteEmployees: finalEmployeeFavs,
        blockedEmployees: finalBlockedEmployees,
        location: companyInfo['location'],
        jobs: List<Job>.from([]),
        webUserEmployees: finalWebUsers, // This list must be filled
      );

      String newWebUserId =
          FirebaseServices.db.collection('web_users').doc().id;

      Map<String, dynamic> userToAdd = WebUserModel(
        accountInfoToAdd,
        profileInfoToAdd,
        newWebUserId,
        finalCompanyInfo,
        Map<String, dynamic>.from({}),
      ).toMap();

      FirebaseServices.db
          .collection('web_users')
          .doc(newWebUserId)
          .set(userToAdd);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('RemoteProfileDatasource, addNewUser Error: $e');
        throw ServerException(e.toString());
      }
      return false;
    }
  }

  @override
  Future<void> disableUser(String userId, bool isEnabled) async {
    try {
      await FirebaseServices.db
          .collection('web_users')
          .doc(userId)
          .update({'account_info.enabled': isEnabled});
    } catch (e) {
      if (kDebugMode) {
        print('RemoteProfileDatasource, disableUser Error: $e');
        throw ServerException(e.toString());
      }
    }
    throw UnimplementedError();
  }
}
