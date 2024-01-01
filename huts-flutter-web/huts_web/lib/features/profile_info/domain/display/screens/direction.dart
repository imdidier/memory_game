import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_geocoding/google_geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as maps;
import 'package:huts_web/features/auth/display/providers/auth_provider.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/profile_info/domain/display/providers/map_provider.dart';
import 'package:huts_web/features/profile_info/domain/display/providers/profile_provider.dart';
import 'package:provider/provider.dart';

import '../../../../../core/utils/ui/ui_variables.dart';
import '../../../../auth/domain/entities/web_user_entity.dart';

class DirectionScreen extends StatelessWidget {
  final ScreenSize size;
  final WebUser user;
  const DirectionScreen({Key? key, required this.size, required this.user})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    ProfileProvider profileProvider = Provider.of<ProfileProvider>(context);
    MapProvider mapProvider = Provider.of<MapProvider>(context);
    AuthProvider authProvider = Provider.of<AuthProvider>(context);
    TextEditingController pointReferenceController = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dirección',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: size.blockWidth >= 920 ? 16 : 12,
                  ),
                ),
                SizedBox(height: size.height * 0.01),
                Text(
                  'Actualiza la dirección',
                  style: TextStyle(
                    fontSize: size.blockWidth >= 920 ? 16 : 12,
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 0,
              left: 390,
              child: InkWell(
                onTap: () async {
                  await profileProvider.updateClientAddress(
                      user,
                      user.company.id,
                      mapProvider.addressController.text,
                      mapProvider.updateCoordinatesGeoPoint!);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  height: size.height * 0.045,
                  decoration: BoxDecoration(
                      color: UiVariables.primaryColor,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Center(
                      child: Text(
                    'Guardar Cambios',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w200),
                  )),
                ),
              ),
            ),
          ],
        ),
        const Divider(),
        SizedBox(height: size.height * 0.03),
        OverflowBar(
          alignment: MainAxisAlignment.spaceBetween,
          overflowSpacing: 10,
          children: [
            SizedBox(
              width: size.blockWidth >= 920
                  ? size.blockWidth * 0.3
                  : size.blockWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.profileInfo.countryPrefix == 'COL'
                        ? 'Departamento'
                        : 'Provincia',
                    style: TextStyle(
                      fontSize: size.blockWidth >= 920 ? 16 : 12,
                    ),
                  ),
                  Container(
                    height: size.height * 0.045,
                    margin: EdgeInsets.only(top: size.absoluteHeight * 0.02),
                    padding:
                        EdgeInsets.symmetric(horizontal: size.width * 0.01),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                            blurRadius: 3,
                            color: Colors.black12,
                            offset: Offset(0, 2))
                      ],
                    ),
                    child: profileProvider.dropdownButton(
                      context: context,
                      updateValue: profileProvider.clientState,
                      items: profileProvider.statesName,
                      hintText: user.company.location.isEmpty
                          ? user.company.country == 'Costa Rica'
                              ? 'Provincia'
                              : 'Departamento'
                          : user.company.location['state'],
                      onChange: (value) async {
                        profileProvider.clientState = value;
                        profileProvider.getCitiesStates();
                        profileProvider.newState = profileProvider.clientState!;
                        profileProvider.clientCity =
                            profileProvider.citiesName.first;
                        profileProvider.newCity = profileProvider.clientCity!;
                        await mapProvider.updateAddressbyText(
                          context,
                          'Provincia de ${profileProvider.clientState}',
                          profileProvider.newState,
                          profileProvider.newCity,
                        );
                      },
                      size: size,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: size.blockWidth >= 920
                  ? size.blockWidth * 0.3
                  : size.blockWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.profileInfo.countryPrefix == 'COL'
                        ? 'Ciudad'
                        : 'Cantón',
                    style: TextStyle(
                      fontSize: size.blockWidth >= 920 ? 16 : 12,
                    ),
                  ),
                  Container(
                    height: size.height * 0.045,
                    margin: EdgeInsets.only(top: size.absoluteHeight * 0.02),
                    padding:
                        EdgeInsets.symmetric(horizontal: size.width * 0.01),
                    decoration: const BoxDecoration(
                        color: Colors.white,
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                              blurRadius: 3,
                              color: Colors.black12,
                              offset: Offset(0, 2))
                        ]),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: profileProvider.dropdownButton(
                          context: context,
                          updateValue: profileProvider.clientCity,
                          items: profileProvider.citiesName,
                          hintText: user.company.location.isEmpty
                              ? user.company.country == 'Costa Rica'
                                  ? 'Cantón'
                                  : 'Ciudad'
                              : user.company.location['city'],
                          onChange: (String value) async {
                            profileProvider.clientCity = value;
                            profileProvider.newCity =
                                profileProvider.clientCity!;
                            await mapProvider.updateAddressbyText(
                              context,
                              'Provincia de ${profileProvider.clientState}',
                              profileProvider.newState,
                              profileProvider.newCity,
                            );
                          },
                          size: size),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
        SizedBox(height: size.height * 0.03),
        OverflowBar(
          alignment: MainAxisAlignment.spaceBetween,
          overflowSpacing: 10,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dirección',
                  style: TextStyle(
                    fontSize: size.blockWidth >= 920 ? 16 : 12,
                  ),
                ),
                Container(
                  width: size.blockWidth >= 920
                      ? size.blockWidth * 0.3
                      : size.blockWidth,
                  height: size.height * 0.045,
                  margin: EdgeInsets.only(top: size.absoluteHeight * 0.02),
                  padding: EdgeInsets.symmetric(horizontal: size.width * 0.01),
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                            blurRadius: 3,
                            color: Colors.black12,
                            offset: Offset(0, 2))
                      ]),
                  child: TextFormField(
                    controller: mapProvider.isSearching
                        ? mapProvider.addressController
                        : null,
                    onChanged: (value) async {
                      await mapProvider.updateAddressbyText(
                          context,
                          value,
                          profileProvider.clientState!,
                          profileProvider.clientCity!);
                    },
                    onEditingComplete: () async {
                      await mapProvider.enterToUpdate(user);
                    },
                    decoration: InputDecoration(
                        suffixIcon: const Icon(Icons.edit),
                        hintText: user.company.location.isNotEmpty
                            ? user.company.location['address']
                            : 'Direccion'),
                  ),
                )
              ],
            ),
            SizedBox(width: size.width * 0.06),
            // Column(
            //   crossAxisAlignment: CrossAxisAlignment.start,
            //   children: [
            //     Text(
            //       'Puntos de referencias',
            //       style: TextStyle(
            //         fontSize: size.blockWidth >= 920 ? 16 : 12,
            //       ),
            //     ),
            //     Container(
            //         width: size.blockWidth >= 920
            //             ? size.blockWidth * 0.3
            //             : size.blockWidth,
            //         height: size.height * 0.045,
            //         margin: EdgeInsets.only(top: size.absoluteHeight * 0.02),
            //         padding:
            //             EdgeInsets.symmetric(horizontal: size.width * 0.01),
            //         decoration: const BoxDecoration(
            //             color: Colors.white,
            //             boxShadow: <BoxShadow>[
            //               BoxShadow(
            //                   blurRadius: 3,
            //                   color: Colors.black12,
            //                   offset: Offset(0, 2))
            //             ]),
            //         child: TextFormField(
            //           controller: pointReferenceController,
            //           maxLines: 4,
            //         )),
            //   ],
            // ),
          ],
        ),
        SizedBox(height: size.height * 0.03),
        Container(
          height: size.height * 0.50,
          decoration: const BoxDecoration(),
          child: Stack(
            children: [
              SingleChildScrollView(
                child: SizedBox(
                  height: size.height * 0.50,
                  width: size.width * 0.80,
                  child: maps.GoogleMap(
                    onCameraMove: (maps.CameraPosition camerapos) async {
                      if (mapProvider.isSearching = true) {
                        mapProvider.coordinatesToReverse = LatLon(
                            camerapos.target.latitude,
                            camerapos.target.longitude);
                        await mapProvider.updateAddressByMap(context, user);
                        // log('${mapProvider.updateCoordinates}');
                      }
                    },
                    onCameraIdle: () async {
                      log(mapProvider.addressController.text);
                      mapProvider.cameraIdle();
                    },
                    onMapCreated: (controller) => mapProvider.onMapCreated(
                        controller,
                        context,
                        authProvider.webUser.company.location['position']),
                    initialCameraPosition: maps.CameraPosition(
                      target: maps.LatLng(
                          authProvider
                              .webUser.company.location['position'].latitude,
                          authProvider
                              .webUser.company.location['position'].longitude),
                      zoom: 18,
                    ),
                    compassEnabled: false,
                    mapToolbarEnabled: false,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    tiltGesturesEnabled: false,
                  ),
                ),
              ),
              SizedBox(width: size.width * 0.025),
              const Align(
                alignment: Alignment.center,
                child: Icon(
                  Icons.location_on,
                  size: 40,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
