import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/utils/ui/widgets/employees/client_selection/dialog_content_client.dart';
import 'package:huts_web/features/clients/domain/entities/client_entity.dart';

import '../../../../../services/navigation_service.dart';

class ClientSelectionDialog {
  static Future<ClientEntity?> show(
      {required List<ClientEntity> clients}) async {
    try {
      BuildContext? globalContext = NavigationService.getGlobalContext();
      if (globalContext == null) return null;
      ClientEntity? selectedClient = await _buildDialog(globalContext, clients);

      return selectedClient;
    } catch (e) {
      if (kDebugMode) print("ClientctionDialog, show error: $e");
      return null;
    }
  }

  static Future<ClientEntity?> _buildDialog(
    BuildContext context,
    List<ClientEntity> clients,
  ) async {
    return showDialog(
      context: context,
      builder: (_) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(15),
              ),
            ),
            titlePadding: const EdgeInsets.all(0),
            title: DialogContentClients(clients: clients),
          ),
        );
      },
    );
  }
}
