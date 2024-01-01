import 'package:flutter/material.dart';
import 'package:huts_web/core/utils/ui/ui_variables.dart';
import 'package:huts_web/core/utils/ui/widgets/general/data_table_from_responsive.dart';
import 'package:huts_web/features/clients/display/provider/clients_provider.dart';
import 'package:huts_web/features/clients/display/widgets/clients_data_table.dart';
import 'package:provider/provider.dart';
import '../../../admins/display/providers/admin_provider.dart';
import '../../../auth/display/providers/auth_provider.dart';
import '../../../auth/domain/entities/screen_size_entity.dart';
import '../../../general_info/display/providers/general_info_provider.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({Key? key}) : super(key: key);
  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  late GeneralInfoProvider generalInfoProvider;
  bool isScreenLoaded = false;
  late ClientsProvider clientsProvider;
  late ScreenSize screenSize;
  late AdminProvider adminProvider;
  late AuthProvider authProvider;

  int selectedClientIndex = -1;
  UiVariables uiVariables = UiVariables();
  List<List<String>> dataTableFromResponsive = [];

  List<Map<String, dynamic>> clientInfoTabs = [
    {
      "name": "Información",
      "is_selected": true,
    },
    {
      "name": "Información legal",
      "is_selected": false,
    },
    {
      "name": "Ubicación",
      "is_selected": false,
    },
    {
      "name": "Tarifas",
      "is_selected": false,
    },
    {
      "name": "Favoritos",
      "is_selected": false,
    },
    {
      "name": "Bloqueados",
      "is_selected": false,
    },
    {
      "name": "Usuarios",
      "is_selected": false,
    },
    {
      "name": "Actividad",
      "is_selected": false,
    }
  ];
  int selectedTab = 0;

  @override
  void didChangeDependencies() async {
    if (isScreenLoaded) return;
    isScreenLoaded = true;
    clientsProvider = Provider.of<ClientsProvider>(context);
    generalInfoProvider = Provider.of<GeneralInfoProvider>(context);
    authProvider = Provider.of<AuthProvider>(context, listen: false);

    adminProvider = Provider.of<AdminProvider>(context);
    await adminProvider.eitherFailOrGetCompanies(authProvider.webUser.uid);

    super.didChangeDependencies();
  }

  final ScrollController _scrollController = ScrollController();
  ValueNotifier<bool> isShowingDateWidget = ValueNotifier<bool>(false);

  bool isDesktop = false;

  @override
  Widget build(BuildContext context) {
    screenSize = Provider.of<GeneralInfoProvider>(context).screenSize;
    isDesktop = screenSize.width >= 1120;
    return SizedBox(
      height: screenSize.height,
      width: screenSize.blockWidth,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            NotificationListener(
              onNotification: (Notification notification) {
                if (_scrollController.position.pixels > 20 &&
                    isShowingDateWidget.value) {
                  isShowingDateWidget.value = false;

                  return true;
                }

                if (_scrollController.position.pixels <= 30 &&
                    !isShowingDateWidget.value) {
                  isShowingDateWidget.value = true;
                }
                return true;
              },
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: (clientsProvider.isMovingMapCamera)
                    ? const NeverScrollableScrollPhysics()
                    : const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: (selectedClientIndex == -1)
                      ? [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              buildTitle(),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Total clientes: ${clientsProvider.allClients.length}",
                                    style: TextStyle(
                                        fontSize: isDesktop ? 16 : 12),
                                  ),
                                  buildSearchBar(),
                                ],
                              ),
                              buildClients()
                            ],
                          )
                        ]
                      : [],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSearchBar() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        height: isDesktop ? screenSize.height * 0.055 : 30,
        width: screenSize.blockWidth >= 920
            ? screenSize.blockWidth * 0.3
            : screenSize.blockWidth,
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
          controller: clientsProvider.searchController,
          decoration: InputDecoration(
            suffixIcon: Icon(
              Icons.search,
              size: isDesktop ? 16 : 12,
            ),
            hintText: "Buscar Cliente",
            hintStyle: TextStyle(
              color: Colors.grey,
              fontSize: isDesktop ? 14 : 10,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
                horizontal: 20, vertical: isDesktop ? 12 : 4),
          ),
          onChanged: clientsProvider.filterClients,
        ),
      ),
    );
  }

  Container buildClients() {
    dataTableFromResponsive.clear();
    for (var clients in clientsProvider.filteredClients) {
      dataTableFromResponsive.add([
        'Imagen-${clients.imageUrl}',
        'Nombre-${clients.name}',
        'Correo-${clients.email}',
        'País-${clients.location.country}',
        'Ciudad-${clients.location.city}',
        'Estado-${clients.accountInfo.status}',
        'Id-${clients.accountInfo.id}',
        "Acciones-",
      ]);
    }
    return Container(
      // color: Colors.red,
      margin: const EdgeInsets.only(top: 30),
      child: (clientsProvider.filteredClients.isNotEmpty &&
              screenSize.blockWidth >= 920)
          ? ClientsDataTable(screenSize: screenSize)
          : DataTableFromResponsive(
              listData: dataTableFromResponsive,
              screenSize: screenSize,
              type: 'client',
            ),
    );
  }

  Row buildTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Clientes",
              style: TextStyle(
                color: Colors.black,
                fontSize: screenSize.width * 0.016,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              "Lista de clientes registrados en Huts.",
              style: TextStyle(
                color: Colors.black54,
                fontSize: screenSize.width * 0.01,
              ),
            ),
          ],
        ),
        InkWell(
          onTap: () {
            clientsProvider.showCreateClientDialog(context, screenSize);
          },
          child: Container(
            width: screenSize.blockWidth >= 920
                ? screenSize.blockWidth * 0.1
                : 100,
            height:
                screenSize.blockWidth >= 920 ? screenSize.height * 0.045 : 20,
            decoration: BoxDecoration(
              color: UiVariables.primaryColor.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                "Crear Cliente",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenSize.blockWidth >= 900 ? 15 : 11,
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
}
