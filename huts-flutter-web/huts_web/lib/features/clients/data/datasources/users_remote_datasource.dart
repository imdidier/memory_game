import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:huts_web/core/errors/exceptions.dart';
import 'package:huts_web/core/firebase_config/firebase_services.dart';

import '../../../auth/data/models/web_user_model.dart';

abstract class UsersRemoteDatasource {
  Future<List<WebUserModel>> getUsers();
  Future<bool> deleteUser({required String userId});
  // Future<String> createUser({required Map<String, dynamic> user});
  Future<bool> updateUserInfo(
      {required String userId, required Map<String, dynamic> updateInfo});
  Future<bool> updateEnable(
      {required String webUserId, required Map<String, dynamic> updateInfo});
}

class UsersRemoteDatasourceImpl implements UsersRemoteDatasource {
  @override
  Future<List<WebUserModel>> getUsers() async {
    try {
      List<WebUserModel> webUsers = [];

      QuerySnapshot querySnapshot = await FirebaseServices.db
          .collection("web_users")
          .where('account_info.type', isEqualTo: 'client')
          .where('account_info.subtype', isEqualTo: 'admin')
          .get();

      for (DocumentSnapshot doc in querySnapshot.docs) {
        webUsers.add(
          WebUserModel.fromMap(doc.data() as Map<String, dynamic>),
        );
      }
      return webUsers;
    } catch (e) {
      throw ServerException("$e");
    }
  }

  @override
  Future<bool> deleteUser({
    required String userId,
  }) async {
    try {
      await FirebaseServices.db.collection("web_user").doc(userId).delete();
      return true;
    } catch (e) {
      throw ServerException("$e");
    }
  }

  @override
  Future<bool> updateEnable(
      {required Map<String, dynamic> updateInfo,
      required String webUserId}) async {
    try {
      await FirebaseServices.db.collection("web_user").doc(webUserId).update(
        {
          "account_info.enabled": updateInfo["new_value"],
        },
      );
      return true;
    } catch (e) {
      throw ServerException("$e");
    }
  }

  @override
  Future<bool> updateUserInfo(
      {required String userId,
      required Map<String, dynamic> updateInfo}) async {
    try {
      await FirebaseServices.db.collection("web_users").doc(userId).update({
        "profile_info.names": updateInfo["names"],
        "profile_info.last_names": updateInfo["lastName"],
        "profile_info.email": updateInfo["email"],
        "profile_info.phone": updateInfo["phone"],
        "profile_info.country_prefix": updateInfo["countryPrefix"],
        "profile_info.image": updateInfo["image"],
        "account_info.enabled": updateInfo["enabled"],
        "account_info.type": updateInfo["type"],
        "account_info.subtype": updateInfo["subtype"],
      });
      return true;
    } catch (e) {
      throw ServerException("$e");
    }
  }
}
