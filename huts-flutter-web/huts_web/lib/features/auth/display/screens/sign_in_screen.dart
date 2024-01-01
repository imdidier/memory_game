import 'package:flutter/material.dart';
import 'package:huts_web/core/services/local_notification_service.dart';
import 'package:huts_web/core/utils/code/code_utils.dart';
import 'package:huts_web/core/utils/ui/ui_variables.dart';
import 'package:huts_web/features/auth/display/providers/auth_provider.dart';
import 'package:huts_web/features/general_info/display/providers/general_info_provider.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/ui/widgets/general/button_progess_indicator.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool isScreenLoaded = false;
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  late GeneralInfoProvider generalInfoProvider;
  late AuthProvider authProvider;

  @override
  void didChangeDependencies() {
    if (isScreenLoaded) return;
    isScreenLoaded = true;
    generalInfoProvider = Provider.of<GeneralInfoProvider>(context);
    authProvider = Provider.of<AuthProvider>(context);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: UiVariables.primaryColor,
        width: generalInfoProvider.screenSize.width,
        height: generalInfoProvider.screenSize.height,
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  "assets/images/white_logo.png",
                  width: generalInfoProvider.screenSize.width * 0.15,
                  filterQuality: FilterQuality.high,
                ),
                const SizedBox(height: 40),
                Text(
                  (!authProvider.isRecoveringPass)
                      ? "Bienvenido a Huts."
                      : "Recuperar contraseña",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: generalInfoProvider.screenSize.width * 0.022,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  (!authProvider.isRecoveringPass)
                      ? "La forma más fácil de encontrar trabajo."
                      : "Ingresa tu correo, se te enviará un mensaje de recuperación",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: generalInfoProvider.screenSize.width * 0.013,
                  ),
                ),
                buildTextFields(),
                buildLoginBtn(),
                //if (!authProvider.isRecoveringPass)
                buildRecoverPassBtn(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  GestureDetector buildLoginBtn() {
    return GestureDetector(
      onTap: () async =>
          (authProvider.isLoading) ? null : await validateFields(),
      child: Container(
        margin: const EdgeInsets.only(top: 40),
        width: generalInfoProvider.screenSize.width * 0.18,
        height: generalInfoProvider.screenSize.absoluteHeight * 0.062,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: (!authProvider.isLoading)
              ? Text(
                  (!authProvider.isRecoveringPass)
                      ? "Iniciar sesión"
                      : "Envíar mensaje",
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: generalInfoProvider.screenSize.width * 0.012,
                  ),
                )
              : const ButtonProgressIndicator(),
        ),
      ),
    );
  }

  Future<void> validateFields() async {
    if (emailController.text.isEmpty) {
      LocalNotificationService.showSnackBar(
        type: "error",
        message: "Debes ingresar un correo",
        icon: Icons.error_outline,
      );
      return;
    }
    if (!CodeUtils.checkValidEmail(emailController.text.trim())) {
      LocalNotificationService.showSnackBar(
        type: "error",
        message: "Debes ingresar un correo válido",
        icon: Icons.error_outline,
      );
      return;
    }
    if (authProvider.isRecoveringPass) {
      await authProvider
          .sendPasswordRecoveryMessage(emailController.text.trim());
      return;
    }
    if (passwordController.text.isEmpty) {
      LocalNotificationService.showSnackBar(
        type: "error",
        message: "Debes llenar todos los campos",
        icon: Icons.error_outline,
      );
      return;
    }
    await authProvider.emailSignInOrFail(
      emailController.text.trim(),
      passwordController.text,
    );
  }

  Column buildTextFields() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 35),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          width: generalInfoProvider.screenSize.width * 0.3,
          height: generalInfoProvider.screenSize.absoluteHeight * 0.062,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5),
          ),
          child: TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            cursorColor: UiVariables.primaryColor,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: "Correo",
              hintStyle: TextStyle(
                color: Colors.grey,
                fontSize: generalInfoProvider.screenSize.width * 0.010,
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 400),
          crossFadeState: (!authProvider.isRecoveringPass)
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Container(
            margin: const EdgeInsets.only(top: 25),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            width: generalInfoProvider.screenSize.width * 0.3,
            height: generalInfoProvider.screenSize.absoluteHeight * 0.062,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
            ),
            child: TextField(
              onSubmitted: (String? value) async =>
                  (authProvider.isLoading) ? null : await validateFields(),
              controller: passwordController,
              keyboardType: TextInputType.visiblePassword,
              obscureText: true,
              cursorColor: UiVariables.primaryColor,
              decoration: InputDecoration(
                // suffixIcon: GestureDetector(
                //   onTap: () => authProvider.changePasswordStatus(),
                //   child: Icon(
                //     (authProvider.isShowingPass)
                //         ? Icons.lock_open_outlined
                //         : Icons.lock_clock_outlined,
                //   ),
                // ),
                border: InputBorder.none,
                hintText: "Contraseña",
                hintStyle: TextStyle(
                  color: Colors.grey,
                  fontSize: generalInfoProvider.screenSize.width * 0.010,
                ),
              ),
            ),
          ),
          secondChild: const SizedBox(),
        )
      ],
    );
  }

  Widget buildRecoverPassBtn() {
    return GestureDetector(
      onTap: () => authProvider.changeRecoveringPassStatus(),
      child: Container(
        margin: const EdgeInsets.only(top: 35),
        child: Text(
          (!authProvider.isRecoveringPass)
              ? "¿Olvidaste tu contraseña?"
              : "Volver",
          style: TextStyle(
            color: Colors.white,
            decoration: TextDecoration.underline,
            fontSize: generalInfoProvider.screenSize.width * 0.012,
          ),
        ),
      ),
    );
  }
}
