import '../repositories/get_admins_repository.dart';

class GetAdmins {
  final GetAdminsRepository getAdminsRepository;
  GetAdmins(this.getAdminsRepository);
  void getAdmins(String uid) async => getAdminsRepository.getAdmins(uid);
  void getCompanies(String uid) async => getAdminsRepository.getCompanies(uid);
}
