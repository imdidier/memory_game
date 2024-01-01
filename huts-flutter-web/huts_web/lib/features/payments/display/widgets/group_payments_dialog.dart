import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/general_info/display/providers/general_info_provider.dart';
import 'package:huts_web/features/payments/display/providers/payments_provider.dart';
import 'package:huts_web/features/payments/display/widgets/datatables/tables/requests_details_data_table.dart';
import 'package:huts_web/features/payments/domain/entities/payment_entity.dart';
import 'package:provider/provider.dart';

class GroupPaymentsDialog extends StatefulWidget {
  final ScreenSize screenSize;
  final Payment payment;
  final bool isClient;
  const GroupPaymentsDialog(
      {required this.screenSize,
      required this.payment,
      required this.isClient,
      Key? key})
      : super(key: key);

  @override
  State<GroupPaymentsDialog> createState() => _GroupPaymentsDialogState();
}

class _GroupPaymentsDialogState extends State<GroupPaymentsDialog> {
  TextEditingController searchController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    PaymentsProvider paymentsProvider = Provider.of<PaymentsProvider>(context);
    return Stack(
      alignment: Alignment.center,
      children: [
        if (paymentsProvider.isShowingDetails)
          Container(
            height: double.infinity,
            width: double.infinity,
            color: Colors.black26,
          ),
        ZoomIn(
          child: Container(
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12)),
            width: widget.screenSize.blockWidth * 0.85,
            height: widget.screenSize.blockWidth <= 920
                ? widget.screenSize.height * 0.9
                : widget.payment.employeeRequests.length < 6
                    ? widget.screenSize.height * 0.7
                    : widget.screenSize.height * 0.9,
            child: SingleChildScrollView(
              child: buildBody(paymentsProvider),
            ),
          ),
        ),
      ],
    );
  }

  Container buildBody(PaymentsProvider paymentsProvider) {
    ScreenSize screenSize =
        Provider.of<GeneralInfoProvider>(context).screenSize;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: RequestsDetailsDataTable(
        payment: widget.payment,
        screenSize: screenSize,
        isClient: widget.isClient,
      ),
    );
  }

  Container buildHeader(PaymentsProvider provider) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white70,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Detalle de solicitudes del colaborador",
                style: TextStyle(
                    color: Colors.black,
                    fontSize: widget.screenSize.width * 0.014,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(width: 15),
          GestureDetector(
            onTap: () => provider.updateDetailsStatus(false, widget.isClient),
            child: Icon(
              Icons.close,
              color: Colors.black,
              size: widget.screenSize.width * 0.018,
            ),
          ),
        ],
      ),
    );
  }
}
