import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/services/local_notification_service.dart';
import 'package:huts_web/features/auth/display/providers/auth_provider.dart';
import 'package:huts_web/features/clients/data/datasources/clients_remote_datasource.dart';
import 'package:huts_web/features/clients/data/models/client_model.dart';
import 'package:huts_web/features/clients/data/repositories/clients_repository_impl.dart';
import 'package:huts_web/features/clients/domain/entities/client_entity.dart';
import 'package:huts_web/features/clients/domain/use_cases/clients_crud.dart';
import 'package:provider/provider.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/services/event_message_service/upload_file_model.dart';
import '../../../../core/services/navigation_service.dart';
import '../../../../core/utils/ui/ui_methods.dart';
import '../../../auth/domain/entities/screen_size_entity.dart';
import '../../../auth/domain/entities/web_user_entity.dart';
import '../../../statistics/domain/entities/employee_fav.dart';
import '../widgets/create_client_dialog.dart';

class ClientsProvider with ChangeNotifier {
  List<ClientEntity> allClients = [];
  List<ClientEntity> filteredClients = [];

  ClientEntity? selectedClient;
  bool isLoading = false;
  List<Map<String, dynamic>> filteredFavs = [];
  List<Map<String, dynamic>> filteredLocks = [];
  List<Map<String, dynamic>> filteredWebUsers = [];

  List<UploadFile> filesToSend = [];
  StreamSubscription? requestsStream;

  TextEditingController searchController = TextEditingController();

  ClientsRepositoryImpl repository = ClientsRepositoryImpl(
    ClientsRemoteDatasourceImpl(),
  );

  bool isMovingMapCamera = false;

  void setMovingMapCameraValue() {
    isMovingMapCamera = !isMovingMapCamera;
    notifyListeners();
  }

  Future<void> getAllClients() async {
    ClientsCrud(repository).getClients();

    (List<ClientEntity> clientsResp) {
      allClients = [...clientsResp];
      filteredClients = [...allClients];
      allClients.sort((a, b) => a.name.compareTo(b.name));
      filteredClients.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
    };
  }

  void updateClients(List<ClientModel> newClient) {
    allClients = [...newClient];
    filteredClients = [...allClients];

    allClients.sort((a, b) => a.name.compareTo(b.name));
    filteredClients.sort((a, b) => a.name.compareTo(b.name));

    if (selectedClient != null &&
        allClients.any((element) =>
            element.accountInfo.id == selectedClient!.accountInfo.id)) {
      selectedClient = allClients.firstWhere((element) =>
          element.accountInfo.id == selectedClient!.accountInfo.id);
    }

    if (searchController.text.isNotEmpty) {
      filterClients(searchController.text);
      return;
    }

    notifyListeners();
  }

  void filterClients(String query) {
    filteredClients.clear();
    query = query.toLowerCase();
    if (query == '') {
      filteredClients = [...allClients];
    } else {
      for (ClientEntity client in allClients) {
        String status = client.accountInfo.status == 1 ? "Activo" : "Inactivo";

        if (client.email.contains(query)) {
          filteredClients.add(client);
          continue;
        }
        if (client.name.toLowerCase().contains(query)) {
          filteredClients.add(client);
          continue;
        }
        if (client.location.country.toLowerCase().contains(query)) {
          filteredClients.add(client);
          continue;
        }
        if (client.location.city.toLowerCase().contains(query)) {
          filteredClients.add(client);
          continue;
        }
        if (client.accountInfo.id.contains(query)) {
          filteredClients.add(client);
          continue;
        }
        if (status.toLowerCase().contains(query)) {
          filteredClients.add(client);
          continue;
        }
      }
    }
    notifyListeners();
  }

  showClientDetails({required ClientEntity client}) {
    selectedClient = client;
    filteredFavs = [...selectedClient!.favoriteEmployees.values.toList()];
    filteredLocks = [...selectedClient!.blockedEmployees.values.toList()];
    filteredWebUsers = [...selectedClient!.webUsers.values.toList()];
    notifyListeners();
  }

  Future<void> deleteClient({required String id}) async {
    ClientsRepositoryImpl repository = ClientsRepositoryImpl(
      ClientsRemoteDatasourceImpl(),
    );
    await repository.deleteClient(clientId: id);
    notifyListeners();
  }

  Future<void> enableDisableClient(int clientIndex, int status, bool isAdmin,
      [bool enabledWebUser = false, String uidWebUser = '']) async {
    BuildContext? globalContext = NavigationService.getGlobalContext();

    UiMethods().showLoadingDialog(context: globalContext!);
    bool itsOk = await ClientsCrud(repository).enableDisable(
      id: !enabledWebUser
          ? filteredClients[clientIndex].accountInfo.id
          : uidWebUser,
      status: status,
      isAdmin: isAdmin,
      enabledWebUser: enabledWebUser,
    );
    UiMethods().hideLoadingDialog(context: globalContext);

    if (!itsOk) {
      LocalNotificationService.showSnackBar(
        type: "fail",
        message: enabledWebUser
            ? "Ocurrió un error al cambiar el estado del cliente"
            : "Ocurrió un error al cambiar el estado del usuario del cliente",
        icon: Icons.check_outlined,
      );
      return;
    }
    LocalNotificationService.showSnackBar(
      type: "success",
      message: enabledWebUser
          ? "Cliente modificado correctamente"
          : "Usuario del cliente modificado correctamente",
      icon: Icons.check_outlined,
    );
    if (isAdmin && !enabledWebUser) {
      filteredClients[clientIndex].accountInfo.status = status;
    }
    // int generalIndex = allClients.indexWhere((element) =>
    //     element.accountInfo.id == filteredClients[clientIndex].accountInfo.id);
    // if (generalIndex != -1) {
    //   allClients[generalIndex].accountInfo.status = status;
    // }
    notifyListeners();
  }

  Future<bool> addClient({required Map<String, dynamic> client}) async {
    try {
      ClientsRepositoryImpl repository = ClientsRepositoryImpl(
        ClientsRemoteDatasourceImpl(),
      );
      bool resp = await repository.createClient(client: client);
      // if (resp) {
      //   allClients.add(ClientModel.fromMap(Map<String, dynamic>.from(client)));
      //   filteredClients.add(allClients.last);
      // }
      return resp;

      //   return false;
    } catch (e) {
      if (kDebugMode) {
        print('ClientProvider, addClient error: $e');
      }
      return false;
    }
  }

  selectClient({required ClientEntity client}) {
    selectedClient = null;
    selectedClient = client;
    notifyListeners();
  }

  unselectClient() {
    selectedClient = null;
    filteredFavs.clear();
    filteredLocks.clear();
    notifyListeners();
  }

  void showCreateClientDialog(
      BuildContext globalContext, ScreenSize screenSize) {
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
              title: CreateClientDialog(
                screenSize: screenSize,
              ),
            ),
            onWillPop: () async => false,
          );
        });
  }

  Future<bool> updateClientInfo(
    Map<String, dynamic> updateInfo,
    String typeOption, [
    bool isFromAdmin = false,
    WebUser? user,
    ClientEmployee? clientEmployee,
    AuthProvider? authProvider,
  ]) async {
    if (isFromAdmin && typeOption == "favs" && updateInfo["action"] == "add") {
      updateInfo["employees"].addAll(selectedClient!.favoriteEmployees);
    } else if (isFromAdmin &&
        typeOption == "locks" &&
        updateInfo["action"] == "add") {
      updateInfo["employees"].addAll(selectedClient!.blockedEmployees);
    }

    Either<Failure, bool> resp = await ClientsCrud(repository).updateClientInfo(
      isFromAdmin
          ? selectedClient!.accountInfo.id
          : user!.accountInfo.companyId,
      updateInfo,
      typeOption,
    );

    return resp.fold(
      (Failure failure) {
        LocalNotificationService.showSnackBar(
          type: "fail",
          message: "Ocurrió un error al actualizar la información",
          icon: Icons.error_outline,
        );
        if (kDebugMode) {
          print(
              "ClientsProvider, updateClientInfo error: ${failure.errorMessage}");
        }
        return false;
      },
      (r) {
        if (typeOption == "general") {
          selectedClient!.name = updateInfo["name"];
          selectedClient!.email = updateInfo["email"];
          selectedClient!.legalInfo.phone = updateInfo["phone"];
          selectedClient!.accountInfo.minRequestHours =
              updateInfo["minRequestHours"];
          notifyListeners();
          LocalNotificationService.showSnackBar(
            type: "success",
            message: "Información actualizada correctamente",
            icon: Icons.check,
          );
          return true;
        }
        if (typeOption == "legal_info") {
          selectedClient!.legalInfo.legalRepresentative =
              updateInfo["legal_representative"];
          selectedClient!.legalInfo.email = updateInfo["email"];
          selectedClient!.legalInfo.legalRepresentativeDocument =
              updateInfo["legal_representative_document"];
          notifyListeners();
          LocalNotificationService.showSnackBar(
            type: "success",
            message: "Información actualizada correctamente",
            icon: Icons.check,
          );
          return true;
        }
        if (typeOption == "favs") {
          if (updateInfo["action"] == "add") {
            if (isFromAdmin) {
              selectedClient!.favoriteEmployees.addAll(updateInfo["employees"]);
            } else {
              updateInfo['employees'].values.forEach(
                (value) {
                  user!.company.favoriteEmployees.add(
                    ClientEmployee(
                      photo: value['photo'],
                      fullname: value['fullname'],
                      uid: value['uid'],
                      jobs: value['jobs'],
                      phone: value['phone'],
                      hoursWorked: 0,
                    ),
                  );
                },
              );
            }
          } else {
            if (isFromAdmin) {
              selectedClient!.favoriteEmployees.removeWhere(
                (key, value) => key == updateInfo["employee"]["uid"],
              );
            } else {
              user!.company.favoriteEmployees.removeWhere((elementEmployee) =>
                  elementEmployee.uid == updateInfo["employee"]["uid"]);
            }
          }
          List<Map<String, dynamic>> newList = [];
          if (!isFromAdmin) {
            for (var element in user!.company.favoriteEmployees) {
              newList.add(
                {
                  "photo": element.photo,
                  "fullname": element.fullname,
                  "uid": element.uid,
                  "jobs": element.jobs,
                  "phone": element.phone,
                },
              );
            }
          }
          isFromAdmin
              ? filteredFavs = [
                  ...selectedClient!.favoriteEmployees.values.toList()
                ]
              : filteredFavs = newList;
          LocalNotificationService.showSnackBar(
            type: "success",
            message:
                "Favorito ${updateInfo["action"] == 'add' ? 'agregado' : 'eliminado'} con éxito",
            icon: Icons.check,
          );
          notifyListeners();
          return true;
        }

        if (typeOption == "locks") {
          if (updateInfo["action"] == "add") {
            if (isFromAdmin) {
              selectedClient!.blockedEmployees.addAll(updateInfo["employees"]);
            } else {
              updateInfo['employees'].values.forEach(
                (value) {
                  user!.company.blockedEmployees.add(
                    ClientEmployee(
                      photo: value['photo'],
                      fullname: value['fullname'],
                      uid: value['uid'],
                      jobs: value['jobs'],
                      phone: value['phone'],
                      hoursWorked: 0,
                    ),
                  );
                },
              );
            }
          } else {
            if (isFromAdmin) {
              selectedClient!.blockedEmployees.removeWhere(
                (key, value) => key == updateInfo["employee"]["uid"],
              );
            } else {
              user!.company.blockedEmployees.removeWhere((elementEmployee) =>
                  elementEmployee.uid == updateInfo["employee"]["uid"]);
            }
          }
          List<Map<String, dynamic>> newList = [];
          if (!isFromAdmin) {
            for (var element in user!.company.blockedEmployees) {
              newList.add(
                {
                  "photo": element.photo,
                  "fullname": element.fullname,
                  "uid": element.uid,
                  "jobs": element.jobs,
                  "phone": element.phone,
                },
              );
            }
          }
          isFromAdmin
              ? filteredLocks = [
                  ...selectedClient!.blockedEmployees.values.toList()
                ]
              : filteredLocks = newList;

          LocalNotificationService.showSnackBar(
            type: "success",
            message:
                "Bloqueado ${updateInfo["action"] == 'add' ? 'agregado' : 'eliminado'} con éxito",
            icon: Icons.check,
          );
          notifyListeners();
          return true;
        }

        if (typeOption == "web_users") {
          if (updateInfo["action"] == "add") {
            isFromAdmin
                ? selectedClient!.webUsers[updateInfo["employee"]["uid"]] =
                    updateInfo["employee"]
                : user!.company.webUserEmployees.add(
                    {
                      'image': updateInfo["employee"]['image'],
                      'full_name': updateInfo["employee"]['full_name'],
                      'uid': updateInfo["employee"]['uid'],
                      'phone': updateInfo["employee"]['phone'],
                      "enable": updateInfo["employee"]['enable'],
                      "type": updateInfo["employee"]['type'],
                      'subtype': updateInfo["employee"]['subtype'],
                      "email": updateInfo["employee"]['email'],
                    },
                  );
          } else if (updateInfo["action"] == 'delete') {
            if (isFromAdmin) {
              selectedClient!.webUsers.removeWhere(
                (key, value) => key == updateInfo["employee"]["uid"],
              );
            } else {
              user!.company.webUserEmployees.removeWhere((elementEmployee) =>
                  elementEmployee['uid'] == updateInfo["employee"]["uid"]);
            }
          } else {
            if (isFromAdmin) {
              selectedClient!.webUsers[updateInfo["employee"]["uid"]] =
                  updateInfo["employee"];
            } else {
              int index = user!.company.webUserEmployees.indexWhere(
                  (element) => element['uid'] == updateInfo["employee"]["uid"]);
              user.company.webUserEmployees[index] = updateInfo['employee'];
            }
          }

          List<Map<String, dynamic>> newList = [];

          if (!isFromAdmin) {
            for (var element in user!.company.webUserEmployees) {
              bool isWebUserChange =
                  (element['uid'] == updateInfo["employee"]["uid"] &&
                      updateInfo["action"] != "add");
              newList.add(
                {
                  "image": element['image'],
                  "full_name": element['full_name'],
                  "uid": element['uid'],
                  "phone": element['phone'],
                  "email": element['email'],
                  "enable":
                      isWebUserChange ? !element['enable'] : element['enable'],
                  "type": element['type'],
                  'subtype': element['subtype'],
                },
              );
            }
          }
          isFromAdmin
              ? filteredWebUsers = [...selectedClient!.webUsers.values.toList()]
              : user!.company.webUserEmployees = [...newList];

          LocalNotificationService.showSnackBar(
            type: "success",
            message:
                "Usuario ${updateInfo["action"] == 'add' ? 'agregado' : updateInfo["action"] == 'delete' ? 'eliminado' : 'modificado'} con éxito",
            icon: Icons.check,
          );
          notifyListeners();

          return true;
        }

        if (typeOption == "dynamic_fare") {
          selectedClient!.accountInfo.hasDynamicFare = updateInfo["new_value"];
        }

        if (typeOption == "location") {
          selectedClient!.location.address = updateInfo["address"];
          selectedClient!.location.state = updateInfo["state"];
          selectedClient!.location.city = updateInfo["city"];
          selectedClient!.location.position = updateInfo["position"];
          selectedClient!.location.district = updateInfo["district"];
        }

        if (typeOption == "jobs") {
          int selectedClientIndex = filteredClients.indexWhere((element) =>
              element.accountInfo.id == selectedClient!.accountInfo.id);

          if (updateInfo["type"] == "add") {
            selectedClient!.jobs[updateInfo["job_info"]["value"]] =
                updateInfo["job_info"];
            if (selectedClientIndex != -1) {
              filteredClients[selectedClientIndex]
                      .jobs[updateInfo["job_info"]["value"]] =
                  updateInfo["job_info"];
            }
          } else {
            selectedClient!.jobs.removeWhere(
                (key, value) => key == updateInfo["job_info"]["value"]);
            if (selectedClientIndex != -1) {
              filteredClients[selectedClientIndex].jobs.removeWhere(
                  (key, value) => key == updateInfo["job_info"]["value"]);
            }
          }
        }
        notifyListeners();
        if (updateInfo["type"] != "add") {
          LocalNotificationService.showSnackBar(
            type: "success",
            message: "Información actualizada correctamente",
            icon: Icons.check,
          );
          return true;
        }
        return true;
      },
    );
  }

  void onUpdateClientUser(ClientEntity updatedClient, String webUserId) {
    selectedClient = updatedClient;
    BuildContext? globalContext = NavigationService.getGlobalContext();
    if (globalContext == null) return;

    bool isAdmin =
        globalContext.read<AuthProvider>().webUser.accountInfo.type == 'admin';
    if (!isAdmin) {
      for (Map<String, dynamic> webUser
          in updatedClient.webUsers.values.toList()) {
        filteredWebUsers.add(webUser);
      }
    }
    int filteredIndex = 0;
    isAdmin
        ? filteredIndex = filteredWebUsers
            .indexWhere((element) => element["uid"] == webUserId)
        : filteredIndex = updatedClient.webUsers.values
            .toList()
            .indexWhere((element) => element['uid'] == webUserId);

    if (filteredIndex != -1) {
      filteredWebUsers[filteredIndex] = updatedClient.webUsers[webUserId];
    }

    notifyListeners();
  }
}
