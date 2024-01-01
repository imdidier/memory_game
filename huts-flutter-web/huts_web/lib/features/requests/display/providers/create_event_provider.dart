import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoder2/geocoder2.dart';
import 'package:google_geocoding/google_geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:huts_web/core/firebase_config/firebase_services.dart';
import 'package:huts_web/core/services/fares/job_fare_service.dart';
import 'package:huts_web/core/services/local_notification_service.dart';
import 'package:huts_web/core/utils/code/code_utils.dart';
import 'package:huts_web/features/auth/domain/entities/web_user_entity.dart';
import 'package:huts_web/features/clients/domain/entities/client_entity.dart';
import 'package:huts_web/features/general_info/domain/entities/country_info_entity.dart';
import 'package:huts_web/features/requests/data/datasources/admin/admin_requests_remote_datasource.dart';
import 'package:huts_web/features/requests/data/datasources/reomote/create_event_datasource.dart';
import 'package:huts_web/features/requests/data/models/event_model.dart';
import 'package:huts_web/features/requests/data/repositories/admin/requests_repository_impl.dart';
import 'package:huts_web/features/requests/data/repositories/event_repository_impl.dart';
import 'package:huts_web/features/requests/domain/entities/event_entity.dart';
import 'package:huts_web/features/requests/domain/use_cases/admin/admin_add_requests.dart';
import 'package:huts_web/features/requests/domain/use_cases/client/create_event.dart';
import 'package:huts_web/features/requests/domain/use_cases/client/create_requests.dart';

import '../../../../core/services/navigation_service.dart';
import '../../../auth/domain/entities/company.dart';
import '../../../auth/domain/entities/screen_size_entity.dart';
import '../../domain/entities/request_entity.dart';
import '../screens/widgets/create_event_dialog.dart';

class CreateEventProvider with ChangeNotifier {
  bool isShowingDialog = false;
  bool isAddingJob = false;
  String? currentJob;
  DateTime? currentStartDate;
  DateTime? currentEndDate;
  bool useSavedAddress = true;
  bool isShowingDateTimePicker = false;
  List<JobRequest> jobsRequests = [];
  ScrollController scrollController = ScrollController();

  //Google geocoding variables//
  TextEditingController addressController = TextEditingController();
  bool isSearchingLocation = false;
  GoogleGeocoding googleGeocoding =
      GoogleGeocoding('AIzaSyBRAS0G1rRYJtZoXQyYI7d09dtePZ3NwW4');
  List<Component> components = [];
  List<GeocodingResult> geocodingResults = [];
  final String _apiKey = 'AIzaSyBRAS0G1rRYJtZoXQyYI7d09dtePZ3NwW4';
  LatLng? newCoordinates;
  GoogleMapController? mapController;
  late LatLng eventCoordinates;
  Set<Marker> mapMarkers = {};
  late EventModel currentEventRequest;
  bool isFromCenter = false;
  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    updateMapCamera();
  }

  void updateDialogStatus(bool newValue, ScreenSize screenSize, Event? event) {
    if (!newValue) {
      currentJob = null;
      currentStartDate = null;
      currentEndDate = null;
      useSavedAddress = true;
      isShowingDateTimePicker = false;
      jobsRequests = [];
    }
    isAddingJob = false;
    currentEventRequest = EventModel.emptyEvent();

    BuildContext? globalContext = NavigationService.getGlobalContext();
    if (globalContext == null) return;

    if (newValue) {
      showCreateEventDialog(globalContext, screenSize, event);
      return;
    }
    Navigator.of(globalContext).pop();
    return;
  }

  void showCreateEventDialog(
      BuildContext globalContext, ScreenSize screenSize, Event? event) {
    showDialog(
        context: globalContext,
        barrierDismissible: false,
        builder: (BuildContext dialogCtx) {
          return WillPopScope(
            child: AlertDialog(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(15)),
              ),
              titlePadding: const EdgeInsets.all(0),
              title: CreateEventDialog(
                screenSize: screenSize,
                event: event,
              ),
            ),
            onWillPop: () async => false,
          );
        });
  }

  void updateSavedAddressStatus(
      bool? newValue, Map<String, dynamic> companyLocation) {
    useSavedAddress = newValue ?? true;
    if (useSavedAddress) {
      addressController.text = companyLocation["address"];
      eventCoordinates = LatLng(
        companyLocation['position'].latitude,
        companyLocation['position'].longitude,
      );
    }
    notifyListeners();
  }

  void clearJobsRequests() {
    jobsRequests.clear();
    currentEventRequest = EventModel.emptyEvent();
    notifyListeners();
  }

  void deleteJobRequest(String job) {
    int index =
        jobsRequests.indexWhere((element) => element.job["name"] == job);
    JobRequest request = jobsRequests[index];
    currentEventRequest.employeesInfo.neededEmployees -=
        request.employeesNumber;
    currentEventRequest.details.totalHours -= request.totalHours;
    currentEventRequest.details.fare.totalClientPays -=
        request.totalToPayClient;

    currentEventRequest.details.fare.totalToPayEmployees -=
        request.totalToPayEmployee * request.employeeHours;

    jobsRequests.removeAt(index);
    notifyListeners();
  }

  void updateCurrentDate({
    required bool isFromStart,
    required DateTime newDate,
  }) {
    if (isFromStart) currentStartDate = newDate;
    if (!isFromStart) currentEndDate = newDate;
    notifyListeners();
  }

  void updateCurrentJob(String? newValue) {
    currentJob = newValue;
    notifyListeners();
  }

  void showHideDateTimePicker(bool newValue) {
    isShowingDateTimePicker = newValue;
    notifyListeners();
  }

  Future<bool> updateNameEvent(String eventId, String nameEvent) async {
    EventRepositoryImpl repository =
        EventRepositoryImpl(CreateEventDatasourceImpl());
    bool resp = await repository.updateNameEvent(eventId, nameEvent);
    notifyListeners();
    return resp;
  }

  Future<bool> deleteEvent(EventModel event, List<Request> requests) async {
    EventRepositoryImpl repository =
        EventRepositoryImpl(CreateEventDatasourceImpl());
    return await repository.deleteEvent(event, requests);
  }

  Future<void> getLocationByAddress(String country) async {
    isSearchingLocation = true;
    notifyListeners();
    GeocodingResponse? response = await googleGeocoding.geocoding.get(
      "$country,${addressController.text}",
      components,
    );
    if (response == null || response.results == null) {
      isSearchingLocation = false;
      notifyListeners();
      return;
    }
    geocodingResults = [...response.results!];

    GeocodingResult result = geocodingResults[0];

    if (result.formattedAddress == null ||
        result.geometry == null ||
        (result.geometry != null && result.geometry!.location == null)) {
      isSearchingLocation = false;
      notifyListeners();
      return;
    }

    eventCoordinates = LatLng(
      result.geometry!.location!.lat!,
      result.geometry!.location!.lng!,
    );
    addressController.text = result.formattedAddress!;

    mapMarkers
        .removeWhere((element) => element.markerId.value == "current_location");

    mapMarkers.add(
      Marker(
          markerId: const MarkerId("current_location"),
          position: eventCoordinates),
    );

    mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(eventCoordinates, 18),
    );

    isSearchingLocation = false;

    notifyListeners();
  }

  void showEmptyFieldsNotification() {
    LocalNotificationService.showSnackBar(
      type: "fail",
      message: "Debes completar la información",
      icon: Icons.error_outline,
    );
  }

  void updateAddressText(BuildContext context) async {
    try {
      if (!isFromCenter) {
        await getAddressByMap(context);
      } else {
        isFromCenter = false;
      }
    } catch (e) {
      log('Error MapProvider, updateAddressText $e');
    }
  }

  Future<void> addJobRequest(
    WebUser webUser,
    String employeesCount,
    String eventName,
    String indications,
    String references,
    CountryInfo countryInfo,
    ClientEntity? clientEntity,
    bool forClient,
  ) async {
    if (currentJob == null ||
        currentStartDate == null ||
        currentEndDate == null) {
      showEmptyFieldsNotification();
      return;
    }
    if (employeesCount.isEmpty || eventName.isEmpty || indications.isEmpty) {
      showEmptyFieldsNotification();
      return;
    }

    int employeesNeeded = int.parse(employeesCount);

    if (currentEventRequest.employeesInfo.neededEmployees + employeesNeeded >
        500) {
      LocalNotificationService.showSnackBar(
        type: "fail",
        message: "No puedes realizar más de 500 solicitudes en un evento",
        icon: Icons.error_outline,
        duration: 5,
      );
      return;
    }

    isAddingJob = true;
    notifyListeners();

    double jobHours = CodeUtils.minutesToHours(
      currentEndDate!.difference(currentStartDate!).inMinutes,
    );

    Job selectedJob;

    if (clientEntity != null) {
      Map<String, dynamic> jobMap = clientEntity.jobs.values
          .firstWhere((element) => element["name"] == currentJob);

      selectedJob = Job(
        name: jobMap["name"],
        value: jobMap["value"],
        fares: jobMap["fares"],
      );
    } else {
      selectedJob = webUser.company.jobs.firstWhere(
        (element) => element.name == currentJob,
      );
    }

    if (jobsRequests.isEmpty && !forClient) {
      currentEventRequest.id =
          FirebaseServices.db.collection("events").doc().id;
    }
    JobRequest? newJobRequest = JobRequest(
      clientInfo: (clientEntity != null)
          ? {
              "id": clientEntity.accountInfo.id,
              "image": clientEntity.imageUrl,
              "name": clientEntity.name,
              "country": clientEntity.location.country,
            }
          : {
              "id": webUser.company.id,
              "image": webUser.company.image,
              "name": webUser.company.name,
              "country": webUser.company.country,
            },
      eventId: currentEventRequest.id,
      eventName: eventName,
      startDate: currentStartDate!,
      endDate: currentEndDate!,
      location: {
        "address": addressController.text,
        "position": GeoPoint(
          eventCoordinates.latitude,
          eventCoordinates.longitude,
        ),
      },
      fareType: "",
      job: {
        "name": currentJob!,
        "value": selectedJob.value,
      },
      employeeHours: jobHours,
      totalHours: employeesNeeded * jobHours,
      employeeFare: JobRequestFare(
        holidayFare: {},
        normalFare: {},
        dynamicFare: {},
      ),
      clientFare: JobRequestFare(
        holidayFare: {},
        normalFare: {},
        dynamicFare: {},
      ),
      totalToPayEmployee: 0,
      totalToPayAllEmployees: 0,
      totalToPayClient: 0,
      totalToPayClientPerEmployee: 0,
      totalClientNightSurcharge: 0,
      totalEmployeeNightSurcharge: 0,
      employeesNumber: employeesNeeded,
      indications: indications,
      references: references,
    );
    newJobRequest = await JobFareService.get(
      selectedJob,
      newJobRequest,
      currentStartDate!,
      currentEndDate!,
      (clientEntity != null)
          ? clientEntity.accountInfo.hasDynamicFare
          : webUser.company.accountInfo["has_dynamic_fare"],
      (clientEntity != null) ? clientEntity.accountInfo.id : webUser.company.id,
      countryInfo,
    );

    if (jobsRequests.isEmpty) {
      currentEventRequest.eventName = eventName;
      currentEventRequest.clientInfo = (clientEntity != null)
          ? EventClientInfo(
              clientEntity.accountInfo.id,
              clientEntity.imageUrl,
              clientEntity.name,
              clientEntity.location.country,
            )
          : EventClientInfo(
              webUser.company.id,
              webUser.company.image,
              webUser.company.name,
              webUser.company.country,
            );
      currentEventRequest.details.location = newJobRequest.location;
      currentEventRequest.details.startDate = currentStartDate!;
      currentEventRequest.details.status = 1;
      currentEventRequest.year = currentStartDate!.year;
      currentEventRequest.month = currentStartDate!.month;
      currentEventRequest.weekCut =
          CodeUtils().getCutOffWeek(currentStartDate!);
      currentEventRequest.startWeek =
          "${currentStartDate!.year}-${CodeUtils.getFormatStringNum(currentStartDate!.month)}-${CodeUtils.getFormatStringNum(currentStartDate!.day)}";
    }
    currentEventRequest.employeesInfo.neededEmployees +=
        newJobRequest.employeesNumber;
    currentEventRequest.details.totalHours += newJobRequest.totalHours;
    currentEventRequest.details.fare.totalClientPays +=
        newJobRequest.totalToPayClient;
    currentEventRequest.details.fare.totalToPayEmployees +=
        newJobRequest.totalToPayAllEmployees;

    jobsRequests.add(newJobRequest);

    scrollController.animateTo(
      0.0,
      curve: Curves.linear,
      duration: const Duration(milliseconds: 400),
    );
    isAddingJob = false;

    notifyListeners();
  }

  Future<void> createEvent(ScreenSize screenSize, bool isAdmin) async {
    jobsRequests.sort((a, b) {
      return a.endDate.compareTo(b.endDate);
    });

    currentEventRequest.details.endDate =
        jobsRequests[jobsRequests.length - 1].endDate;

    currentEventRequest.endWeek =
        "${currentEventRequest.details.endDate.year}-${CodeUtils.getFormatStringNum(currentEventRequest.details.endDate.month)}-${CodeUtils.getFormatStringNum(currentEventRequest.details.endDate.day)}";

    for (JobRequest item in jobsRequests) {
      if (currentEventRequest.employeesInfo.neededJobs
          .containsKey(item.job["value"])) {
        currentEventRequest.employeesInfo.neededJobs[item.job["value"]]
            ["employees"] += item.employeesNumber;
        currentEventRequest.employeesInfo.neededJobs[item.job["value"]]
            ["total_hours"] += item.totalHours;
      } else {
        currentEventRequest.employeesInfo.neededJobs[item.job["value"]] = {
          "employees": item.employeesNumber,
          "total_hours": item.totalHours,
          "name": item.job["name"],
          "value": item.job["value"],
        };
      }
    }

    EventRepositoryImpl repository = EventRepositoryImpl(
      CreateEventDatasourceImpl(),
    );

    String eventCreationResp = await CreateEvent(repository)
        .call(event: currentEventRequest, isAdmin: isAdmin);

    if (eventCreationResp == "fail") {
      LocalNotificationService.showSnackBar(
        type: "fail",
        message: "No se pudo crear el evento, intenta nuevamente",
        icon: Icons.error_outline_outlined,
      );
      return;
    }

    if (eventCreationResp == "created") {
      bool requestsCreated =
          await CreateRequests(repository).call(jobsRequests: jobsRequests);

      if (!requestsCreated) {
        LocalNotificationService.showSnackBar(
          type: "fail",
          message: "No se pudieron crear las solicitudes, intenta nuevamente",
          icon: Icons.error_outline_outlined,
        );
        return;
      }

      updateDialogStatus(false, screenSize, null);
      LocalNotificationService.showSnackBar(
        type: "success",
        message: "Evento creado correctamente",
        icon: Icons.check,
      );

      return;
    }

    //When is the event already exists//

    AdminRequestsRepositoryImpl adminRequestsRepository =
        AdminRequestsRepositoryImpl(
      AdminRequestsRemoteDatasourceImpl(),
    );

    bool requestsAdded = await AdminAddRequests(adminRequestsRepository).call(
      jobsRequests: jobsRequests,
      eventId: eventCreationResp,
    );

    if (!requestsAdded) {
      LocalNotificationService.showSnackBar(
        type: "fail",
        message: "No se pudieron agregar las solicitudes, intenta nuevamente",
        icon: Icons.error_outline_outlined,
      );
      return;
    }

    updateDialogStatus(false, screenSize, null);
    LocalNotificationService.showSnackBar(
      type: "success",
      message: "Solicitudes agregadas correctamente",
      icon: Icons.check,
    );
  }

  EventRquest getInitialEventRequest() {
    return EventRquest(
      clientInfo: {},
      details: {},
      employeesInfo: {},
      eventNumber: "",
      year: 0,
      month: 0,
      weekStart: "",
      weekEnd: "",
      weekCut: "",
    );
  }

  void updateMapCamera() {
    mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(eventCoordinates, 18),
    );
  }

  Future<void> getAddressByMap(BuildContext context) async {
    try {
      if (useSavedAddress) return;
      GeoData newDirection = await Geocoder2.getDataFromCoordinates(
        latitude: newCoordinates!.latitude,
        longitude: newCoordinates!.longitude,
        googleMapApiKey: _apiKey,
        language: 'es_CR',
      );

      eventCoordinates = LatLng(
        newCoordinates!.latitude,
        newCoordinates!.longitude,
      );
      addressController.text = newDirection.address;
      mapMarkers.removeWhere(
          (element) => element.markerId.value == "current_location");
      mapMarkers.add(
        Marker(
            markerId: const MarkerId("current_location"),
            position: eventCoordinates),
      );
      isSearchingLocation = false;
      notifyListeners();
    } catch (e) {
      log('Error CrezateEventProvider, getAddressByMap: $e');
    }
  }
}

class JobRequest {
  Map<String, dynamic> clientInfo;
  String eventId;
  String eventName;
  DateTime startDate;
  DateTime endDate;
  Map<String, dynamic> location;
  String fareType;
  Map<String, dynamic> job;
  double employeeHours;
  double totalHours;
  JobRequestFare employeeFare;
  JobRequestFare clientFare;
  double totalToPayEmployee;
  double totalToPayAllEmployees;
  double totalToPayClient;
  double totalToPayClientPerEmployee;
  double totalClientNightSurcharge;
  double totalEmployeeNightSurcharge;
  int employeesNumber;
  String indications;
  String references;

  JobRequest({
    required this.clientInfo,
    required this.eventId,
    required this.eventName,
    required this.startDate,
    required this.endDate,
    required this.location,
    required this.fareType,
    required this.job,
    required this.employeeHours,
    required this.totalHours,
    required this.employeeFare,
    required this.clientFare,
    required this.totalToPayEmployee,
    required this.totalToPayClient,
    required this.totalToPayClientPerEmployee,
    required this.totalClientNightSurcharge,
    required this.totalEmployeeNightSurcharge,
    required this.employeesNumber,
    required this.totalToPayAllEmployees,
    required this.indications,
    required this.references,
  });
}

class JobRequestFare {
  Map<String, dynamic> holidayFare;
  Map<String, dynamic> normalFare;
  Map<String, dynamic> dynamicFare;

  JobRequestFare({
    required this.holidayFare,
    required this.normalFare,
    required this.dynamicFare,
  });

  Map<String, dynamic> toMap() {
    return {
      'holiday': holidayFare,
      'normal': normalFare,
      'dynamic': dynamicFare,
    };
  }
}

class EventRquest {
  Map<String, dynamic> clientInfo;
  Map<String, dynamic> details;
  Map<String, dynamic> employeesInfo;
  String eventNumber;
  int year;
  int month;
  String weekStart;
  String weekEnd;
  String weekCut;

  // double totalHours;
  // int totalEmployees;
  // double totalToPayClient;

  EventRquest({
    required this.clientInfo,
    required this.details,
    required this.employeesInfo,
    required this.eventNumber,
    required this.year,
    required this.month,
    required this.weekStart,
    required this.weekEnd,
    required this.weekCut,
    // required this.totalHours,
    // required this.totalEmployees,
    // required this.totalToPayClient,
  });
}
