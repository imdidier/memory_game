import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_geocoding/google_geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_web/google_maps_flutter_web.dart' as web;
import 'package:huts_web/core/services/local_notification_service.dart';
import 'package:huts_web/features/auth/domain/entities/web_user_entity.dart';
import 'package:huts_web/features/general_info/display/providers/general_info_provider.dart';
import 'package:provider/provider.dart';

class MapProvider with ChangeNotifier {
  GoogleMapController? mapController;
  TextEditingController addressController = TextEditingController();
  GeoPoint? updateCoordinatesGeoPoint;
  LatLng? updateCoordinates;
  LatLon? coordinatesToReverse;
  web.GoogleMapsPlugin plug = web.GoogleMapsPlugin();
  GoogleGeocoding geocoding =
      GoogleGeocoding('AIzaSyBRAS0G1rRYJtZoXQyYI7d09dtePZ3NwW4');
  List<GeocodingResult> geocodingResult = [];
  List<GeocodingResult> reverseGeocodingResult = [];
  bool isSearching = false;
  List<Component> component = [];

  void onMapCreated(
      GoogleMapController controller, BuildContext context, GeoPoint position) {
    mapController = controller;
    moveToInitialLocation(context, position);
  }

  Future<void> moveToInitialLocation(
      BuildContext context, GeoPoint clientPosition) async {
    try {
      GeneralInfoProvider generalInfoProvider =
          Provider.of<GeneralInfoProvider>(context, listen: false);

      Position? currentPosition;
      currentPosition ??=
          await Geolocator.getCurrentPosition().catchError((onError) {
        Position defaultPosition = Position(
            longitude: generalInfoProvider
                .generalInfo.countryInfo.defaultLocation.longitude,
            latitude: generalInfoProvider
                .generalInfo.countryInfo.defaultLocation.latitude,
            timestamp: DateTime.now(),
            accuracy: 10,
            altitude: 10,
            heading: 10,
            speed: 10,
            speedAccuracy: 10);
        return defaultPosition;
      });
      LatLng coordinatesPosition = LatLng(
        clientPosition.latitude,
        clientPosition.longitude,
      );
      log('posicion del cliente $coordinatesPosition');
      await mapController!.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: coordinatesPosition, zoom: 20),
        ),
      );

      notifyListeners();
    } catch (e) {
      log('error mapProvider, moveMapToCenter: $e');
    }
  }

  Future<void> updateAddressByMap(BuildContext context, WebUser user) async {
    try {
      // isSearching = true;

      var res = await geocoding.geocoding.getReverse(coordinatesToReverse!);
      if (res != null && res.results != null) {
        reverseGeocodingResult = res.results!;

        addressController.text = reverseGeocodingResult[0].formattedAddress!;
      } else {
        reverseGeocodingResult = [];
      }
    } catch (e) {
      log('mapProvider updateAddresByMap error $e');
    }
    notifyListeners();
  }

  Future<void> updateAddressbyText(BuildContext context, String clientAddress,
      String userCity, String userState) async {
    try {
      var result = await geocoding.geocoding
          .get('$clientAddress, $userState, $userCity', component);
      if (result != null && result.results != null) {
        geocodingResult = result.results!;
        updateCoordinates = LatLng(geocodingResult[0].geometry!.location!.lat!,
            geocodingResult[0].geometry!.location!.lng!);
        updateCoordinatesGeoPoint =
            GeoPoint(updateCoordinates!.latitude, updateCoordinates!.longitude);
        await mapController!.moveCamera(CameraUpdate.newCameraPosition(
            CameraPosition(target: updateCoordinates!, zoom: 24)));
        addressController.text = geocodingResult[0].formattedAddress!;
      }
      notifyListeners();
    } catch (e) {
      log('MapProvider updateAddressbyText error: $e');
    }
  }

  Future<void> enterToUpdate(WebUser user) async {
    try {
      updateCoordinates = LatLng(geocodingResult[0].geometry!.location!.lat!,
          geocodingResult[0].geometry!.location!.lng!);
      updateCoordinatesGeoPoint =
          GeoPoint(updateCoordinates!.latitude, updateCoordinates!.longitude);
      log('nueva ubicación $updateCoordinates');
      if (geocodingResult[0].geometry != null) {
        await mapController!.moveCamera(CameraUpdate.newCameraPosition(
            CameraPosition(target: updateCoordinates!, zoom: 24)));

        addressController.text = geocodingResult[0].formattedAddress!;
      }
    } catch (e) {
      log('MapProvider updateMarkers error: $e');

      LocalNotificationService.showSnackBar(
          type: 'Error',
          message:
              'No se ha encontrado la dirección puedes mover el cursor para seleccionar un lugar',
          icon: Icons.error_outline);
      isSearching = true;
    }
    notifyListeners();
  }

  void cameraIdle() {
    isSearching = false;
    notifyListeners();
  }
}
