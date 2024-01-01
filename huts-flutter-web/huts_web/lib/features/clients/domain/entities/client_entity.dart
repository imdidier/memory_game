import 'package:cloud_firestore/cloud_firestore.dart';

class ClientEntity {
  ClientAccountInfo accountInfo;
  String name;
  String email;
  String description;
  String imageUrl;
  Map<String, dynamic> blockedEmployees;
  Map<String, dynamic> favoriteEmployees;
  Map<String, dynamic> webUsers;
  String uidWebUser;

  Map<String, dynamic> jobs;
  ClientLegalInfo legalInfo;
  ClientLocation location;

  Map<String, dynamic> nightWorkShift;

  ClientEntity({
    required this.accountInfo,
    required this.name,
    required this.email,
    required this.description,
    required this.imageUrl,
    required this.blockedEmployees,
    required this.favoriteEmployees,
    required this.webUsers,
    required this.jobs,
    required this.legalInfo,
    required this.location,
    required this.uidWebUser,
    required this.nightWorkShift,
  });
}

class ClientAccountInfo {
  bool hasDynamicFare;
  String id;
  int minRequestHours;
  int totalRequests;
  int totalRequestEnded;
  int status;

  ClientAccountInfo({
    required this.hasDynamicFare,
    required this.id,
    required this.minRequestHours,
    required this.totalRequests,
    required this.totalRequestEnded,
    required this.status,
  });
}

class ClientLegalInfo {
  String legalId;
  String email;
  String legalRepresentative;
  String legalRepresentativeDocument;
  String phone;
  ClientLegalInfo({
    required this.legalId,
    required this.email,
    required this.legalRepresentative,
    required this.legalRepresentativeDocument,
    required this.phone,
  });
}

class ClientLocation {
  String address;
  String city;
  GeoPoint position;
  String state;
  String country;
  String? district;

  ClientLocation({
    required this.address,
    required this.city,
    required this.position,
    required this.state,
    required this.country,
    required this.district,
  });
}
