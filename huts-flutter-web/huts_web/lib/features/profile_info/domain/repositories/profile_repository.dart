import 'package:dartz/dartz.dart';
import 'package:flutter/cupertino.dart';
import 'package:huts_web/core/errors/failures.dart';
import 'package:huts_web/features/profile_info/domain/entities/activity.dart';
import 'package:huts_web/features/profile_info/domain/entities/state_country.dart';

import '../../../auth/domain/entities/web_user_entity.dart';

abstract class ProfileRepository {
  Future<Either<Failure, List<StateCountry>?>> getCountry(
      BuildContext context, String countryPrefix);
  Future<Either<Failure, List<WebUser>?>> getClientUsers(
      BuildContext context, String companyId);
  Future<void> editUserInfo(Map<String, dynamic> infoToUpdate);
  Future<Either<Failure, bool>?> editClietAddress(
      Map<String, dynamic> addressToUpdate, String clientId);

  Future<Either<Failure, bool>?> updateInfo(
      String idToUpdate,
      Map<String, dynamic> adminInfoToUpdate,
      Map<String, dynamic> updatedSubtype);

  Future<void> deleteUser(BuildContext context, String keyUserDelete);

  Future<Either<Failure, List<Activity>>> getActivities();
  Future<Either<Failure, bool>?> addNewUser(
      BuildContext context, String idClient);

  Future<void> disableUser(String userId, bool isEnabled);
}
