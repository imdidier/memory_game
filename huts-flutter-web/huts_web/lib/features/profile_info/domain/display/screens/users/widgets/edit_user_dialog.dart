// import 'dart:js';

// import 'package:flutter/material.dart';
// import 'package:flutter/src/foundation/key.dart';
// import 'package:flutter/src/widgets/framework.dart';
// import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
// import 'package:huts_web/features/get_general_info/display/providers/general_info_provider.dart';
// import 'package:provider/provider.dart';

// class UserEditDialog extends StatefulWidget {
//   const UserEditDialog({Key? key}) : super(key: key);

//   @override
//   State<UserEditDialog> createState() => _UserEditDialogState();
// }

// class _UserEditDialogState extends State<UserEditDialog> {
//   bool isLoadedDialog = false;
//   late ScreenSize screenSize;
//   @override
//   void didChangeDependencies() {
//     if (!isLoadedDialog) {
//       isLoadedDialog = true;
//       screenSize = Provider.of<GeneralInfoProvider>(context).screenSize;
//     }
//     super.didChangeDependencies();
//   }
//   @override
//   Widget build(BuildContext ctx) {
//     GeneralInfoProvider generalInfoProvider = Provider.of(editUserContext);
//     return AlertDialog(
//             title: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: const [
//                 Text('Editar Datos'),
//                 Text(
//                   'Edita los datos del usuario y reasigna su rol si es necesario',
//                   style: TextStyle(fontSize: 13),
//                 ),
//               ],
//             ),
//             content: StatefulBuilder(
//               builder: ((context, setState) {
//                 return SizedBox(
//                   height: screenSize.height * 0.70,
//                   child: Column(children: [
//                     buildEditForm(screenSize, context),
//                   ]),
//                 );
//               }),
//             ),
//           );
//   }
// }