import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/firebase_config/firebase_services.dart';
import 'package:huts_web/core/services/navigation_service.dart';
import 'package:huts_web/features/auth/domain/entities/company.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/messages/domain/entities/message_entity.dart';
import 'package:huts_web/features/requests/domain/entities/event_entity.dart';
import "package:flutter/foundation.dart";
import 'package:provider/provider.dart';
import 'dialog_info_widget.dart';
import 'event_message_provider.dart';

class EventMessageService {
  static late EventMessageProvider eventMessageProvider;

  static Future<void> send({
    required Event? eventItem,
    required List<String> employeesIds,
    required Company? company,
    required ScreenSize screenSize,
    String employeeName = "",
  }) async {
    try {
      BuildContext? globalContext = NavigationService.getGlobalContext();

      if (globalContext == null) return;

      await _showMessageDialog(
        globalContext,
        eventItem,
        employeesIds,
        company,
        screenSize,
        employeeName,
      );

      return;
    } catch (e) {
      if (kDebugMode) print("EventMessageService, send error: $e");
      return;
    }
  }

  static Future<Map<String, dynamic>?> getInfo(
      HistoricalMessage message) async {
    try {
      Map<String, dynamic> resp = {};
      resp["data"] = message.toMap();

      QuerySnapshot querySnapshot = await FirebaseServices.db
          .collection("messages")
          .doc(message.id)
          .collection("employees")
          .get();

      resp["employees"] = querySnapshot.docs
          .map((DocumentSnapshot doc) => doc.data() as Map<String, dynamic>)
          .toList();

      return resp;
    } catch (e) {
      if (kDebugMode) {
        print("EventMessageService, getInfo error: $e");
      }
      return null;
    }
  }

  static Future<void> _showMessageDialog(
      BuildContext context,
      Event? event,
      List<String> ids,
      Company? company,
      ScreenSize screenSize,
      String employeeName) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return ChangeNotifierProvider(
          create: (_) => EventMessageProvider(),
          child: WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              scrollable: false,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(15),
                ),
              ),
              titlePadding: const EdgeInsets.all(0),
              title: DialogInfoWidget(
                company: company,
                event: event,
                screenSize: screenSize,
                employeesIds: ids,
                employeeName: employeeName,
              ),
            ),
          ),
        );
      },
    );
    // return itsDone;
  }
}
