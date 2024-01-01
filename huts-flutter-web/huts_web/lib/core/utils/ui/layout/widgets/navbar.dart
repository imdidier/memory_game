// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:huts_web/core/services/navigation_service.dart';
import 'package:huts_web/core/utils/ui/providers/sidebar_provider.dart';
import 'package:huts_web/core/utils/ui/ui_methods.dart';
import 'package:huts_web/features/auth/display/providers/auth_provider.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/auth/domain/entities/web_user_entity.dart';
import 'package:huts_web/features/clients/display/provider/clients_provider.dart';
import 'package:huts_web/features/general_info/display/providers/general_info_provider.dart';
import 'package:huts_web/features/profile_info/domain/display/providers/profile_provider.dart';
import 'package:huts_web/features/profile_info/domain/display/screens/activity.dart';
import 'package:huts_web/features/profile_info/domain/display/screens/direction.dart';
import 'package:huts_web/features/profile_info/domain/display/screens/information.dart';
import 'package:provider/provider.dart';

import '../../../../../features/activity/display/providers/activity_provider.dart';
import '../../../../../features/profile_info/domain/display/screens/users/blocked/blocked.dart';
import '../../../../../features/profile_info/domain/display/screens/users/favorites/favorites.dart';
import '../../../../../features/profile_info/domain/display/screens/users/users.dart';
import '../../ui_variables.dart';
import '../../widgets/general/custom_date_selector.dart';

class Navbar extends StatefulWidget {
  final ScreenSize screenSize;
  final WebUser user;
  final ClientsProvider clientsProvider;

  const Navbar({
    Key? key,
    required this.screenSize,
    required this.user,
    required this.clientsProvider,
  }) : super(key: key);

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  bool isShowingDateWidget = false;
  final ScrollController _scrollController = ScrollController();
  bool isShowTabsClient = false;
  late AuthProvider authProvider;

  // @override
  // void didChangeDependencies() {
  //   widget.user.isClicked = false;
  //   super.didChangeDependencies();
  // }

  @override
  Widget build(BuildContext context) {
    ProfileProvider profileProvider = Provider.of<ProfileProvider>(context);
    GeneralInfoProvider generalInfoProvider =
        Provider.of<GeneralInfoProvider>(context);
    authProvider = Provider.of<AuthProvider>(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      height: 50,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment:
            // (screenSize.blockWidth >= 700)
            //     ? MainAxisAlignment.end
            //     :
            MainAxisAlignment.spaceBetween,
        children: [
          //if (screenSize.blockWidth < 700)
          InkWell(
            onTap: () {
              if (generalInfoProvider.screenSize.blockWidth >= 700) {
                generalInfoProvider.showHideWebSideBar();
              } else {
                SidebarProvider.openMenu();
                context.read<SidebarProvider>().showing = false;
              }
            },
            child: Icon(
              Icons.menu,
              color: UiVariables.primaryColor,
              size: widget.screenSize.width * 0.02,
            ),
          ),
          Row(
            children: [
              Text(
                getFormatedUserName(),
                style: TextStyle(
                  color: Colors.black,
                  fontSize: widget.screenSize.width * 0.012,
                ),
              ),
              const SizedBox(width: 16),
              InkWell(
                onTap: () async {
                  if (widget.user.isClicked) {
                    return;
                  }
                  UiMethods().showLoadingDialog(
                      context: NavigationService.getGlobalContext()!);

                  await profileProvider.eitherOrFailClientUsers(
                      context, widget.user.accountInfo.companyId);

                  if (!widget.user.isClicked) {
                    widget.user.isClicked = true;
                    await profileProvider.eitherFailOrCountries(
                        context, widget.user);

                    UiMethods().hideLoadingDialog(
                        context: NavigationService.getGlobalContext()!);

                    myDialogProfile(context, profileProvider, widget.screenSize,
                        generalInfoProvider);
                  }
                },
                child: CircleAvatar(
                  backgroundColor: UiVariables.primaryColor,
                  radius: 15,
                  child: (widget.user.profileInfo.image != "")
                      ? ClipOval(
                          child: Image.network(
                            widget.user.profileInfo.image,
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          color: Colors.white,
                        ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  _showDialog() {
    showDialog(
      context: NavigationService.getGlobalContext()!,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Center(
            child: Text(
              "¡Permisos insuficientes!",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          content: const Text(
            'Permisos insuficientes para visualizar esta información, contacta al administrador de Huts',
          ),
          actions: [
            Center(
              child: TextButton(
                child: const Text("Aceptar"),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  myDialogProfile(BuildContext context, ProfileProvider profileProvider,
      ScreenSize screenSize, GeneralInfoProvider generalInfoProvider) {
    List<Map<String, dynamic>> newProfileTabs = [];
    bool isSuperAdmin = authProvider.webUser.accountInfo.subtype == 'admin' &&
        authProvider.webUser.accountInfo.type == 'admin';
    isShowTabsClient = ((generalInfoProvider.otherInfo.webRoutes['profile']
                    ['visibility'][widget.user.accountInfo.type]['enabled'] ==
                true &&
            generalInfoProvider.otherInfo.webRoutes['profile']['visibility']
                        [widget.user.accountInfo.type]
                    [widget.user.accountInfo.subtype] ==
                true)) &&
        !isSuperAdmin;
    if (isShowTabsClient) {
      newProfileTabs = [...profileProvider.profileTabs];
    } else {
      newProfileTabs.add(profileProvider.profileTabs[0]);
    }
    return showDialog(
      context: NavigationService.getGlobalContext()!,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Perfil'),
              InkWell(
                  onTap: () {
                    Navigator.of(ctx).pop();
                    widget.user.isClicked = false;
                  },
                  child: const Icon(Icons.cancel_sharp))
            ],
          ),
          content: StatefulBuilder(
            builder: ((ctx, setState) {
              return SizedBox(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(
                        width: screenSize.width,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 35,
                              child: (widget.user.profileInfo.image != '')
                                  ? ClipOval(
                                      child: Image.network(
                                        widget.user.profileInfo.image,
                                      ),
                                    )
                                  : const Icon(Icons.person,
                                      color: Colors.white),
                            ),
                            SizedBox(height: screenSize.height * 0.03),
                            Text(
                              '${widget.user.profileInfo.names} ${widget.user.profileInfo.lastNames}',
                              style: TextStyle(
                                  fontSize: screenSize.width * 0.012,
                                  fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: screenSize.height * 0.034),
                            Text(
                              widget.user.company.name,
                              style:
                                  TextStyle(fontSize: screenSize.width * 0.013),
                            ),
                            SizedBox(height: screenSize.height * 0.009),
                            Text(
                              (widget.user.accountInfo.type == 'client' &&
                                      widget.user.accountInfo.subtype ==
                                          'admin')
                                  ? '${generalInfoProvider.otherInfo.webUserSubtypes['admin']} '
                                      .toUpperCase()
                                  : widget.user.accountInfo.subtype ==
                                          'finances'
                                      ? '${generalInfoProvider.otherInfo.webUserSubtypes['finances']} '
                                          .toUpperCase()
                                      : '${generalInfoProvider.otherInfo.webUserSubtypes['operations']}'
                                          .toUpperCase(),
                              style:
                                  TextStyle(fontSize: screenSize.width * 0.01),
                            ),
                            SizedBox(height: screenSize.height * 0.03),
                            SizedBox(
                              height: screenSize.height * 0.062,
                              width: screenSize.blockWidth,
                              child: ListView.builder(
                                  itemExtent: 220,
                                  itemCount: newProfileTabs.length,
                                  scrollDirection: Axis.horizontal,
                                  itemBuilder:
                                      (BuildContext contex, int index) {
                                    Map<String, dynamic> itemTab =
                                        profileProvider.profileTabs[index];
                                    return profileTabsItem(itemTab, index,
                                        profileProvider, setState);
                                  }),
                            ),
                            SizedBox(height: screenSize.height * 0.03),
                            Stack(
                              children: [
                                NotificationListener(
                                  onNotification: (Notification notification) {
                                    if (_scrollController.position.pixels >
                                            20 &&
                                        isShowingDateWidget) {
                                      isShowingDateWidget = false;
                                      setState(() {});
                                      return true;
                                    }

                                    if (_scrollController.position.pixels <=
                                            30 &&
                                        !isShowingDateWidget) {
                                      isShowingDateWidget = true;
                                      setState(() {});
                                    }
                                    return true;
                                  },
                                  child: SingleChildScrollView(
                                    controller: _scrollController,
                                    physics: const BouncingScrollPhysics(),
                                    child: Container(
                                      alignment: Alignment.center,
                                      child: profileProvider.selectedProfileTab[
                                                  'value'] ==
                                              0
                                          ? InformationScreen(user: widget.user)
                                          : profileProvider.selectedProfileTab[
                                                          'value'] ==
                                                      1 &&
                                                  isShowTabsClient
                                              ? DirectionScreen(
                                                  size: screenSize,
                                                  user: widget.user)
                                              : profileProvider.selectedProfileTab[
                                                              'value'] ==
                                                          2 &&
                                                      isShowTabsClient
                                                  ? UsersScreen(
                                                      screenSize: screenSize,
                                                      user: widget.user,
                                                    )
                                                  : profileProvider.selectedProfileTab[
                                                                  'value'] ==
                                                              3 &&
                                                          isShowTabsClient
                                                      ? FavoritesScreen(
                                                          screenSize:
                                                              screenSize,
                                                          user: widget.user,
                                                          clientsProvider: widget
                                                              .clientsProvider,
                                                        )
                                                      : profileProvider.selectedProfileTab[
                                                                      'value'] ==
                                                                  4 &&
                                                              isShowTabsClient
                                                          ? BlockedScreen(
                                                              screenSize:
                                                                  screenSize,
                                                              user: widget.user,
                                                              clientsProvider:
                                                                  widget
                                                                      .clientsProvider,
                                                            )
                                                          : profileProvider.selectedProfileTab[
                                                                          'value'] ==
                                                                      5 &&
                                                                  isShowTabsClient
                                                              ? ActivityScreen(
                                                                  clientsProvider:
                                                                      widget
                                                                          .clientsProvider,
                                                                )
                                                              : const SizedBox(),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: screenSize.height * 0.001,
                                  right: 10,
                                  child: CustomDateSelector(
                                    isVisible: profileProvider
                                                .selectedProfileTab['value'] ==
                                            5 &&
                                        isShowingDateWidget,
                                    onDateSelected:
                                        (DateTime? start, DateTime? end) async {
                                      if (start == null) return;

                                      start = DateTime(
                                        start.year,
                                        start.month,
                                        start.day,
                                        00,
                                        00,
                                      );
                                      end ??= DateTime(
                                        start.year,
                                        start.month,
                                        start.day,
                                        23,
                                        59,
                                      );

                                      if (end.day != start.day) {
                                        end = DateTime(
                                          end.year,
                                          end.month,
                                          end.day,
                                          23,
                                          59,
                                        );
                                      }

                                      await Provider.of<ActivityProvider>(
                                              context,
                                              listen: false)
                                          .getClientActivity(
                                        id: widget.user.company.id,
                                        startDate: start,
                                        endDate: end,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget profileTabsItem(Map<String, dynamic> itemTab, int index,
      ProfileProvider profileProvider, StateSetter setter) {
    return InkWell(
      onTap: () {
        setter(
          () {
            profileProvider.selectProfileTab(newTabSelected: index);
          },
        );
      },
      child: Container(
        width: widget.screenSize.blockWidth * 0.35,
        decoration: (itemTab['isSelectedTab'])
            ? const BoxDecoration(
                border:
                    Border(bottom: BorderSide(color: Colors.pink, width: 1.0)))
            : const BoxDecoration(),
        // margin: EdgeInsets.only(
        //   left: (index == 0)
        //       ? (itemTab['isSelectedTab'])
        //           ? 25
        //           : 15
        //       : 30,
        //   right: (index == profileProvider.profileTabs.length - 1) ? 30 : 0,
        // ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: (Text(
              itemTab['name'],
              style: TextStyle(
                color: (itemTab['isSelectedTab']) ? Colors.black : Colors.grey,
                fontSize: widget.screenSize.width * 0.012,
              ),
            )),
          ),
        ),
      ),
    );
  }

  String getFormatedUserName() {
    String firstName = widget.user.profileInfo.names.split(" ")[0];
    String firstLastName = widget.user.profileInfo.lastNames.split(" ")[0];

    return "¡Hola $firstName $firstLastName!";
  }
}
