import 'package:flutter/cupertino.dart';
import 'package:huts_web/core/errors/exceptions.dart';
import 'package:huts_web/features/general_info/data/datasources/general_info_remote_datasource.dart';
import 'package:huts_web/features/general_info/domain/entities/other_info_entity.dart';
import 'package:huts_web/features/general_info/domain/entities/general_info_entity.dart';
import 'package:huts_web/core/errors/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:huts_web/features/general_info/domain/repositories/general_info_repository.dart';

class GeneralInfoRepositoryImpl implements GeneralInfoRepository {
  final GeneralInfoRemoteDataSource remoteDataSource;

  GeneralInfoRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, GeneralInfo?>> getGeneralInfo(
      BuildContext context) async {
    try {
      return Right(await remoteDataSource.getGeneralInfo(context));
    } on ServerException catch (e) {
      return Left(ServerFailure(errorMessage: e.message));
    }
  }

  @override
  Future<Either<Failure, OtherInfo?>> getOtherInfo(BuildContext context) async {
    try {
      return Right(await remoteDataSource.getOtherInfo(context));
    } on ServerException catch (e) {
      return Left(ServerFailure(errorMessage: e.message));
    }
  }
}
