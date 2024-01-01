// ignore_for_file: use_build_context_synchronously

import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:huts_web/core/firebase_config/firebase_services.dart';
import 'package:huts_web/features/auth/data/models/web_user_model.dart';

import '../../../../core/errors/exceptions.dart';

abstract class AuthRemoteDataSource {
  Future<WebUserModel>? getUserInfo();
  Future<UserCredential>? emailSignIn(String email, String password);
  Future<bool>? recoverPassword(String email);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  @override
  Future<WebUserModel> getUserInfo() async {
    try {
      DocumentSnapshot adminDoc = await FirebaseServices.db
          .collection("web_users")
          .doc(FirebaseServices.auth.currentUser!.uid)
          .get();
      Map<String, dynamic> adminData = adminDoc.data() as Map<String, dynamic>;
      adminData['id'] = adminDoc.id;

      Map<String, dynamic> companyData = {};

      if (adminData['account_info']['type'] == 'client') {
        DocumentSnapshot companyDoc = await FirebaseServices.db
            .collection("clients")
            .doc(adminData["account_info"]["company_id"])
            .get();

        companyData = companyDoc.data() as Map<String, dynamic>;

        companyData["id"] = companyDoc.id;
      }

      adminData["company_info"] = companyData;
      adminData['id'] = adminDoc.id;
      adminData["client_association_info"] = Map<String, dynamic>.from({});

      return WebUserModel.fromMap(adminData);
    } catch (e) {
      developer.log("AuthRemoteDataSource, getUserInfo error: $e");
      throw ServerException("$e");
    }
  }

  @override
  Future<UserCredential> emailSignIn(String email, String password) async {
    try {
      final UserCredential userCredential =
          await FirebaseServices.auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      developer.log("AuthRemoteDataSource, emailSignIn error: ${e.code}");
      throw ServerException(e.code);
    } catch (error) {
      developer.log("AuthRemoteDataSource, emailSignIn error: $error");
      throw ServerException("$error");
    }
  }

  @override
  Future<bool>? recoverPassword(String email) async {
    try {
      await FirebaseServices.auth.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      developer.log("AuthRemoteDataSource, recoverPassword error: ${e.code}");
      throw ServerException(e.code);
    } catch (error) {
      developer.log("AuthRemoteDataSource, recoverPassword error: $error");
      throw ServerException("$error");
    }
  }
}
