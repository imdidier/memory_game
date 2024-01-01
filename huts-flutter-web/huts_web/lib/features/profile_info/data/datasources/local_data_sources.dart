import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:huts_web/features/profile_info/data/models/state_country.dart';
import 'dart:convert' as convert;

abstract class ProfileLocalDataSources {
  Future<List<StateCountryModel>?> getCountries(
      BuildContext context, String countryPrefix);
}

class ProfileLocalDataSourcesImpl implements ProfileLocalDataSources {
  @override
  Future<List<StateCountryModel>?> getCountries(
      BuildContext context, String countryPrefix) async {
    try {
      List<StateCountryModel> resultStateList = [];
      countryPrefix = countryPrefix.toLowerCase();
      String data = await DefaultAssetBundle.of(context)
          .loadString('assets/${countryPrefix}_data.json');
      final jsonResult = convert.json.decode(data) as List;

      String keyName = '';
      String keyCities = '';
      if (countryPrefix == 'col') {
        keyName = 'departamento';
        keyCities = 'ciudades';
      } else {
        keyName = 'Nombre';
        keyCities = 'Cantones';
      }

      for (var element in jsonResult) {
        Map<String, dynamic> stateMap = {
          'name': element[keyName],
          'cities': element[keyCities] as List,
        };
        resultStateList.add(StateCountryModel.fromMap(stateMap));
      }
      return resultStateList;
    } catch (e) {
      log('ProfileLocalDataSourceImpl, getCountry error: $e');
      return null;
    }
  }
}
