class MessageEmployee {
  String imageUrl;
  String names;
  String lastNames;
  int status;
  String id;
  bool isSelected;

  MessageEmployee({
    required this.imageUrl,
    required this.names,
    required this.lastNames,
    required this.status,
    required this.id,
    required this.isSelected,
  });

  MessageEmployee.fromMap(Map<String, dynamic> map)
      : imageUrl = map["profile_info"]["image"],
        names = map["profile_info"]["names"],
        lastNames = map["profile_info"]["last_names"],
        status = map["account_info"]["status"],
        id = map["uid"],
        isSelected = false;
}
