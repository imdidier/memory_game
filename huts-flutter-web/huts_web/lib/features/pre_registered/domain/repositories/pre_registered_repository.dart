abstract class PreRegisteredRepository {
  void getPreRegistered(DateTime startDate, DateTime endDate);

  Future<bool> approveEmployee(String employeeID, String employeeName);
}
