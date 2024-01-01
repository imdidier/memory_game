import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:huts_web/core/errors/exceptions.dart';
import 'package:huts_web/core/firebase_config/firebase_services.dart';
import 'package:huts_web/features/messages/data/models/message_employee.dart';

abstract class MessagesRemoteDataSource {
  Future<List<String>> getIds(List<String> jobs, List<int> status);
  Future<List<MessageEmployee>> getEmployees();
}

class MessagesRemoteDataSourcesImpl implements MessagesRemoteDataSource {
  @override
  Future<List<String>> getIds(List<String> jobs, List<int> status) async {
    try {
      List<String> employeesIds = [];

    bool isAllStatus = status.any((element) => element==-1);

      await Future.forEach(
        jobs,
        (String jobValue) async {
          Query query = (!isAllStatus)
              ? FirebaseServices.db
                  .collection("employees")
                  .where("jobs", arrayContains: jobValue)
                  .where("account_info.status", whereIn: status)
              : FirebaseServices.db
                  .collection("employees")
                  .where("jobs", arrayContains: jobValue);

          QuerySnapshot querySnapshot = await query.get();

          employeesIds = employeesIds +
              querySnapshot.docs.map((DocumentSnapshot doc) => doc.id).toList();
        },
      );
      return employeesIds.toSet().toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<MessageEmployee>> getEmployees() async {
    try {
      List<MessageEmployee> finalEmployees = [];
      QuerySnapshot querySnapshot =
          await FirebaseServices.db.collection("employees").get();

      for (DocumentSnapshot doc in querySnapshot.docs) {
        Map<String, dynamic> docData = doc.data() as Map<String, dynamic>;
        finalEmployees.add(MessageEmployee.fromMap(docData));
      }

      return finalEmployees;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
