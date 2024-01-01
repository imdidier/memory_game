import 'package:flutter/material.dart';
import 'package:huts_web/core/services/navigation_service.dart';
import 'package:huts_web/core/utils/ui/providers/sidebar_provider.dart';
import 'package:huts_web/core/utils/ui/ui_variables.dart';
import 'package:huts_web/features/auth/display/providers/auth_provider.dart';
import 'package:huts_web/features/general_info/display/providers/general_info_provider.dart';
import 'package:provider/provider.dart';

class Sidebar extends StatelessWidget {
  final GeneralInfoProvider generalInfoProvider;
  final AuthProvider authProvider;
  final String projectVersion;
  const Sidebar({
    Key? key,
    required this.generalInfoProvider,
    required this.authProvider,
    required this.projectVersion,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SidebarProvider sidebarProvider = Provider.of<SidebarProvider>(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      width: 200,
      height: double.infinity,
      decoration: BoxDecoration(
        color: UiVariables.primaryColor,
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 5,
          ),
        ],
      ),
      child: ListView(
        physics: const ClampingScrollPhysics(),
        children: [
          const SizedBox(height: 25),
          Center(
            child: authProvider.webUser.accountInfo.type == "admin"
                ? Image.asset(
                    "assets/images/white_logo.png",
                    width: generalInfoProvider.screenSize.width * 0.042,
                    filterQuality: FilterQuality.high,
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      authProvider.webUser.company.image,
                      width: generalInfoProvider.screenSize.width * 0.05,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
          ),
          const SizedBox(height: 18),
          Text(
            authProvider.webUser.company.name,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          Center(
              child: Text(
            projectVersion,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          )),
          buildDivider(),
          ListView(
            shrinkWrap: true,
            children: getUserRoutes(sidebarProvider),
          ),
          buildDivider(),
          buildLogoutBtn(),
          const SizedBox(height: 25),
        ],
      ),
    );
  }

  List<SidebarItem> getUserRoutes(SidebarProvider sidebarProvider) {
    List<SidebarItem> routes = [];

    for (String key in generalInfoProvider.otherInfo.webRoutes.keys) {
      Map<String, dynamic> routeData =
          generalInfoProvider.otherInfo.webRoutes[key];

      String userType = authProvider.webUser.accountInfo.type;
      String userSubtype = authProvider.webUser.accountInfo.subtype;

      if (routeData["info"]["text"] == "Perfil") continue;
      if (!routeData["visibility"][userType]["enabled"]) continue;
      if (!routeData["visibility"][userType][userSubtype]) continue;

      routes.add(
        SidebarItem(
          optionInfo: {
            "icon": routeData["info"]["icon"],
            "text": (routeData["info"]["text"] == "Eventos")
                ? (authProvider.webUser.accountInfo.type == "admin")
                    ? "Solicitudes"
                    : "Eventos"
                : routeData["info"]["text"],
            "position": routeData["info"]["position"],
            "is_active":
                sidebarProvider.currentPage == routeData["info"]["route"],
          },
          onPressed: () {
            authProvider.webUser.isClicked = false;
            NavigationService.goback();
            NavigationService.navigateTo(routeName: routeData["info"]["route"]);
            if (generalInfoProvider.screenSize.blockWidth < 700) {
              SidebarProvider.closeMenu();
              sidebarProvider.showing = false;
            }
          },
        ),
      );
    }

    routes.sort(
        (a, b) => a.optionInfo["position"].compareTo(b.optionInfo["position"]));

    return routes;
  }

  Widget buildDivider() {
    return const Column(
      children: [
        SizedBox(height: 15),
        Divider(color: Color.fromARGB(137, 240, 209, 209)),
      ],
    );
  }

  SidebarItem buildLogoutBtn() {
    return SidebarItem(
      optionInfo: const {
        "icon": "logout_rounded",
        "text": "Cerrar sesión",
        "position": 0,
        "is_active": false,
      },
      onPressed: () => {authProvider.signOut()},
    );
  }
}

class SidebarItem extends StatefulWidget {
  final Map<String, dynamic> optionInfo;
  final Function onPressed;
  const SidebarItem({
    Key? key,
    required this.optionInfo,
    required this.onPressed,
  }) : super(key: key);

  @override
  State<SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<SidebarItem> {
  bool isHovered = false;
  @override
  Widget build(BuildContext context) {
    // GeneralInfoProvider generalInfoProvider =
    //     Provider.of<GeneralInfoProvider>(context);
    return AnimatedContainer(
      color: isHovered
          ? Colors.white.withOpacity(0.2)
          : widget.optionInfo["is_active"]
              ? Colors.white.withOpacity(0.2)
              : Colors.transparent,
      duration: const Duration(milliseconds: 0),
      margin: const EdgeInsets.only(
        top: 5,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap:
              widget.optionInfo["is_active"] ? null : () => widget.onPressed(),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: MouseRegion(
              onEnter: (_) => setState(() => isHovered = true),
              onExit: (_) => setState(() => isHovered = false),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    widget.optionInfo["icon"],
                    style: const TextStyle(
                      fontFamily: 'MaterialIcons',
                      color: Colors.white,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.optionInfo["text"],
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
