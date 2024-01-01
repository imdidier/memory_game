// import 'package:data_table_2/data_table_2.dart';
// import 'package:flutter/material.dart';

// import '../../../../features/auth/domain/entities/screen_size_entity.dart';

// class CustomDataTable extends StatefulWidget {
//   final String type;
//   final ScreenSize screenSize;
//   double width;
//   double height;
//   CustomDataTable({
//     required this.type,
//     required this.screenSize,
//     this.height = 0,
//     this.width = 0,
//     Key? key,
//   }) : super(key: key);

//   @override
//   State<CustomDataTable> createState() => _CustomDataTableState();
// }

// class _CustomDataTableState extends State<CustomDataTable> {
//   final ScrollController _scrollController = ScrollController();
//   @override
//   Widget build(BuildContext context) {
//     if (widget.width == 0 && widget.height == 0) {
//       widget.width = widget.screenSize.blockWidth;
//       widget.height = widget.screenSize.height * 0.6;
//     }
//     return Scrollbar(
//       controller: _scrollController,
//       thumbVisibility: true,
//       thickness: 10,
//       radius: const Radius.circular(10),
//       scrollbarOrientation: ScrollbarOrientation.bottom,
//       child: SingleChildScrollView(
//         controller: _scrollController,
//         scrollDirection: Axis.horizontal,
//         child: SizedBox(
//           height: widget.height,
//           width: widget.width,
//           child: PaginatedDataTable2(
//             horizontalMargin: 20,
//             columnSpacing: 20,
//             rowsPerPage: (provider.filteredEmployees.length >= 8)
//                 ? 8
//                 : provider.filteredEmployees.length,
//             columns: _getColums(),
//             source: _EmployeesTableSource(provider: provider),
//           ),
//         ),
//       ),
//     );
//   }


//   getRowsPerPage(){}
// }
