import 'package:dartz/dartz.dart';
import 'package:flutter/cupertino.dart';
import 'package:huts_web/core/errors/failures.dart';
import 'package:huts_web/features/general_info/domain/entities/general_info_entity.dart';
import 'package:huts_web/features/general_info/domain/entities/other_info_entity.dart';

abstract class GeneralInfoRepository {
  Future<Either<Failure, GeneralInfo?>> getGeneralInfo(BuildContext context);
  Future<Either<Failure, OtherInfo?>> getOtherInfo(BuildContext context);
}
