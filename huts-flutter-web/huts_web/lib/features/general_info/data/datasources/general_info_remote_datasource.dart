// ignore_for_file: use_build_context_synchronously

import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:huts_web/core/errors/exceptions.dart';
import 'package:huts_web/core/firebase_config/firebase_services.dart';
import 'package:huts_web/features/auth/display/providers/auth_provider.dart';
import 'package:huts_web/features/general_info/data/models/general_info_model.dart';
import 'package:huts_web/features/general_info/data/models/other_info_model.dart';
import 'package:provider/provider.dart';
import 'dart:convert' as convert;

import '../../../../core/services/navigation_service.dart';

abstract class GeneralInfoRemoteDataSource {
  Future<GeneralInfoModel>? getGeneralInfo(BuildContext context);
  Future<OtherInfoModel>? getOtherInfo(BuildContext context);
}

class GeneralInfoRemoteDataSourceImpl implements GeneralInfoRemoteDataSource {
  @override
  Future<GeneralInfoModel>? getGeneralInfo(BuildContext context) async {
    try {
      AuthProvider authProvider =
          Provider.of<AuthProvider>(context, listen: false);
      String countryPath =
          authProvider.webUser.profileInfo.countryPrefix == 'COL'
              ? 'colombia'
              : 'costa_rica';
      DocumentSnapshot doc =
          await FirebaseServices.db.collection('info').doc('general').get();
      Map<String, dynamic> generaldata = doc.data() as Map<String, dynamic>;
      DocumentSnapshot countryDoc = await FirebaseServices.db
          .collection('countries_info')
          .doc(countryPath)
          .get();
      Map<String, dynamic> countryData =
          countryDoc.data() as Map<String, dynamic>;

      generaldata['country_info'] = countryData;

      GeneralInfoModel generalInfoModel = GeneralInfoModel.fromMap(generaldata);

      String prefix =
          authProvider.webUser.profileInfo.countryPrefix.toLowerCase();

      String data = await DefaultAssetBundle.of(context)
          .loadString('assets/${prefix}_data.json');

      final jsonResult = convert.json.decode(data) as List;

      String stateKey = prefix == 'col' ? "departamento" : "Nombre";
      String stateCities = prefix == 'col' ? "ciudades" : "Cantones";

      for (var element in jsonResult) {
        Map<String, dynamic> stateMap = {
          'state': element[stateKey],
          'cities': element[stateCities] as List,
        };
        generalInfoModel.countryInfo.statesCities.add(stateMap);
      }

      return generalInfoModel;
    } catch (e) {
      developer.log("GeneralInfoRemoteDataSource, getGeneralInfo error: $e");
      throw ServerException("$e");
    }
  }

  @override
  Future<OtherInfoModel>? getOtherInfo(BuildContext context) async {
    try {
      DocumentSnapshot doc =
          await FirebaseServices.db.collection('info').doc('other_info').get();
      OtherInfoModel otherInfo =
          OtherInfoModel.fromMap(doc.data() as Map<String, dynamic>);

      //Check if the webuser is a huts user associated to a client
      BuildContext? context = NavigationService.getGlobalContext();
      if (context == null) return otherInfo;

      Map<String, dynamic> systemRoles = otherInfo.systemRoles;
      AuthProvider authProvider = context.read<AuthProvider>();
      String webUserType = authProvider.webUser.accountInfo.type;
      String webUserSubType = authProvider.webUser.accountInfo.subtype;

      if (webUserType != "admin") return otherInfo;

      if (!systemRoles["admin"].containsKey(webUserSubType)) return otherInfo;

      if (!systemRoles["admin"][webUserSubType]
          .containsKey("has_client_association")) {
        return otherInfo;
      }

      if (!systemRoles["admin"][webUserSubType]["has_client_association"]) {
        return otherInfo;
      }

      authProvider.webUser.clientAssociationInfo = {
        "client_name": systemRoles["admin"][webUserSubType]["client_name"],
        "client_id": systemRoles["admin"][webUserSubType]["client_id"],
      };

      return otherInfo;
    } catch (e) {
      developer.log("GeneralInfoRemoteDataSource, getOtherInfo error: $e");
      throw ServerException("$e");
    }
  }
}
