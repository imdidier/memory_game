// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:huts_web/core/firebase_config/firebase_services.dart';
import 'package:huts_web/features/auth/domain/entities/web_user_entity.dart';
import 'package:provider/provider.dart';
import '../../../../core/config.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/navigation_service.dart';
import '../../../auth/data/models/web_user_model.dart';
import 'package:http/http.dart' as http;

import '../../display/providers/admin_provider.dart';

abstract class AdminsRemoteDataSource {
  Future<void> listenAdmins(String uid);
  Future<void> listenCompanies(String uid);

  Future<bool> enableDisabled(String id, bool toEnable);
  Future<String> create(Map<String, dynamic> data);
  Future<String> delete(String uid);
  Future<String> edit(Map<String, dynamic> data, bool isFromAdmin);
}

class AdminsRemoteDataSourceImpl implements AdminsRemoteDataSource {
  @override
  Future<void> listenAdmins(String uid) async {
    try {
      BuildContext? globalContext = NavigationService.getGlobalContext();
      if (globalContext == null) {
        throw const ServerException("El contexto es nulo");
      }
      FirebaseServices.db
          .collection('web_users')
          .where('account_info.type', isNotEqualTo: 'client')
          // .where('account_info.company_id', isEqualTo: '') //ONLY HUTS USERS
          .snapshots()
          .listen(
        (QuerySnapshot querySnapshot) async {
          List<WebUser> allAdmins = [];
          for (var myDoc in querySnapshot.docs) {
            Map<String, dynamic>? myData =
                myDoc.data() as Map<String, dynamic>?;
            if (myDoc.id == uid) continue;
            myData!['id'] = myDoc.id;

            Map<String, dynamic> companyData = {};
            if (myData['account_info']['type'] == 'client') {
              DocumentSnapshot companyDoc = await FirebaseServices.db
                  .collection("clients")
                  .doc(myData["account_info"]["company_id"])
                  .get();

              companyData = companyDoc.data() as Map<String, dynamic>;
              companyData["id"] = companyDoc.id;
            }

            myData['company_info'] = companyData;
            WebUser newAdmin = WebUserModel.fromMap(myData);
            allAdmins.add(newAdmin);
          }
          Provider.of<AdminProvider>(globalContext, listen: false)
              .updateAdmin(allAdmins);
          allAdmins;
        },
      );

      int index = FirebaseServices.streamSubscriptions
          .indexWhere((addedStream) => addedStream.id == "listen_admin");

      if (index != -1) {
        await FirebaseServices.streamSubscriptions[index].streamSubscription
            ?.cancel();
        FirebaseServices.streamSubscriptions.removeAt(index);
      }
      AdminProvider adminProvider =
          Provider.of<AdminProvider>(globalContext, listen: false);
      FirebaseServices.streamSubscriptions.add(
        FirestoreStream(
          id: "listen_admin",
          streamSubscription: adminProvider.requestsStream,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error AdminsRemoteDataSourceImpl, getAdmins $e');
      }
      throw ServerException("$e");
    }
  }

  @override
  Future<void> listenCompanies(String uid) async {
    try {
      BuildContext? globalContext = NavigationService.getGlobalContext();
      if (globalContext == null) {
        throw const ServerException("El contexto es nulo");
      }
      FirebaseServices.db
          .collection('web_users')
          .where('account_info.type', isEqualTo: 'client')
          .snapshots()
          .listen(
        (QuerySnapshot querySnapshot) async {
          List<WebUser> allCompanies = [];

          for (var myDoc in querySnapshot.docs) {
            Map<String, dynamic> myData = myDoc.data() as Map<String, dynamic>;
            if (myDoc.id == uid) continue;

            WebUser newCompany = WebUserModel.fromMap(myData);
            allCompanies.add(newCompany);
            Provider.of<AdminProvider>(globalContext, listen: false)
                .updateCompanies(allCompanies);
            allCompanies;
          }
        },
      );
      int index = FirebaseServices.streamSubscriptions
          .indexWhere((addedStream) => addedStream.id == "listen_companies");

      if (index != -1) {
        await FirebaseServices.streamSubscriptions[index].streamSubscription
            ?.cancel();
        FirebaseServices.streamSubscriptions.removeAt(index);
      }
      AdminProvider adminProvider =
          Provider.of<AdminProvider>(globalContext, listen: false);
      FirebaseServices.streamSubscriptions.add(
        FirestoreStream(
          id: "listen_companies",
          streamSubscription: adminProvider.requestsStream,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error AdminsRemoteDataSourceImpl, getAdmins $e');
      }
      throw ServerException("$e");
    }
  }

  @override
  Future<bool> enableDisabled(String id, bool toEnable) async {
    try {
      await FirebaseServices.db.collection("web_users").doc(id).update(
        {
          "account_info.enabled": toEnable,
        },
      );
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error AdminsRemoteDataSourceImpl, enableDisabled $e');
      }
      return false;
    }
  }

  @override
  Future<String> create(Map<String, dynamic> data) async {
    try {
      QuerySnapshot query = await FirebaseServices.db
          .collection("web_users")
          .where("profile_info.email", isEqualTo: data["profile_info"]["email"])
          .get();

      if (query.size > 0) {
        return "repeated_email";
      }

      Uri cloudUrl = Uri.parse("$urlFunctions/createAdmin");
      http.Response response = await http.post(
        cloudUrl,
        headers: {
          "content-type": "application/json; charset=UTF-8",
        },
        body: json.encode(data),
      );

      if (response.statusCode != 200) {
        if (kDebugMode) {
          print(
              "AdminsRemoteDataSourceImpl, create error: status code: ${response.statusCode}, reason phrase: ${response.reasonPhrase}");
        }
        return "error";
      }

      return jsonDecode(response.body)["uid"];
    } catch (e) {
      if (kDebugMode) {
        print('AdminsRemoteDataSourceImpl, create error: $e');
      }
      return "error";
    }
  }

  @override
  Future<String> delete(String uid) async {
    try {
      Uri cloudUrl = Uri.parse("$urlFunctions/deleteAdmin");
      http.Response response = await http.post(
        cloudUrl,
        headers: {
          "content-type": "application/json; charset=UTF-8",
        },
        body: json.encode({"uid": uid}),
      );

      if (response.statusCode != 200) {
        if (kDebugMode) {
          print(
              "AdminsRemoteDataSourceImpl, delete error: status code: ${response.statusCode}, reason phrase: ${response.reasonPhrase}");
        }
        return "error";
      }
      return jsonDecode(response.body)["uid"];
    } catch (e) {
      if (kDebugMode) {
        print('AdminsRemoteDataSourceImpl, delete error: $e');
      }
      return "error";
    }
  }

  @override
  Future<String> edit(Map<String, dynamic> data, bool isFromAdmin) async {
    try {
      if (data["update_auth"] && data["update_email"]) {
        QuerySnapshot query = await FirebaseServices.db
            .collection("web_users")
            .where("profile_info.email", isEqualTo: data["user_info"]["email"])
            .get();

        if (query.size > 0) {
          return "repeated_email";
        }
      }

      if (isFromAdmin) {
        await FirebaseServices.db
            .collection("web_users")
            .doc(data["id"])
            .update({
          "account_info.subtype": data["user_info"]["subtype"],
          "profile_info.email": data["user_info"]["email"],
          "profile_info.names": data["user_info"]["names"],
          "profile_info.last_names": data["user_info"]["last_names"],
          "profile_info.phone": data["user_info"]["phone"],
        });
      } else {
        List<WebUser> allCompanies = [];
        await FirebaseServices.db
            .collection('web_users')
            .where('account_info.type', isEqualTo: 'client')
            .where('account_info.subtype', isEqualTo: 'admin') //ONLY HUTS USERS
            .get()
            .then((myQuery) async {
          for (var myDoc in myQuery.docs) {
            Map<String, dynamic> myData = myDoc.data();
            myData['id'] = myData['uid'];
            myData.remove('uid');
            myData['company_info'] = Map<String, dynamic>.from({});

            WebUser newCompany = WebUserModel.fromMap(myData);
            allCompanies.add(newCompany);
          }
        });

        List<WebUser> client = [
          ...allCompanies.where((WebUser element) =>
              element.accountInfo.subtype == 'client' &&
              element.accountInfo.type == 'admin' &&
              element.accountInfo.companyId == data['id'])
        ];
        String uidClient = '';
        for (var element in client) {
          uidClient = element.uid;
        }
        await FirebaseServices.db
            .collection("web_users")
            .doc(uidClient)
            .update({
          "account_info.subtype": data["user_info"]["subtype"],
          "profile_info.email": data["user_info"]["email"],
          "profile_info.names": data["user_info"]["names"],
          "profile_info.last_names": data["user_info"]["last_names"],
          "profile_info.phone": data["user_info"]["phone"],
        });
      }

      if (data["update_auth"]) {
        Uri cloudUrl = Uri.parse("$urlFunctions/updateWebUserAuth");

        http.Response response = await http.post(
          cloudUrl,
          headers: {
            "content-type": "application/json",
          },
          body: json.encode({
            "uid": data["id"],
            "email": data["user_info"]["email"],
            "password": data["password"],
          }),
        );

        if (response.statusCode != 200) {
          if (kDebugMode) {
            print(
                "AdminsRemoteDataSourceImpl, edit error: status code: ${response.statusCode}, reason phrase: ${response.reasonPhrase}");
          }
          return "error";
        }
        return jsonDecode(response.body)["uid"];
      }

      return "success";
    } catch (e) {
      if (kDebugMode) {
        print('AdminsRemoteDataSourceImpl, edit error: $e');
      }
      return "error";
    }
  }
}
