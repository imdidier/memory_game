import 'package:flutter/material.dart';
import 'package:huts_web/features/profile_info/domain/repositories/profile_repository.dart';

class DeleteUser {
  final ProfileRepository repository;

  DeleteUser(this.repository);

  Future<void> call(BuildContext context, String keyUserDelete) async {
    repository.deleteUser(context, keyUserDelete);
  }
}
