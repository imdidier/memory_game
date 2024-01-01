import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:huts_web/features/clients/domain/entities/client_entity.dart';

class ClientModel extends ClientEntity {
  ClientModel({
    required super.accountInfo,
    required super.name,
    required super.email,
    required super.description,
    required super.imageUrl,
    required super.blockedEmployees,
    required super.favoriteEmployees,
    required super.webUsers,
    required super.jobs,
    required super.legalInfo,
    required super.location,
    required super.uidWebUser,
    required super.nightWorkShift,
  });

  factory ClientModel.fromMap(Map<String, dynamic> generalMap) {
    Map<String, dynamic> accountMap = generalMap["account_info"];
    Map<String, dynamic> legalMap = generalMap["legal_info"];
    Map<String, dynamic> locationMap = generalMap["location"];

    return ClientModel(
      accountInfo: ClientAccountInfo(
        hasDynamicFare: accountMap["has_dynamic_fare"],
        id: accountMap["id"],
        minRequestHours: accountMap["min_request_hours"],
        totalRequests: accountMap["total_requests"],
        totalRequestEnded: accountMap["total_requests_ended"],
        status: accountMap["status"],
      ),
      blockedEmployees: generalMap["blocked_employees"],
      favoriteEmployees: generalMap["favorites"],
      description: generalMap["description"],
      name: generalMap["name"],
      email: generalMap["email"],
      imageUrl: generalMap["image"],
      webUsers: generalMap["web_users"],
      jobs: generalMap["jobs"],
      legalInfo: ClientLegalInfo(
        legalId: legalMap["company_legal_id"],
        email: legalMap["email"],
        legalRepresentative: legalMap["legal_representative"],
        legalRepresentativeDocument: legalMap["legal_representative_document"],
        phone: legalMap["phone"],
      ),
      location: ClientLocation(
        address: locationMap["address"],
        city: locationMap["city"],
        position: locationMap["position"] as GeoPoint,
        state: locationMap["state"],
        country: generalMap["country"],
        district: locationMap["district"] ?? "",
      ),
      uidWebUser: generalMap["uid_web_user"] ?? "",
      nightWorkShift: generalMap["night_workshift"],
    );
  }
}
