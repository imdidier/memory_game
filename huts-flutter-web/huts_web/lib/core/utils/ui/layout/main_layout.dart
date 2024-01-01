import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/utils/ui/layout/widgets/navbar.dart';
import 'package:huts_web/core/utils/ui/layout/widgets/sidebar.dart';
import 'package:huts_web/features/auth/display/providers/auth_provider.dart';
import 'package:huts_web/features/clients/display/provider/clients_provider.dart';
import 'package:huts_web/features/employees/display/provider/employees_provider.dart';
import 'package:huts_web/features/general_info/display/providers/general_info_provider.dart';
import 'package:huts_web/features/requests/display/providers/get_requests_provider.dart';
import 'package:provider/provider.dart';

import '../providers/sidebar_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

class MainLayout extends StatefulWidget {
  final Widget child;
  const MainLayout({Key? key, required this.child}) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout>
    with SingleTickerProviderStateMixin {
  bool isScreenLoaded = false;
  late GeneralInfoProvider generalInfoProvider;
  late AuthProvider authProvider;
  late GetRequestsProvider requestsProvider;
  late ClientsProvider clientsProvider;
  late EmployeesProvider employeesProvider;
  String projectVersion = "1.0";
  @override
  void initState() {
    super.initState();
    SidebarProvider.menuController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 300,
      ),
    );
  }

  @override
  void didChangeDependencies() async {
    if (isScreenLoaded) return;
    isScreenLoaded = true;
    generalInfoProvider = Provider.of<GeneralInfoProvider>(context);
    authProvider = Provider.of<AuthProvider>(context);
    requestsProvider = Provider.of<GetRequestsProvider>(context);
    clientsProvider = Provider.of<ClientsProvider>(context);
    employeesProvider = Provider.of<EmployeesProvider>(context);
    await generalInfoProvider.getGeneralInfoOrFail(context);

    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    projectVersion = packageInfo.version;
    //Validate this for firebase readings//
    if (authProvider.webUser.accountInfo.type == "admin") {
      await clientsProvider.getAllClients();
      await employeesProvider.getEmployees(employeesProvider);
    }

    await refreshView();

    super.didChangeDependencies();
  }

  Future<void> refreshView() async {
    if (mounted) {
      setState(() {});
      return;
    }
    await Future.delayed(
      const Duration(milliseconds: 1500),
      () async => await refreshView(),
    );
  }

  @override
  Widget build(BuildContext context) {
    clientsProvider = Provider.of<ClientsProvider>(context);
    return Scaffold(
      backgroundColor: const Color(0xffEDF1F2),
      body: Stack(
        children: [
          Row(
            children: [
              if (generalInfoProvider.screenSize.blockWidth >= 700)
                if (generalInfoProvider.showWebSideBar)
                  FadeInLeft(
                    animate: true,
                    manualTrigger: true,
                    controller: (controller) => generalInfoProvider
                        .webSideBarAnimationController = controller,
                    from: 50,
                    duration: const Duration(milliseconds: 300),
                    child: Sidebar(
                      projectVersion: projectVersion,
                      generalInfoProvider: generalInfoProvider,
                      authProvider: authProvider,
                    ),
                  ),
              Expanded(
                child: AnimatedSize(
                  curve: Curves.linear,
                  duration: const Duration(milliseconds: 300),
                  child: Column(
                    children: [
                      Navbar(
                        screenSize: generalInfoProvider.screenSize,
                        user: authProvider.webUser,
                        clientsProvider: clientsProvider,
                      ),
                      Expanded(
                        child: widget.child,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (generalInfoProvider.screenSize.blockWidth < 700)
            AnimatedBuilder(
              animation: SidebarProvider.menuController,
              builder: (_, __) => Stack(
                children: [
                  if (SidebarProvider.isOpen)
                    Opacity(
                      opacity: SidebarProvider.opacity.value,
                      child: GestureDetector(
                        onTap: () => SidebarProvider.closeMenu(),
                        child: Container(
                          width: generalInfoProvider.screenSize.blockWidth,
                          height: generalInfoProvider.screenSize.absoluteHeight,
                          color: Colors.black26,
                        ),
                      ),
                    ),
                  Transform.translate(
                    offset: Offset(SidebarProvider.movement.value, 0),
                    child: Sidebar(
                      projectVersion: projectVersion,
                      generalInfoProvider: generalInfoProvider,
                      authProvider: authProvider,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
