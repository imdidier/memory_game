import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/features/auth/domain/entities/web_user_entity.dart';
import 'package:huts_web/features/profile_info/data/datasources/local_data_sources.dart';
import 'package:huts_web/features/profile_info/data/datasources/remote_profile_data_sources.dart';
import 'package:huts_web/features/profile_info/domain/entities/activity.dart';
import 'package:huts_web/features/profile_info/domain/entities/state_country.dart';
import 'package:huts_web/core/errors/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:huts_web/features/profile_info/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileLocalDataSources? profileLocalDataSources;
  final RemoteProfileDatasurces? remoteProfileDatasurces;

  ProfileRepositoryImpl(
      {this.profileLocalDataSources, this.remoteProfileDatasurces});
  @override
  Future<Either<Failure, List<StateCountry>?>> getCountry(
      BuildContext context, String countryPrefix) async {
    try {
      return Right(
          await profileLocalDataSources!.getCountries(context, countryPrefix));
    } catch (e) {
      return Left(LocalFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<WebUser>?>> getClientUsers(
      BuildContext context, String compayId) async {
    try {
      return Right(
          await remoteProfileDatasurces!.getClientUsers(context, compayId));
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<void> editUserInfo(Map<String, dynamic> infoToUpdate) async {
    try {
      await remoteProfileDatasurces!.editUserInfo(infoToUpdate);
    } catch (e) {
      ServerFailure(errorMessage: e.toString());
    }
  }

  @override
  Future<Either<Failure, bool>> editClietAddress(
      Map<String, dynamic> addressToUpdate, String clientId) async {
    try {
      return Right(await remoteProfileDatasurces!
          .editClientAddress(addressToUpdate, clientId));
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>?> updateInfo(
      String idToUpdate,
      Map<String, dynamic> adminInfoToUpdate,
      Map<String, dynamic> updatedSubtype) async {
    try {
      return Right(await remoteProfileDatasurces!
          .updateInfo(idToUpdate, adminInfoToUpdate, updatedSubtype));
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<void> deleteUser(BuildContext context, String keyUserDelete) async {
    try {
      await remoteProfileDatasurces!.deleteUser(context, keyUserDelete);
    } catch (e) {
      ServerFailure(errorMessage: '$e');
    }
  }

  @override
  Future<Either<Failure, List<Activity>>> getActivities() {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, bool>?> addNewUser(
      BuildContext context, String idClient) async {
    try {
      return Right(
          await remoteProfileDatasurces!.addNewUser(context, idClient));
    } catch (e) {
      return Left(ServerFailure(errorMessage: '$e'));
    }
  }

  @override
  Future<void> disableUser(String userId, bool isEnabled) async {
    try {
      await remoteProfileDatasurces!.disableUser(userId, isEnabled);
    } catch (e) {
      if (kDebugMode) {
        print('profileRepositoryImpl, disableUser Error: $e ');
      }
    }
  }
}
