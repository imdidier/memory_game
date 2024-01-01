import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/services/local_notification_service.dart';

import '../../../../core/errors/failures.dart';
import '../../../auth/data/models/web_user_model.dart';
import '../../../auth/domain/entities/screen_size_entity.dart';
import '../../data/datasources/users_remote_datasource.dart';
import '../../data/repositories/users_repository_impl.dart';
import '../../domain/use_cases/users_crud.dart';
import '../widgets/users/dialog_content_web_user.dart';

class UsersProvider with ChangeNotifier {
  List<WebUserModel> allUsers = [];

  List<WebUserModel> filteredUsers = [];

  WebUserModel? selectedUser;

  bool isLoading = false;
  List<Map<String, dynamic>> filteredUserClient = [];

  UsersRepositoryImpl repository = UsersRepositoryImpl(
    UsersRemoteDatasourceImpl(),
  );

  Future<void> getAllUsers() async {
    Either<Failure, List<WebUserModel>> resp =
        await UsersCrud(repository).getUsers();
    resp.fold(
      (l) => null,
      (List<WebUserModel> userResp) {
        allUsers = [...userResp];
        filteredUsers = [...allUsers];
        notifyListeners();
      },
    );
  }

  showCreateWebUserDialog(
    BuildContext globalContext,
    ScreenSize screenSize, {
    Map<String,dynamic>? userToEdit,
  }) {
    showDialog(
        context: globalContext,
        barrierDismissible: false,
        builder: (BuildContext dialogCtx) {
          return WillPopScope(
            child: AlertDialog(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(15)),
              ),
              titlePadding: const EdgeInsets.all(0),
              title: DialogContentWebUser(
                screenSize: screenSize,
                userToEdit: userToEdit,
              ),
            ),
            onWillPop: () async => false,
          );
        });
  }

  editUser({required WebUserModel user}) {
    selectedUser = user;
    notifyListeners();
  }

  selectUser({required WebUserModel user}) {
    selectedUser = null;
    selectedUser = user;
    notifyListeners();
  }

  unselectUser() {
    selectedUser = null;
    notifyListeners();
  }

  Future<void> updateUserInfo(
      Map<String, dynamic> updateInfo, String type) async {
    Either<Failure, bool> resp = await UsersCrud(repository).updateUserInfo(
      selectedUser!.uid,
      updateInfo,
    );

    resp.fold((Failure failure) {
      LocalNotificationService.showSnackBar(
        type: "fail",
        message: "Ocurrió un error al actualizar la información",
        icon: Icons.error_outline,
      );
      if (kDebugMode) {
        print("UsersProvider, updateUserInfo error: ${failure.errorMessage}");
      }
    }, (r) {
      if (type == "enable") {
        selectedUser!.accountInfo.enabled = updateInfo["new_value"];
        notifyListeners();
        return;
      }
      LocalNotificationService.showSnackBar(
        type: "success",
        message: "Información actualizada correctamente",
        icon: Icons.error_outline,
      );

      notifyListeners();
      return;
    });
  }
}
