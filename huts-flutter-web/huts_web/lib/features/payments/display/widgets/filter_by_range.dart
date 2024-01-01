import 'package:animate_do/animate_do.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/utils/code/code_utils.dart';
import 'package:huts_web/core/utils/ui/ui_variables.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/payments/display/providers/payments_provider.dart';
import 'package:huts_web/features/payments/display/widgets/range_calendar_widget.dart';

class FilterByRange extends StatefulWidget {
  final PaymentsProvider paymentsProvider;
  final ScreenSize screenSize;
  final bool isAdmin;
  const FilterByRange(
      {Key? key,
      required this.paymentsProvider,
      required this.screenSize,
      required this.isAdmin})
      : super(key: key);

  @override
  State<FilterByRange> createState() => _FilterByRangeState();
}

class _FilterByRangeState extends State<FilterByRange> {
  bool isLoaded = false;
  @override
  Widget build(BuildContext context) {
    bool isDesktop = widget.screenSize.blockWidth >= 1300;
    return Positioned(
      right: 10,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            decoration: UiVariables.boxDecoration,
            padding: (isDesktop || widget.screenSize.blockWidth >= 580)
                ? const EdgeInsets.symmetric(horizontal: 20, vertical: 10)
                : const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          "Filtrar por rango",
                          style: TextStyle(
                              fontSize: (isDesktop ||
                                      widget.screenSize.blockWidth >= 580)
                                  ? widget.screenSize.width * 0.01
                                  : widget.screenSize.width * 0.014,
                              fontWeight: FontWeight.bold),
                        ),
                        Transform.scale(
                          scale: 0.8,
                          child: CupertinoSwitch(
                              activeColor: UiVariables.primaryColor,
                              value: widget.paymentsProvider.isRangeSelected,
                              onChanged: !widget.isAdmin
                                  ? (val) {
                                      setState(() {
                                        widget.paymentsProvider
                                            .updateIsRangeSelected(val);
                                        if (!widget.paymentsProvider
                                            .isRangeDatesSelected()) {
                                          widget.paymentsProvider
                                              .updateIsEditingDate(val);
                                        }
                                      });
                                    }
                                  : null),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (widget.paymentsProvider.isRangeSelected)
                      Container(
                        padding: const EdgeInsets.only(top: 5),
                        child: widget.paymentsProvider.isRangeDatesSelected()
                            ? Row(
                                children: [
                                  Text(
                                    "${CodeUtils.formatDateWithoutHour(widget.paymentsProvider.calendarProperties.rangeStart!)} - ${CodeUtils.formatDateWithoutHour(widget.paymentsProvider.calendarProperties.rangeEnd!)}",
                                    style: TextStyle(
                                        fontSize:
                                            widget.screenSize.width * 0.0112,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  InkWell(
                                    onTap: () => setState(() {
                                      widget.paymentsProvider
                                          .updateIsEditingDate(!widget
                                              .paymentsProvider.isEditingDate);
                                    }),
                                    child: Icon(
                                        widget.paymentsProvider.isEditingDate
                                            ? Icons.arrow_drop_up
                                            : Icons.arrow_drop_down),
                                  ),
                                ],
                              )
                            : FadeIn(
                                duration: const Duration(milliseconds: 500),
                                child: Text(
                                  "Selecciona el rango de fechas",
                                  style: TextStyle(
                                      fontSize: (isDesktop ||
                                              widget.screenSize.blockWidth >=
                                                  580)
                                          ? widget.screenSize.width * 0.0096
                                          : widget.screenSize.width * 0.014,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                      ),
                    AnimatedSize(
                      curve: Curves.easeInOut,
                      duration: const Duration(milliseconds: 500),
                      child: (widget.paymentsProvider.isRangeSelected)
                          ? Transform.translate(
                              offset: const Offset(0, -10),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  children: [
                                    if (widget.paymentsProvider.isEditingDate)
                                      RangeCalendarWidget(
                                        screenSize: widget.screenSize,
                                      ),
                                  ],
                                ),
                              ),
                            )
                          : const SizedBox(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (widget.isAdmin) {
        widget.paymentsProvider.updateIsRangeSelected(true);
        if (!widget.paymentsProvider.isRangeDatesSelected()) {
          widget.paymentsProvider.updateIsEditingDate(true);
        }
      }
    });
  }
}
