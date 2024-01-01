import 'package:dartz/dartz.dart';
import 'package:flutter/cupertino.dart';
import 'package:huts_web/core/errors/failures.dart';
import 'package:huts_web/features/general_info/domain/entities/general_info_entity.dart';
import 'package:huts_web/features/general_info/domain/entities/other_info_entity.dart';
import 'package:huts_web/features/general_info/domain/repositories/general_info_repository.dart';

class GetGeneralInfo {
  final GeneralInfoRepository generalInfoRepository;
  GetGeneralInfo(this.generalInfoRepository);

  Future<Either<Failure, GeneralInfo?>> getGeneralInfo(
          BuildContext context) async =>
      await generalInfoRepository.getGeneralInfo(context);

  Future<Either<Failure, OtherInfo?>> getOtherInfo(
          BuildContext context) async =>
      generalInfoRepository.getOtherInfo(context);
}
