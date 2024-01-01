import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../../services/navigation_service.dart';
import 'dialog_content.dart';

class JobSelectionDialog {
  static Future<List<Map<String, dynamic>>?> show(
      {required List<Map<String, dynamic>> jobs}) async {
    try {
      BuildContext? globalContext = NavigationService.getGlobalContext();
      if (globalContext == null) return null;
      List<Map<String, dynamic>>? selectedJobs =
          await _buildDialog(globalContext, jobs);

      return selectedJobs;
    } catch (e) {
      if (kDebugMode) print("JobSelectionDialog, show error: $e");
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>?> _buildDialog(
    BuildContext context,
    List<Map<String, dynamic>> jobs,
  ) async {
    return showDialog(
      context: context,
      builder: (_) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            scrollable: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(15),
              ),
            ),
            titlePadding: const EdgeInsets.all(0),
            title: JobDialogContent(
              jobs: jobs,
            ),
          ),
        );
      },
    );
  }
}
