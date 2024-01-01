import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huts_web/core/services/employee_services/employee_services.dart';
import 'package:huts_web/core/services/employee_services/widgets/employee_messages.dart';
import 'package:huts_web/core/services/employee_services/widgets/employee_requests.dart';
import 'package:huts_web/core/services/local_notification_service.dart';
import 'package:huts_web/core/use_cases_params/excel_params.dart';
import 'package:huts_web/core/utils/code/code_utils.dart';
import 'package:huts_web/core/utils/ui/ui_methods.dart';
import 'package:huts_web/core/utils/ui/widgets/general/data_table_from_responsive.dart';
import 'package:huts_web/core/utils/ui/widgets/general/export_to_excel_btn.dart';
import 'package:huts_web/features/employees/display/provider/employees_provider.dart';
import 'package:huts_web/features/employees/domain/entities/employee_entity.dart';
import 'package:huts_web/features/general_info/domain/entities/country_info_entity.dart';
import 'package:huts_web/features/messages/domain/entities/message_entity.dart';
import 'package:huts_web/features/pre_registered/display/provider/pre_registered_provider.dart';
import 'package:provider/provider.dart';
import '../../../../../features/activity/display/providers/activity_provider.dart';
import '../../../../../features/employees/display/widgets/change_phone_dialog.dart';
import '../../../../../features/requests/domain/entities/request_entity.dart';
import '../../../../services/employee_services/widgets/availability.dart';
import '../../../../services/employee_services/widgets/employee_activity.dart';
import '../../ui_variables.dart';
import '../../../../../features/auth/domain/entities/screen_size_entity.dart';
import '../../../../../features/general_info/display/providers/general_info_provider.dart';
import '../general/custom_search_bar.dart';

class EmployeeTabInfo extends StatefulWidget {
  final Map<String, dynamic> tabInfo;
  final Employee employee;
  final String newImage;
  const EmployeeTabInfo(
      {required this.employee,
      required this.tabInfo,
      required this.newImage,
      Key? key})
      : super(key: key);

  @override
  State<EmployeeTabInfo> createState() => _EmployeeTabInfoState();
}

class _EmployeeTabInfoState extends State<EmployeeTabInfo> {
  bool isWidgetLoaded = false;

  List<Map<String, dynamic>> allJobs = [];
  late CountryInfo countryInfo;

  @override
  void didChangeDependencies() {
    if (isWidgetLoaded) return;
    isWidgetLoaded = true;
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    ScreenSize screenSize =
        Provider.of<GeneralInfoProvider>(context).screenSize;

    if (widget.tabInfo["value"] == "jobs") {
      countryInfo = Provider.of<GeneralInfoProvider>(context, listen: false)
          .generalInfo
          .countryInfo;

      allJobs.clear();

      countryInfo.jobsFares.forEach((key, value) {
        allJobs.add({
          "name": value["name"],
          "value": key,
          "is_enabled": widget.employee.jobs.contains(key),
        });
      });
    }
    return Container(
      margin: const EdgeInsets.only(top: 15),
      width: double.infinity,
      decoration: UiVariables.boxDecoration,
      padding: const EdgeInsets.all(25),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.tabInfo["name"],
              style: TextStyle(
                color: Colors.black,
                fontSize: screenSize.width * 0.016,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              widget.tabInfo["text"],
              style: TextStyle(
                color: Colors.black54,
                fontSize: screenSize.width * 0.01,
              ),
            ),
            _TabContent(
              aditionalInfo: widget.tabInfo,
              type: widget.tabInfo["value"],
              employee: widget.employee,
              newImage: widget.newImage,
              jobs: (widget.tabInfo["value"] == "jobs") ? allJobs : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _TabContent extends StatefulWidget {
  final Map<String, dynamic> aditionalInfo;
  final String type;
  final Employee employee;
  final String newImage;
  final List<Map<String, dynamic>>? jobs;

  const _TabContent({
    required this.aditionalInfo,
    required this.type,
    required this.employee,
    required this.newImage,
    this.jobs,
    Key? key,
  }) : super(key: key);

  @override
  State<_TabContent> createState() => _TabContentState();
}

class _TabContentState extends State<_TabContent> {
  late ScreenSize _screenSize;
  late EmployeesProvider _employeesProvider;
  late PreRegisteredProvider _preRegisteredProvider;
  late ActivityProvider activityProvider;

  final TextEditingController _searchMessageController =
      TextEditingController();

  TextEditingController namesController = TextEditingController();
  TextEditingController lastNamesController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController numDocController = TextEditingController();
  TextEditingController birthdayController = TextEditingController();
  TextEditingController socialSecurityController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController bankController = TextEditingController();
  TextEditingController bankAccountNumberController = TextEditingController();

  bool isWidgetLoaded = false;

  late GeneralInfoProvider generalInfoProvider;
  List<List<String>> dataTableFromResponsive = [];
  List<List<String>> dataTableFromResponsiveRequest = [];
  List<List<String>> dataTableFromResponsiveRequestSearch = [];

  List<List<String>> dataTableFromResponsiveActivity = [];
  DateTime currentDate = DateTime.now();
  DateTime? selectedDate;
  DateTime? newDateBirthday;
  bool jobsSorted = false;
  @override
  void didChangeDependencies() {
    if (!isWidgetLoaded) {
      isWidgetLoaded = true;
      generalInfoProvider = Provider.of<GeneralInfoProvider>(context);
    }

    super.didChangeDependencies();
  }

  @override
  void initState() {
    namesController.text = widget.employee.profileInfo.names;
    lastNamesController.text = widget.employee.profileInfo.lastNames;
    phoneController.text = widget.employee.profileInfo.phone;
    numDocController.text = widget.employee.profileInfo.docNumber;

    birthdayController.text =
        CodeUtils.formatDateWithoutHour(widget.employee.profileInfo.birthday);
    socialSecurityController.text =
        widget.employee.profileInfo.socialSecurityType ?? 'No definida';
    addressController.text = widget.employee.profileInfo.location.isNotEmpty &&
            widget.employee.profileInfo.location.containsKey("address")
        ? widget.employee.profileInfo.location['address'] ?? "Sin dirección"
        : "Sin dirección";

    bankController.text = widget.employee.bankInfo['bank'] ??
        'Aún no agrega información  bancaría';
    bankAccountNumberController.text =
        widget.employee.bankInfo['bank_account_number'] ??
            'Aún no agrega información bancaría';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _screenSize =
        Provider.of<GeneralInfoProvider>(context, listen: false).screenSize;
    _employeesProvider = Provider.of<EmployeesProvider>(context);
    _preRegisteredProvider = Provider.of<PreRegisteredProvider>(context);
    activityProvider = Provider.of<ActivityProvider>(context);
    jobsSorted = false;

    return Container(
      margin: const EdgeInsets.only(top: 30),
      child: getContent(),
    );
  }

  Widget getContent() {
    switch (widget.type) {
      case "info":
        return _buildInfo();

      case "availability":
        return _buildAvailability();

      case "docs":
        return _buildDocs();

      case "jobs":
        return _buildJobs();

      case "requests":
        return _buildRequests();

      case "messages":
        return _buildMessages();

      default:
        return _buildActivity();
    }
  }

  Widget _buildInfo() {
    return Column(
      children: [
        // _screenSize.blockWidth >= 920
        //     ?
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.spaceEvenly,
          children: [
            buildTextField(
              "Nombres",
              namesController,
            ),
            buildTextField(
              "Apellidos",
              lastNamesController,
            ),
            buildTextField(
              "Teléfono",
              phoneController,
              true,
              true,
              true,
            ),
            buildTextField(
              "Documento",
              numDocController,
              false,
              true,
            ),
            buildTextField(
              "Fecha de nacimiento",
              birthdayController,
              true,
              false,
              true,
            ),
            buildTextField(
              "Seguridad Social",
              socialSecurityController,
            ),
            buildTextField(
              "Dirección",
              addressController,
              false,
              false,
              false,
            ),
            buildTextField(
              "Banco",
              bankController,
              false,
              false,
              false,
            ),
            buildTextField(
              "Numero de cuenta",
              bankAccountNumberController,
              false,
              true,
              false,
            ),
          ],
        ),

        if (widget.type == 'info') buildUpdateBtn(),
      ],
    );
  }

  Align buildUpdateBtn() {
    return Align(
      alignment: _screenSize.blockWidth > 920
          ? Alignment.centerRight
          : Alignment.center,
      child: InkWell(
          onTap: () async => await _validateField(),
          child: Container(
            margin: const EdgeInsets.only(top: 30),
            width: _screenSize.blockWidth > 1194
                ? _screenSize.blockWidth * 0.1
                : 150,
            height: _screenSize.blockWidth > 920
                ? _screenSize.height * 0.055
                : _screenSize.height * 0.035,
            decoration: BoxDecoration(
              color: UiVariables.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                "Guardar cambios",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: _screenSize.blockWidth >= 920 ? 15 : 12,
                ),
              ),
            ),
          )),
    );
  }

  Column buildTextField(String text, TextEditingController controller,
      [bool isChangePhoneOrBirthday = false,
      bool isMinRequest = false,
      bool isReadOnly = false]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          textAlign: TextAlign.start,
          style: TextStyle(
            fontSize: _screenSize.blockWidth >= 920 ? 15 : 12,
            color: Colors.black54,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 10, right: 10),
          width: _screenSize.blockWidth >= 920
              ? _screenSize.blockWidth * 0.24
              : _screenSize.width,
          height: _screenSize.blockWidth >= 920
              ? _screenSize.height * 0.055
              : _screenSize.height * 0.045,
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
          child: TextField(
            keyboardType: TextInputType.number,
            readOnly: isReadOnly,
            inputFormatters: [
              isMinRequest
                  ? FilteringTextInputFormatter.digitsOnly
                  : FilteringTextInputFormatter.singleLineFormatter
            ],
            controller: controller,
            cursorColor: UiVariables.primaryColor,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
            ),
            maxLength: isMinRequest ? 11 : 300,
            decoration: InputDecoration(
              suffixIcon: isChangePhoneOrBirthday
                  ? (text == 'Teléfono')
                      ? InkWell(
                          onTap: () async =>
                              await ChangePhoneDialog.show(widget.employee),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.blueAccent,
                            size: 20,
                          ),
                        )
                      : InkWell(
                          onTap: () async {
                            final DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime(currentDate.year - 18),
                              firstDate: DateTime(currentDate.year - 100),
                              lastDate: DateTime(currentDate.year - 18),
                            );

                            if (pickedDate != null) {
                              newDateBirthday = pickedDate;
                              DateTime newDate = DateTime(
                                newDateBirthday!.year,
                                newDateBirthday!.month,
                                newDateBirthday!.day,
                              );
                              birthdayController.text =
                                  CodeUtils.formatDateWithoutHour(
                                newDate,
                              );
                            }
                          },
                          child: const Icon(
                            Icons.edit,
                            color: Colors.blueAccent,
                            size: 20,
                          ),
                        )
                  : const SizedBox(),
              hintText: text == 'Dirección' ? 'País, Estado, Ciudad' : text,
              hintStyle: const TextStyle(
                color: Colors.black54,
                fontSize: 14,
              ),
              counterText: '',
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocs() {
    widget.employee.documents = Map.fromEntries(
      widget.employee.documents.entries.toList()
        ..sort(
          (e1, e2) => e1.key.compareTo(e2.key),
        ),
    );

    int numDocsExpired = 0;
    return SizedBox(
      width: _screenSize.blockWidth,
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        spacing: 10,
        runSpacing: 10,
        direction: Axis.horizontal,
        children: List<Widget>.from(
          widget.employee.documents.values.toList().map((docData) {
            bool compareDates = docData['can_expire'] &&
                docData['expired_date'] != null &&
                currentDate.isAfter(
                  DateTime.parse(
                    docData['expired_date'].toDate().toString(),
                  ),
                );
            if (compareDates) numDocsExpired++;

            if (docData["file_url"].isEmpty && docData["approval_status"] > 0) {
              docData["approval_status"] = 0;
            }

            return OverflowBar(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 20, bottom: 20),
                  padding: const EdgeInsets.all(10),
                  width: _screenSize.blockWidth >= 920
                      ? _screenSize.blockWidth * 0.27
                      : _screenSize.blockWidth,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                          offset: Offset(0, 2),
                          blurRadius: 2,
                          color: Colors.black12)
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          (compareDates)
                              ? Align(
                                  alignment: Alignment.centerLeft,
                                  child: Chip(
                                    elevation: 2,
                                    backgroundColor: Colors.red,
                                    padding: const EdgeInsets.all(2),
                                    label: Text(
                                      "Documento vencido",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: _screenSize.blockWidth >= 920
                                            ? 12
                                            : 10,
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox(),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Chip(
                              elevation: 2,
                              backgroundColor: (docData["approval_status"] == 0)
                                  ? Colors.blue
                                  : (docData["approval_status"] == 1)
                                      ? Colors.green
                                      : Colors.orange,
                              padding: const EdgeInsets.all(2),
                              label: Text(
                                (docData["approval_status"] == 0)
                                    ? "Pendiente"
                                    : (docData["approval_status"] == 1)
                                        ? "Aprobado"
                                        : "Rechazado",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: _screenSize.blockWidth >= 920
                                        ? 12
                                        : 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Text(
                        _getDocRequitedStatus(docData["value"])
                            ? "${docData["name"]} *"
                            : "${docData["name"]}",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: _screenSize.blockWidth >= 920 ? 16 : 12),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text(
                                  (docData["file_url"].isNotEmpty)
                                      ? "Documento agregado"
                                      : "El documento no ha sido agregado",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize:
                                        _screenSize.blockWidth >= 920 ? 16 : 12,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                if (docData["file_url"].isNotEmpty)
                                  InkWell(
                                    onTap: () => CodeUtils.launchURL(
                                        docData["file_url"]),
                                    child: const Text(
                                      "Ver",
                                      style: TextStyle(
                                        decoration: TextDecoration.underline,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            if (docData['can_expire'])
                              Row(
                                children: [
                                  Text(
                                    compareDates
                                        ? "El documento vencio: "
                                        : "El documento vence: ",
                                    style: TextStyle(
                                      color: docData['expired_date'] != null &&
                                              compareDates
                                          ? Colors.red
                                          : Colors.grey,
                                      fontSize: _screenSize.blockWidth >= 920
                                          ? 16
                                          : 12,
                                    ),
                                  ),
                                  Text(
                                    docData["expired_date"] != null
                                        ? CodeUtils.formatDateWithoutHour(
                                            docData['expired_date'].toDate(),
                                          )
                                        : "¡Sin fecha!",
                                    style: TextStyle(
                                      color: docData['expired_date'] != null &&
                                              compareDates
                                          ? Colors.red
                                          : Colors.grey,
                                      fontSize: _screenSize.blockWidth >= 920
                                          ? 16
                                          : 12,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          if (docData['can_expire'])
                            InkWell(
                              onTap: () async {
                                final DateTime? pickedDate =
                                    await showDatePicker(
                                  context: context,
                                  initialDate: currentDate,
                                  firstDate: currentDate,
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 7300),
                                  ),
                                );

                                if (pickedDate != null) {
                                  selectedDate = pickedDate;
                                  DateTime dueDate = DateTime(
                                    selectedDate!.year,
                                    selectedDate!.month,
                                    selectedDate!.day,
                                    23,
                                    59,
                                    59,
                                  );
                                  await _updateDoc(
                                    docData["value"],
                                    1,
                                    docData['file_url'],
                                    true,
                                    dueDate.toString(),
                                    numDocsExpired,
                                  );
                                }
                              },
                              child: Text(
                                "Cambiar fecha",
                                style: TextStyle(
                                  color: Colors.blue.withOpacity(0.8),
                                  fontWeight: FontWeight.bold,
                                  fontSize:
                                      _screenSize.blockWidth >= 920 ? 16 : 12,
                                ),
                              ),
                            ),
                          InkWell(
                              onTap: () async {
                                if (!(docData["approval_status"] > 1 ||
                                    docData["file_url"].isEmpty)) {
                                  return;
                                }

                                FilePickerResult? file =
                                    (await FilePicker.platform.pickFiles(
                                  type: FileType.custom,
                                  allowCompression: true,
                                  allowedExtensions: [
                                    "jpg",
                                    "jpeg",
                                    "pdf",
                                    "png",
                                  ],
                                ));

                                if (file == null) {
                                  LocalNotificationService.showSnackBar(
                                    type: "fail",
                                    message: "No seleccionaste nigún archivo",
                                    icon: Icons.error_outline,
                                  );
                                  return;
                                }
                                String? fileExtension =
                                    file.files.last.extension;
                                Uint8List? nameFile = file.files.first.bytes;
                                TaskSnapshot uploadTask = await FirebaseStorage
                                    .instance
                                    .ref(
                                        'employees/${widget.employee.id}/documents/${docData['value']}')
                                    .putData(
                                        nameFile!,
                                        SettableMetadata(
                                            contentType: fileExtension!
                                                        .toLowerCase() ==
                                                    'pdf'
                                                ? 'application/${fileExtension.toLowerCase()}'
                                                : 'image/jpeg'));
                                String urlFile =
                                    await uploadTask.ref.getDownloadURL();

                                await _updateDoc(
                                    docData["value"], 1, urlFile, true);
                              },
                              child: Text(
                                "Subir",
                                style: TextStyle(
                                  color: docData["approval_status"] > 1 ||
                                          docData["file_url"].isEmpty
                                      ? Colors.orange
                                      : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize:
                                      _screenSize.blockWidth >= 920 ? 16 : 12,
                                ),
                              )),
                          InkWell(
                              onTap: () async {
                                if (docData["approval_status"] > 1 ||
                                    docData["file_url"].isEmpty) return;

                                await _updateDoc(docData["value"], 2);
                              },
                              child: Text(
                                "Rechazar",
                                style: TextStyle(
                                    color: docData["approval_status"] > 1 ||
                                            docData["file_url"].isEmpty
                                        ? Colors.grey
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: _screenSize.blockWidth >= 920
                                        ? 16
                                        : 12),
                              )),
                          InkWell(
                            onTap: () async {
                              if (docData["approval_status"] == 1 ||
                                  docData["file_url"].isEmpty) return;
                              await _updateDoc(
                                docData["value"],
                                1,
                              );
                            },
                            child: Text(
                              "Aprobar",
                              style: TextStyle(
                                  color: docData["approval_status"] == 1 ||
                                          docData["file_url"].isEmpty
                                      ? Colors.grey
                                      : Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize:
                                      _screenSize.blockWidth >= 920 ? 16 : 12),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _updateDoc(String doc, int status,
      [String urlFile = "",
      bool addDoc = false,
      String dueDate = '',
      int numDocsExpired = 0]) async {
    UiMethods().showLoadingDialog(context: context);
    bool itsOK = await EmployeeServices.updateDocStatus(
      context: context,
      employeeName: CodeUtils.getFormatedName(
        widget.employee.profileInfo.names,
        widget.employee.profileInfo.lastNames,
      ),
      employeeId: widget.employee.id,
      urlFile: urlFile,
      docKey: doc,
      newStatus: status,
      addDoc: addDoc,
      dueDate: dueDate,
      numDocsExpired: numDocsExpired,
    );
    UiMethods().hideLoadingDialog(context: context);
    LocalNotificationService.showSnackBar(
      type: (itsOK) ? "success" : "fail",
      message: (itsOK)
          ? "Documento actualizado correctamente"
          : "Ocurrió un error al actualizar el estado del documento",
      icon: itsOK ? Icons.check_outlined : Icons.error_outline,
    );

    if (itsOK) {
      setState(() {
        widget.employee.documents[doc]["approval_status"] = status;
        if (urlFile.isEmpty) return;
        widget.employee.documents[doc]["file_url"] = urlFile;
      });
    }
  }

  Future<void> _updateJob(String job, bool toEnable) async {
    UiMethods().showLoadingDialog(context: context);
    bool itsOk = await EmployeeServices.updateJobs(
      employee: widget.employee,
      jobKey: job,
      toEnable: toEnable,
    );
    UiMethods().hideLoadingDialog(context: context);
    LocalNotificationService.showSnackBar(
      type: (itsOk) ? "success" : "fail",
      message: (itsOk)
          ? "Cargo actualizado correctamente"
          : "Ocurrió un error al actualizar el cargo",
      icon: itsOk ? Icons.check_outlined : Icons.error_outline,
    );

    if (widget.employee.accountInfo.status == 0) {
      _preRegisteredProvider.updateSelectedEmployee(
        "jobs",
        {"job": job, "to_enable": toEnable},
      );
    } else {
      _employeesProvider.updateSelectedEmployee(
        "jobs",
        {"job": job, "to_enable": toEnable},
      );
    }
  }

  Widget _buildJobs() {
    if (jobsSorted == false) {
      widget.jobs!.sort(((a, b) =>
          a['name'].toLowerCase().compareTo(b['name'].toLowerCase())));
      jobsSorted = true;
    }
    return SizedBox(
      width: _screenSize.width,
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        spacing: 10,
        runSpacing: 10,
        direction: Axis.horizontal,
        children: List<Widget>.from(widget.jobs!.map((jobData) {
          return OverflowBar(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 20, bottom: 20),
                padding: const EdgeInsets.all(10),
                width: _screenSize.blockWidth >= 920
                    ? _screenSize.blockWidth * 0.2
                    : _screenSize.blockWidth,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      offset: Offset(0, 2),
                      blurRadius: 2,
                      color: Colors.black12,
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      jobData["name"],
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: _screenSize.blockWidth >= 920 ? 16 : 12),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Transform.scale(
                        scale: 0.76,
                        child: CupertinoSwitch(
                          value: jobData["is_enabled"],
                          onChanged: (bool newValue) async {
                            await _updateJob(jobData["value"], newValue);
                            setState(() {
                              jobData["is_enabled"] = newValue;
                            });
                          },
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          );
        })),
      ),
    );
  }

  Widget _buildRequests() {
    bool isSearch = false;

    Padding noInfoWidget = const Padding(
      padding: EdgeInsets.symmetric(vertical: 30),
      child: Center(
        child: Text("No hay solicitudes"),
      ),
    );
    List<Request> requests = [];
    List<Request> filteredRequests = [];
    if (widget.aditionalInfo['requests'] != null) {
      requests = [...widget.aditionalInfo['requests']];
    }
    dataTableFromResponsiveRequest.clear();
    if (widget.aditionalInfo['requests'] != null && !isSearch) {
      requests = [...widget.aditionalInfo['requests']];
      dataTableFromResponsiveRequest.clear();
      filteredRequests = [...requests];
      for (var request in requests) {
        dataTableFromResponsiveRequest.add([
          "Cliente-${request.clientInfo.name}",
          "Cargo-${request.details.job['name']}",
          "Fecha inicio-${CodeUtils.formatDate(request.details.startDate)}",
          "Fecha fin-${CodeUtils.formatDate(request.details.endDate)}",
          "T.Horas-${request.details.totalHours}",
          "Estado-${request.details.status}",
          "Evento-${request.eventName}",
          "Total cliente-${CodeUtils.formatMoney(request.details.fare.totalClientPays)}",
          "Total.Colab-${CodeUtils.formatMoney(request.details.fare.totalToPayEmployee)}",
        ]);
      }
    }

    return widget.aditionalInfo.containsKey("requests") &&
            widget.aditionalInfo["requests"].isEmpty
        ? noInfoWidget
        : _screenSize.blockWidth >= 920
            ? EmployeeRequests(
                requests: requests,
                screenSize: _screenSize,
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: _screenSize.blockWidth,
                    child: Row(
                      mainAxisAlignment: (filteredRequests.isNotEmpty)
                          ? MainAxisAlignment.spaceBetween
                          : MainAxisAlignment.end,
                      children: [
                        if (filteredRequests.isNotEmpty)
                          ExportToExcelBtn(
                            params: _getExcelParams(filteredRequests),
                          ),
                        CustomSearchBar(
                          onChange: (String query) {
                            isSearch = true;
                            if (query.isEmpty) {
                              filteredRequests = [...requests];
                              setState(() {});
                              return;
                            }
                            filteredRequests.clear();

                            for (Request request in requests) {
                              RequestEmployeeInfo employeeInfo =
                                  request.employeeInfo;
                              String name = CodeUtils.getFormatedName(
                                      employeeInfo.names,
                                      employeeInfo.lastNames)
                                  .toLowerCase();
                              String job =
                                  request.details.job["name"].toLowerCase();
                              String startDate = CodeUtils.formatDate(
                                  request.details.startDate);
                              String endDate =
                                  CodeUtils.formatDate(request.details.endDate);

                              String eventName =
                                  request.eventName.trim().toLowerCase();
                              String status = CodeUtils.getStatusName(
                                      request.details.status)
                                  .toLowerCase();

                              if (name.contains(query)) {
                                filteredRequests.add(request);
                                continue;
                              }
                              if (job.contains(query)) {
                                filteredRequests.add(request);
                                continue;
                              }
                              if (startDate.contains(query)) {
                                filteredRequests.add(request);
                                continue;
                              }
                              if (endDate.contains(query)) {
                                filteredRequests.add(request);
                                continue;
                              }
                              if (eventName.contains(query)) {
                                filteredRequests.add(request);
                                continue;
                              }

                              if (status.contains(query)) {
                                filteredRequests.add(request);
                                continue;
                              }
                            }
                            dataTableFromResponsiveRequest.clear();
                            dataTableFromResponsiveRequestSearch.clear();
                            for (var request in filteredRequests) {
                              dataTableFromResponsiveRequestSearch.add([
                                "Cliente-${request.clientInfo.name}",
                                "Cargo-${request.details.job['name']}",
                                "Fecha inicio-${CodeUtils.formatDate(request.details.startDate)}",
                                "Fecha fin-${CodeUtils.formatDate(request.details.endDate)}",
                                "T.Horas-${request.details.totalHours}",
                                "Estado-${request.details.status}",
                                "Evento-${request.eventName}",
                                "Total cliente-${CodeUtils.formatMoney(request.details.fare.totalClientPays)}",
                                "Total.Colab-${CodeUtils.formatMoney(request.details.fare.totalToPayEmployee)}",
                              ]);
                            }
                            setState(() {});
                          },
                          hint: "Buscar solicitud",
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  DataTableFromResponsive(
                    listData: !isSearch
                        ? dataTableFromResponsiveRequest
                        : dataTableFromResponsiveRequestSearch,
                    screenSize: _screenSize,
                    type: 'request-employee',
                    listRequestEmployees: requests,
                  ),
                ],
              );
  }

  Widget _buildMessages() {
    Padding noInfoWidget = const Padding(
      padding: EdgeInsets.symmetric(vertical: 30),
      child: Center(
        child: Text("No hay mensajes "),
      ),
    );

    List<HistoricalMessage> messages = [];

    if (widget.aditionalInfo['messages'] != null) {
      messages = [...widget.aditionalInfo['messages']];
    }
    dataTableFromResponsive.clear();

    if (messages.isNotEmpty) {
      dataTableFromResponsive.clear();

      for (var messages in messages) {
        dataTableFromResponsive.add([
          "Título-${messages.title}",
          "Mensaje-${messages.message}",
          "Tipo-${CodeUtils.getMessageTypeName(messages.type)}",
          "Adjuntos-${messages.attachments.join(', ')}",
          "Fecha-${CodeUtils.formatDate(messages.date)}",
        ]);
      }
    }
    return (widget.aditionalInfo.containsKey("messages") &&
            widget.aditionalInfo["messages"].isEmpty)
        ? noInfoWidget
        : _screenSize.blockWidth >= 920
            ? EmployeeMessages(
                messages: messages,
                screenSize: _screenSize,
              )
            : DataTableFromResponsive(
                listData: dataTableFromResponsive,
                screenSize: _screenSize,
                type: 'messages');
  }

  Widget _buildActivity() {
    dataTableFromResponsiveActivity.clear();
    if (activityProvider.employeeFilteredActivity.isNotEmpty) {
      dataTableFromResponsiveActivity.clear();
      for (var activityEmployee in activityProvider.employeeFilteredActivity) {
        dataTableFromResponsiveActivity.add([
          "Descripción-${activityEmployee.description}",
          "Responsable-${activityEmployee.personInCharge['name']}",
          "Tipo responsable-${activityEmployee.personInCharge['type_name']}",
          "Categoría-${activityEmployee.category['name']}",
          "Fecha-${CodeUtils.formatDate(activityEmployee.date)}",
        ]);
      }
    }
    return _screenSize.blockWidth >= 920
        ? EmployeeActivity(
            screenSize: _screenSize,
            employeeId: widget.employee.id,
          )
        : DataTableFromResponsive(
            listData: dataTableFromResponsiveActivity,
            screenSize: _screenSize,
            type: 'activity-employee',
            employeeId: widget.employee.id,
          );
  }

  Widget buildMessagesSearchBar() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(top: 30),
        width: _screenSize.blockWidth * 0.3,
        height: _screenSize.height * 0.055,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              offset: Offset(0, 2),
              color: Colors.black26,
              blurRadius: 2,
            )
          ],
        ),
        child: TextField(
          controller: _searchMessageController,
          decoration: const InputDecoration(
            suffixIcon: Icon(Icons.search),
            hintText: "Buscar mensaje",
            hintStyle: TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          // onChanged: messagesProvider.filterMessages,
        ),
      ),
    );
  }

  bool _getDocRequitedStatus(String docKey) {
    if (generalInfoProvider.generalInfo.countryInfo.requiredDocs
        .containsKey(docKey)) {
      return generalInfoProvider.generalInfo.countryInfo.requiredDocs[docKey]
          ["required"];
    }

    return false;
  }

  Widget _buildAvailability() {
    return SizedBox(
      width: _screenSize.blockWidth,
      child: AvaliabilityScreen(
        screenSize: _screenSize,
        employeesProvider: _employeesProvider,
        employee: widget.employee,
      ),
    );
  }

  _validateField() async {
    if (numDocController.text.isEmpty ||
        namesController.text.isEmpty ||
        phoneController.text.isEmpty ||
        lastNamesController.text.isEmpty ||
        socialSecurityController.text.isEmpty) {
      LocalNotificationService.showSnackBar(
        type: 'fail',
        message: 'No pueden existir campos vacíos',
        icon: Icons.warning,
        duration: 2,
      );
      return;
    }
    if (addressController.text ==
            widget.employee.profileInfo.location['address'] &&
        numDocController.text == widget.employee.profileInfo.docNumber &&
        namesController.text == widget.employee.profileInfo.names &&
        phoneController.text == widget.employee.profileInfo.phone &&
        lastNamesController.text == widget.employee.profileInfo.lastNames &&
        socialSecurityController.text ==
            widget.employee.profileInfo.socialSecurityType &&
        bankController.text == widget.employee.bankInfo['bank'] &&
        bankAccountNumberController.text ==
            widget.employee.bankInfo['bank_account_number'] &&
        widget.newImage == widget.employee.profileInfo.image) {
      LocalNotificationService.showSnackBar(
        type: 'fail',
        message: 'Aún no ha realizado ningún cambio',
        icon: Icons.warning,
        duration: 2,
      );
      return;
    }
    UiMethods().showLoadingDialog(context: context);
    await _employeesProvider.updateEmployees(
      idEmployee: widget.employee.id,
      data: {
        "bank_info": {
          "bank": bankController.text.toUpperCase(),
          "bank_account_number": bankAccountNumberController.text,
        },
        "profile_info": {
          "image": widget.newImage == ''
              ? widget.employee.profileInfo.image
              : widget.newImage,
          "gender": widget.employee.profileInfo.gender,
          "birthday": newDateBirthday != null
              ? DateTime.parse(newDateBirthday.toString())
              : widget.employee.profileInfo.birthday,
          "doc_number": numDocController.text,
          "doc_type": widget.employee.profileInfo.docType,
          "document": numDocController.text,
          "names": namesController.text,
          "last_names": lastNamesController.text,
          "phone": phoneController.text,
          "social_security_type":
              widget.employee.profileInfo.socialSecurityType ??
                  socialSecurityController.text,
          "location": {
            "country": widget.employee.profileInfo.location['country'],
            "state": widget.employee.profileInfo.location['state'],
            "city": widget.employee.profileInfo.location['city'],
            "address": addressController.text,
            "position": widget.employee.profileInfo.location['position']
          },
          //widget.employee.profileInfo.location,
          "rate": widget.employee.profileInfo.rate,
        },
      },
    );

    if (mounted) {
      UiMethods().hideLoadingDialog(context: context);
    }
  }

  ExcelParams _getExcelParams(List<Request> requests) {
    return ExcelParams(
      headers: [
        {
          "key": "client_name",
          "display_name": "Cliente",
          "width": 150,
        },
        {
          "key": "job",
          "display_name": "Cargo",
          "width": 150,
        },
        {
          "key": "start_date",
          "display_name": "Fecha inicio",
          "width": 150,
        },
        {
          "key": "end_date",
          "display_name": "Fecha fin",
          "width": 150,
        },
        {
          "key": "total_hours",
          "display_name": "Total horas",
          "width": 150,
        },
        {
          "key": "status",
          "display_name": "Estado",
          "width": 150,
        },
        {
          "key": "event_name",
          "display_name": "Evento",
          "width": 150,
        },
        {
          "key": "client_total",
          "display_name": "Total cliente",
          "width": 150,
        },
        {
          "key": "employee_total",
          "display_name": "Total colaborador",
          "width": 150,
        },
      ],
      data: List.generate(requests.length, (index) {
        Request request = requests[index];

        return {
          "client_name": request.clientInfo.name,
          "job": request.details.job["name"],
          "start_date": CodeUtils.formatDate(request.details.startDate),
          "end_date": CodeUtils.formatDate(request.details.endDate),
          "total_hours": request.details.totalHours,
          "status": CodeUtils.getStatusName(request.details.status),
          "event_name": request.eventName,
          "client_total": request.details.fare.totalClientPays,
          "employee_total": request.details.fare.totalToPayEmployee,
        };
      }),
      otherInfo: {},
      fileName:
          "solicitudes_${requests[0].employeeInfo.names}_${requests[0].employeeInfo.lastNames}",
    );
  }
}

// Row _buildRowItemDivider() {
//   return Row(
//     children: [
//       const SizedBox(width: 10),
//       Container(
//         width: 1,
//         height: 25,
//         color: Colors.grey,
//       ),
//       const SizedBox(width: 10),
//     ],
//   );
// }
