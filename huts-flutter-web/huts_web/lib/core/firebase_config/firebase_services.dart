import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:huts_web/firebase_options.dart';

class FirebaseServices {
  static late FirebaseApp firebaseApp;
  static late FirebaseFirestore db;
  static late FirebaseAuth auth;
  static late FirebaseStorage storage;
  static List<FirestoreStream> streamSubscriptions = [];
  static Future<void> init() async {
    try {
      firebaseApp = await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
      db = FirebaseFirestore.instanceFor(app: firebaseApp);
      auth = FirebaseAuth.instanceFor(app: firebaseApp);
      storage = FirebaseStorage.instanceFor(app: firebaseApp);
    } catch (e) {
      developer.log("FirebaseServices, init error: $e");
    }
  }

  static Future<List<String>> uploadFilesFromBytes(
      List<Map<String, dynamic>> filesData) async {
    try {
      List<String> filesUrls = [];
      await Future.forEach(
        filesData,
        (Map<String, dynamic> fileItem) async {
          final Reference reference = storage.ref().child(fileItem["path"]);
          final TaskSnapshot taskSnapshot = await reference.putData(
            fileItem["bytes"],
            SettableMetadata(
              contentType: (fileItem["type"] == "image")
                  ? 'image/jpeg'
                  : (fileItem["type"] == "pdf")
                      ? "application/pdf"
                      : (fileItem["type"] == "word")
                          ? "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
                          : (fileItem["type"] == "excel")
                              ? "application/vnd.ms-excel"
                              : "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            ),
          );
          filesUrls.add(await taskSnapshot.ref.getDownloadURL());
        },
      );
      return filesUrls;
    } catch (e) {
      if (kDebugMode) print("FirebaseServices, uploadFilesFromBytes error: $e");
      return [];
    }
  }
}

class FirestoreStream {
  String id;
  StreamSubscription? streamSubscription;

  FirestoreStream({
    required this.id,
    required this.streamSubscription,
  });
}
