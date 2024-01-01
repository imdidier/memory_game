import 'package:dartz/dartz.dart';
import 'package:flutter/cupertino.dart';
import 'package:huts_web/core/errors/failures.dart';
import 'package:huts_web/features/profile_info/domain/entities/state_country.dart';
import 'package:huts_web/features/profile_info/domain/repositories/profile_repository.dart';

class GetCountries {
  final ProfileRepository repository;

  GetCountries(this.repository);

  Future<Either<Failure, List<StateCountry>?>> call(
      BuildContext context, String countryPrefix) async {
    return repository.getCountry(context, countryPrefix);
  }
}
