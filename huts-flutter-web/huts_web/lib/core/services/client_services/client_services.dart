// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/firebase_config/firebase_services.dart';
import 'package:huts_web/core/services/navigation_service.dart';
import 'package:huts_web/features/clients/data/models/client_model.dart';
import 'package:huts_web/features/clients/domain/entities/client_entity.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../features/clients/display/provider/clients_provider.dart';

class ClientServices {
  static Future<ClientEntity> getClient({required String clientId}) async {
    DocumentSnapshot clientDoc =
        await FirebaseServices.db.collection("clients").doc(clientId).get();
    return ClientModel.fromMap(clientDoc.data() as Map<String, dynamic>);
  }

  static Future<bool> updateClientUser(
      {required Map<String, dynamic> updateData}) async {
    try {
      Uri cloudUrl = Uri.parse(
          "https://us-central1-huts-services.cloudfunctions.net/updateUserClient");

      http.Response response = await http.post(
        cloudUrl,
        body: updateData,
      );

      if (response.statusCode != 200) return false;

      BuildContext? globalContext = NavigationService.getGlobalContext();

      if (globalContext == null) return false;

      ClientEntity updatedClient =
          await getClient(clientId: updateData["client_id"]);

      Provider.of<ClientsProvider>(globalContext, listen: false)
          .onUpdateClientUser(updatedClient, updateData["uid"]);

      return true;
    } catch (e) {
      if (kDebugMode) {
        print("ClientServices, updateClientUser error: $e");
      }
      return false;
    }
  }
}
