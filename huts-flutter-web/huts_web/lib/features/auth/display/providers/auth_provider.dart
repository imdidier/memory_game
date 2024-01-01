// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/errors/failures.dart';
import 'package:huts_web/core/services/local_notification_service.dart';
import 'package:huts_web/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:huts_web/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:huts_web/features/auth/domain/use_cases/email_sign_in.dart';
import 'package:huts_web/features/auth/domain/use_cases/get_user_info.dart';
import 'package:huts_web/features/auth/domain/use_cases/recover_password.dart';
import 'package:huts_web/features/general_info/data/models/other_info_model.dart';

import '../../../../core/firebase_config/firebase_services.dart';
import '../../domain/entities/web_user_entity.dart';

enum AuthStatus { checking, authenticated, notAuthenticated }

class AuthProvider with ChangeNotifier {
  AuthStatus authStatus = AuthStatus.checking;
  User? firebaseUser = FirebaseAuth.instance.currentUser;
  Map<String, dynamic> signUpData = {};
  bool isLoading = false;
  bool isRecoveringPass = false;
  bool isShowingPass = false;
  late WebUser webUser;

  AuthProvider(BuildContext context) {
    listenUserAuth(context);
  }

  Future<void> listenUserAuth(BuildContext context) async {
    bool isGettingInfo = false;
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      firebaseUser = user;
      if (firebaseUser == null) {
        authStatus = AuthStatus.notAuthenticated;
        developer.log('User is currently signed out!');
        notifyListeners();
      } else {
        if (isGettingInfo) return;
        isGettingInfo = true;
        await getUserInfoOrFail();
        developer.log('User is signed in!');
        isGettingInfo = false;
      }
    });
  }

  Future<void> emailSignInOrFail(String email, String password) async {
    changeLoadingStatus();
    AuthRepositoryImpl repository =
        AuthRepositoryImpl(AuthRemoteDataSourceImpl());
    final credentialOrFail =
        await EmailSignIn(repository).call(email, password);
    credentialOrFail.fold((Failure failure) {
      LocalNotificationService.showSnackBar(
        type: "error",
        message: getErrorText(failure.errorMessage ?? " "),
        icon: Icons.error_outline,
      );
      changeLoadingStatus();
      return;
    }, (UserCredential? userCredential) {
      if (userCredential == null) {
        LocalNotificationService.showSnackBar(
          type: "error",
          message: getErrorText(""),
          icon: Icons.error_outline,
        );
        changeLoadingStatus();
        return;
      }
    });
  }

  late OtherInfoModel temporalOtherInfo;

  Future<void> getUserInfoOrFail() async {
    AuthRepositoryImpl repository =
        AuthRepositoryImpl(AuthRemoteDataSourceImpl());
    final userOrFail = await GetUserInfo(repository).call();
    userOrFail.fold((Failure failure) async {
      LocalNotificationService.showSnackBar(
        type: "error",
        message: getErrorText(failure.errorMessage ?? " "),
        icon: Icons.error_outline,
      );
      if (isLoading) changeLoadingStatus();
      await signOut();
      return;
    }, (WebUser? user) async {
      if (user == null) {
        LocalNotificationService.showSnackBar(
          type: "error",
          message: getErrorText(""),
          icon: Icons.error_outline,
        );
        if (isLoading) changeLoadingStatus();
        await signOut();
        return;
      }
      webUser = user;
      if (webUser.company.accountInfo['status'] == 0) {
        await signOut();
        LocalNotificationService.showSnackBar(
          type: "error",
          message: "Tu usuario ha sido deshabilitado",
          icon: Icons.error_outline,
        );
      }
      if (!webUser.accountInfo.enabled) {
        await signOut();
        LocalNotificationService.showSnackBar(
          type: "error",
          message: "Tu usuario ha sido bloqueado",
          icon: Icons.error_outline,
        );
      } else {
        authStatus = AuthStatus.authenticated;
      }

      DocumentSnapshot doc =
          await FirebaseServices.db.collection('info').doc('other_info').get();

      temporalOtherInfo =
          OtherInfoModel.fromMap(doc.data() as Map<String, dynamic>);

      if (isLoading) changeLoadingStatus();
      notifyListeners();
    });
  }

  Future<void> sendPasswordRecoveryMessage(String email) async {
    changeLoadingStatus();
    AuthRepositoryImpl repository =
        AuthRepositoryImpl(AuthRemoteDataSourceImpl());
    final resp = await RecoverPassword(repository).call(email);
    resp.fold((Failure failure) {
      LocalNotificationService.showSnackBar(
        type: "error",
        message: getErrorText(failure.errorMessage ?? ""),
        icon: Icons.error_outline,
      );
      changeLoadingStatus();
      return;
    }, (bool? itsOk) {
      if (itsOk == null) {
        LocalNotificationService.showSnackBar(
          type: "error",
          message: getErrorText(""),
          icon: Icons.error_outline,
        );
        changeLoadingStatus();
        return;
      }
      changeLoadingStatus();
      LocalNotificationService.showSnackBar(
        type: "success",
        message: "Se envió el mensaje de recuperación correctamente",
        icon: Icons.error_outline,
      );
    });
  }

  Future<void> signOut() async {
    try {
      for (FirestoreStream firestoreStream
          in FirebaseServices.streamSubscriptions) {
        firestoreStream.streamSubscription?.cancel();
      }
      await FirebaseServices.auth.signOut();
    } catch (e) {
      developer.log("AuthProvider, signOut error: $e");
    }
  }

  void changeLoadingStatus() {
    isLoading = !isLoading;
    notifyListeners();
  }

  void changeRecoveringPassStatus() {
    isRecoveringPass = !isRecoveringPass;
    notifyListeners();
  }

  void changePasswordStatus() {
    isShowingPass = !isShowingPass;
    notifyListeners();
  }

  String getErrorText(String code) {
    switch (code) {
      case "user-not-found":
        return "El correo ingresado no se encuentra registrado";

      case "invalid-password":
        return "Contraseña inválida";

      case "wrong-password":
        return "Contraseña incorrecta";

      default:
        return "Ocurrió un error, intenta nuevamente";
    }
  }
}
