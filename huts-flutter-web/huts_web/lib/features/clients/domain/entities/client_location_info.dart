import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_geocoding/google_geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:huts_web/core/services/cr_districts.dart';
import 'package:huts_web/core/utils/ui/widgets/general/custom_dropdown.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/clients/display/provider/clients_provider.dart';
import 'package:huts_web/features/general_info/display/providers/general_info_provider.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/local_notification_service.dart';
import '../../../../core/utils/ui/ui_methods.dart';
import '../../../../core/utils/ui/ui_variables.dart';
import '../../../../core/utils/ui/widgets/general/button_progess_indicator.dart';
import 'package:geocoder2/geocoder2.dart';

class ClientLocationInfo extends StatefulWidget {
  final ClientsProvider clientsProvider;
  const ClientLocationInfo({Key? key, required this.clientsProvider})
      : super(key: key);

  @override
  State<ClientLocationInfo> createState() => _ClientLocationInfoState();
}

class _ClientLocationInfoState extends State<ClientLocationInfo> {
  bool isWidgetLoaded = false;

  late ScreenSize screenSize;
  GeneralInfoProvider? generalInfoProvider;
  ClientsProvider? clientProvider;

  late String newState;
  String? newCity;
  String? newDistrict;
  List<String> selectedStateCities = [];
  List<String> selectedCityDistricts = [];
  TextEditingController addressController = TextEditingController();
  GeoPoint coordinates = const GeoPoint(9.9355151, -84.2568766);
  bool isSearchingLocation = false;
  late GoogleMapController _mapController;
  bool mapMovementBySearch = false;

  @override
  void didChangeDependencies() {
    if (isWidgetLoaded) return;
    isWidgetLoaded = true;
    generalInfoProvider ??=
        Provider.of<GeneralInfoProvider>(context, listen: false);
    clientProvider ??= Provider.of<ClientsProvider>(context, listen: false);

    newState = widget.clientsProvider.selectedClient!.location.state;
    newCity = widget.clientsProvider.selectedClient!.location.city;
    newDistrict = widget.clientsProvider.selectedClient!.location.district;
    addressController.text =
        widget.clientsProvider.selectedClient!.location.address;

    coordinates = widget.clientsProvider.selectedClient!.location.position;

    getCities();
    getDistricts();
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    generalInfoProvider ??=
        Provider.of<GeneralInfoProvider>(context, listen: false);
    clientProvider ??= Provider.of<ClientsProvider>(context, listen: false);
    screenSize = generalInfoProvider!.screenSize;
    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Ubicación",
            style: TextStyle(
                color: Colors.black,
                fontSize: screenSize.width * 0.016,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 3),
          Text(
            "Información de ubicación del cliente",
            style: TextStyle(
              color: Colors.black54,
              fontSize: screenSize.width * 0.01,
            ),
          ),
          const SizedBox(height: 20),
          OverflowBar(
            alignment: MainAxisAlignment.spaceBetween,
            children: [
              buildTextContainer(
                label: "Provincia",
                child: CustomDropDown(
                  items: getStates(),
                  hintText: "Selecciona una opción",
                  onChange: (String newValue) {
                    setState(() {
                      newState = newValue;
                      getCities();
                      newCity = '';
                      newDistrict = '';
                    });
                  },
                  value: newState.isEmpty ? null : newState,
                ),
              ),
              buildTextContainer(
                label: "Cantón",
                child: CustomDropDown(
                  value: _getcityDropDownValue(),
                  items: selectedStateCities,
                  hintText: "Selecciona una opción",
                  onChange: (String newValue) async {
                    setState(() {
                      newCity = newValue;
                    });
                    await getDistricts();
                  },
                ),
              ),
              buildTextContainer(
                label: "Distrito",
                child: CustomDropDown(
                  value: _getDistrictDropDownValue(),
                  items: selectedCityDistricts,
                  hintText: "Selecciona una opción",
                  onChange: (String newValue) {
                    setState(() {
                      newDistrict = newValue;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          buildTextContainer(
            label: "Dirección",
            child: TextField(
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.only(bottom: 10),
                hintStyle: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                counter: const SizedBox(),
                suffix: (isSearchingLocation)
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: ButtonProgressIndicator(),
                      )
                    : InkWell(
                        onTap: () async {
                          if (addressController.text.isEmpty) {
                            LocalNotificationService.showSnackBar(
                              type: "fail",
                              message:
                                  "El campo de dirección no puede estar vacío",
                              icon: Icons.error_outline,
                            );
                            return;
                          }

                          setState(() {
                            isSearchingLocation = true;
                          });
                          GoogleGeocoding googleGeocoding = GoogleGeocoding(
                              'AIzaSyBRAS0G1rRYJtZoXQyYI7d09dtePZ3NwW4');
                          GeocodingResponse? response =
                              await googleGeocoding.geocoding.get(
                            "${widget.clientsProvider.selectedClient!.location.country},${addressController.text}",
                            [],
                          );

                          if (response == null || response.results == null) {
                            setState(() {
                              isSearchingLocation = false;
                            });
                            return;
                          }

                          GeocodingResult result = response.results![0];

                          bool validResult = true;

                          if (result.formattedAddress == null) {
                            validResult = false;
                          }

                          if (result.geometry == null) {
                            validResult = false;
                          }

                          if (result.geometry != null &&
                              result.geometry!.location == null) {
                            validResult = false;
                          }

                          if (!validResult) {
                            setState(() {
                              isSearchingLocation = false;
                            });
                            return;
                          }

                          coordinates = GeoPoint(
                            result.geometry!.location!.lat!,
                            result.geometry!.location!.lng!,
                          );

                          isSearchingLocation = false;
                          mapMovementBySearch = true;

                          _updateMapCamera();
                          setState(() {});
                        },
                        child: Text(
                          "Buscar",
                          style: TextStyle(
                            color: UiVariables.primaryColor,
                            fontSize: screenSize.blockWidth >= 920 ? 14 : 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
              controller: addressController,
            ),
          ),
          const SizedBox(height: 30),
          buildMap(),
          buildUpdateBtn()
        ],
      ),
    );
  }

  Column buildTextContainer({
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey,
            fontSize: screenSize.blockWidth >= 920 ? 15 : 12,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          margin: const EdgeInsets.only(top: 10, right: 10),
          width: screenSize.blockWidth >= 920
              ? screenSize.blockWidth * 0.24
              : screenSize.width,
          height: screenSize.blockWidth >= 920
              ? screenSize.height * 0.055
              : screenSize.height * 0.035,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [
              BoxShadow(
                offset: Offset(0, 2),
                color: Colors.black26,
                blurRadius: 2,
              )
            ],
          ),
          child: child,
        ),
      ],
    );
  }

  List<String> getStates() {
    List<String> resultList = [];

    List<Map<String, dynamic>> data =
        generalInfoProvider!.generalInfo.countryInfo.statesCities;

    for (Map<String, dynamic> stateMap in data) {
      stateMap.forEach(
        (key, value) {
          if (key == "state") {
            resultList.add(stateMap[key]);
          }
        },
      );
    }
    return resultList;
  }

  void getCities() {
    int index = generalInfoProvider!.generalInfo.countryInfo.statesCities
        .indexWhere((element) => element["state"] == newState);
    if (index == -1) {
      selectedStateCities = [];
      return;
    }
    Map<String, dynamic> map =
        generalInfoProvider!.generalInfo.countryInfo.statesCities[index];
    selectedStateCities = [...map["cities"]];
  }

  Future<void> getDistricts() async {
    String stateId = (generalInfoProvider!.generalInfo.countryInfo.statesCities
                .indexWhere((element) => element["state"] == newState) +
            1)
        .toString();

    String cityId =
        (selectedStateCities.indexWhere((element) => element == newCity) + 1)
            .toString();

    selectedCityDistricts = [...await CrDistricts.get(stateId, cityId)];

    if (mounted) {
      setState(() {});
    }
  }

  SizedBox buildMap() {
    return SizedBox(
      width: double.infinity,
      height: screenSize.height * 0.45,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            GoogleMap(
              onMapCreated: _onMapCreated,
              compassEnabled: false,
              mapToolbarEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              tiltGesturesEnabled: false,
              initialCameraPosition: CameraPosition(
                zoom: 18,
                target: LatLng(
                  coordinates.latitude,
                  coordinates.longitude,
                ),
              ),
              onCameraMove: (CameraPosition newPosition) {
                if (!widget.clientsProvider.isMovingMapCamera) {
                  widget.clientsProvider.setMovingMapCameraValue();
                }

                coordinates = GeoPoint(
                  newPosition.target.latitude,
                  newPosition.target.longitude,
                );
              },
              onCameraIdle: () async {
                await _getAddressByMap();
                widget.clientsProvider.setMovingMapCameraValue();
                mapMovementBySearch = false;
              },
            ),
            Center(
              child: Icon(
                Icons.location_on_sharp,
                color: UiVariables.primaryColor,
                size: 40,
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _getAddressByMap() async {
    GeoData newDirection = await Geocoder2.getDataFromCoordinates(
      latitude: coordinates.latitude,
      longitude: coordinates.longitude,
      googleMapApiKey: "AIzaSyBRAS0G1rRYJtZoXQyYI7d09dtePZ3NwW4",
      language: 'es_CR',
    );
    if (mapMovementBySearch) {
      newDirection.address = addressController.text;
    } else {
      addressController.text = newDirection.address;
    }
  }

  Align buildUpdateBtn() {
    return Align(
      alignment: screenSize.blockWidth > 920
          ? Alignment.centerRight
          : Alignment.center,
      child: InkWell(
        onTap: () async =>
            (widget.clientsProvider.isLoading) ? null : await validateFields(),
        child: Container(
          margin: const EdgeInsets.only(top: 30),
          width:
              screenSize.blockWidth > 1194 ? screenSize.blockWidth * 0.1 : 150,
          height: screenSize.blockWidth > 920
              ? screenSize.height * 0.055
              : screenSize.height * 0.035,
          decoration: BoxDecoration(
            color: UiVariables.primaryColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              "Guardar cambios",
              style: TextStyle(
                color: Colors.white,
                fontSize: screenSize.blockWidth >= 920 ? 15 : 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _updateMapCamera() {
    _mapController.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(coordinates.latitude, coordinates.longitude),
        18,
      ),
    );
  }

  Future<void> validateFields() async {
    if (newCity == null ||
        newCity == '' ||
        newDistrict == null ||
        newDistrict == '' ||
        newState == '') {
      LocalNotificationService.showSnackBar(
        type: "fail",
        message: "Debes llenar todos los campos",
        icon: Icons.error_outline,
      );
      return;
    } else {
      if (mounted) {
        UiMethods().showLoadingDialog(context: context);
      }
      await clientProvider!.updateClientInfo(
        {
          "state": newState,
          "city": newCity,
          "address": addressController.text,
          "position": coordinates,
          "district": newDistrict,
        },
        "location",
        true,
      );
      if (mounted) {
        UiMethods().hideLoadingDialog(context: context);
      }
    }
  }

  String? _getcityDropDownValue() {
    String? finalValue = newCity != null
        ? newCity!.isEmpty
            ? null
            : newCity
        : newCity;

    return selectedStateCities.contains(finalValue) ? finalValue : null;
  }

  String? _getDistrictDropDownValue() {
    String? finalValue = newDistrict != null
        ? newDistrict!.isEmpty
            ? null
            : newDistrict
        : newDistrict;

    return selectedCityDistricts.contains(finalValue) ? finalValue : null;
  }
}
