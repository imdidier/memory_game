import 'package:animate_do/animate_do.dart';
// import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:huts_web/core/utils/ui/ui_variables.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/general_info/display/providers/general_info_provider.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../code/code_utils.dart';

class CustomDateSelector extends StatefulWidget {
  final bool isVisible;
  final Function onDateSelected;
  const CustomDateSelector({
    this.isVisible = true,
    required this.onDateSelected,
    Key? key,
  }) : super(key: key);

  @override
  State<CustomDateSelector> createState() => _CustomDateSelectorState();
}

class _CustomDateSelectorState extends State<CustomDateSelector> {
  bool isWidgetLoaded = false;

  @override
  void didChangeDependencies() {
    if (isWidgetLoaded) return;
    isWidgetLoaded = true;
    Provider.of<SelectorProvider>(context, listen: false).resetValues();
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return (widget.isVisible)
        ? Container(
            decoration: UiVariables.boxDecoration,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: _SelectorWidget(onDateSelected: widget.onDateSelected),
          )
        : const SizedBox();
  }
}

class SelectorProvider with ChangeNotifier {
  bool isDateSelected = false;
  bool isEditingDate = false;

  CalendarProperties calendarProperties = CalendarProperties(
    calendarFormat: CalendarFormat.month,
    rangeSelectionMode: RangeSelectionMode.toggledOn,
    focusedDay: DateTime.now(),
    firstDay: DateTime(2020, 10, 16),
    lastDay: DateTime.now().add(const Duration(days: 1095)),
    selectedDay: null,
    rangeStart: null,
    rangeEnd: null,
  );

  void resetValues() {
    isDateSelected = false;
    isEditingDate = false;
    calendarProperties = CalendarProperties(
      calendarFormat: CalendarFormat.month,
      rangeSelectionMode: RangeSelectionMode.toggledOn,
      focusedDay: DateTime.now(),
      firstDay: DateTime(2020, 10, 16),
      lastDay: DateTime.now().add(const Duration(days: 1095)),
      selectedDay: null,
      rangeStart: null,
      rangeEnd: null,
    );
  }

  void changeSelectedStatus(bool newValue) {
    isDateSelected = newValue;
    notifyListeners();
  }

  void changeEditingStatus(bool newValue) {
    isEditingDate = newValue;
    notifyListeners();
  }

  void onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    calendarProperties.selectedDay = selectedDay;
    calendarProperties.focusedDay = focusedDay;
    calendarProperties.rangeStart = null;
    calendarProperties.rangeEnd = null;
    calendarProperties.rangeSelectionMode = RangeSelectionMode.toggledOn;
    notifyListeners();
  }

  void onRangeSelected(
      DateTime? startDate, DateTime? endDate, DateTime focusedDay) {
    calendarProperties.selectedDay = null;
    calendarProperties.focusedDay = focusedDay;
    calendarProperties.rangeStart = startDate;
    calendarProperties.rangeEnd = endDate;
    calendarProperties.rangeSelectionMode = RangeSelectionMode.toggledOn;
    notifyListeners();
  }
}

class _SelectorWidget extends StatelessWidget {
  final Function onDateSelected;

  const _SelectorWidget({required this.onDateSelected, Key? key})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    SelectorProvider provider = Provider.of<SelectorProvider>(context);
    ScreenSize screenSize =
        Provider.of<GeneralInfoProvider>(context, listen: false).screenSize;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Align(
        //   alignment: Alignment.center,
        //   child: Row(
        //     mainAxisAlignment: MainAxisAlignment.end,
        //     children: [
        //       Text(
        //         "Filtrar por fecha",
        //         style: TextStyle(fontSize: screenSize.width >= 1120 ? 16 : 12),
        //       ),
        //       Transform.scale(
        //         scale: 0.75,
        //         child: CupertinoSwitch(
        //           activeColor: UiVariables.primaryColor,
        //           value: provider.isDateSelected,
        //           onChanged: (bool? newValue) {
        //             provider.changeSelectedStatus(newValue!);
        //             if (provider.calendarProperties.rangeStart == null) {
        //               provider.changeEditingStatus(newValue);
        //             }
        //           },
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            //  if (provider.isDateSelected)
            Container(
              padding: const EdgeInsets.all(10),
              child: (provider.calendarProperties.rangeStart != null)
                  ? Row(
                      children: [
                        Text(
                          (provider.calendarProperties.rangeEnd == null)
                              ? CodeUtils.formatDateWithoutHour(
                                  provider.calendarProperties.rangeStart!)
                              : "${CodeUtils.formatDateWithoutHour(provider.calendarProperties.rangeStart!)} - ${CodeUtils.formatDateWithoutHour(provider.calendarProperties.rangeEnd!)}",
                          style: TextStyle(
                            fontSize: screenSize.width * 0.0112,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        InkWell(
                          onTap: () => provider
                              .changeEditingStatus(!provider.isEditingDate),
                          child: Icon(
                            provider.isEditingDate
                                ? Icons.arrow_drop_up
                                : Icons.arrow_drop_down,
                            size: 30,
                          ),
                        ),
                      ],
                    )
                  : FadeIn(
                      duration: const Duration(milliseconds: 500),
                      child: Row(
                        children: [
                          Text(
                            "Selecciona una fecha",
                            style: TextStyle(
                              fontSize: screenSize.width * 0.0096,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          InkWell(
                            onTap: () => provider
                                .changeEditingStatus(!provider.isEditingDate),
                            child: Icon(
                              provider.isEditingDate
                                  ? Icons.arrow_drop_up
                                  : Icons.arrow_drop_down,
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            AnimatedSize(
              curve: Curves.easeInOut,
              duration: const Duration(milliseconds: 500),
              child: (provider.isEditingDate)
                  ? Transform.translate(
                      offset: const Offset(0, -10),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        child: (provider.isEditingDate)
                            ? _CalendarWidget(
                                screenSize: screenSize,
                                onRangeSelected: onDateSelected,
                              )
                            : const SizedBox(),
                      ),
                    )
                  : const SizedBox(),
            )
          ],
        )
      ],
    );
  }
}

class _CalendarWidget extends StatefulWidget {
  final ScreenSize screenSize;
  final Function onRangeSelected;
  const _CalendarWidget({
    required this.screenSize,
    required this.onRangeSelected,
    Key? key,
  }) : super(key: key);

  @override
  State<_CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<_CalendarWidget> {
  @override
  Widget build(BuildContext context) {
    SelectorProvider provider = Provider.of<SelectorProvider>(context);
    return SizedBox(
      width: widget.screenSize.width * 0.2,
      child: TableCalendar(
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: widget.screenSize.blockWidth >= 1120 ? 16 : 11),
          weekendStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: widget.screenSize.blockWidth >= 1120 ? 16 : 11),
        ),
        headerStyle: HeaderStyle(
          titleCentered: true,
          titleTextStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: widget.screenSize.blockWidth >= 1120 ? 16 : 11),
        ),
        calendarStyle: CalendarStyle(
          todayDecoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue,
          ),
          rangeHighlightColor: UiVariables.ultraLightRedColor,
          rangeStartTextStyle: TextStyle(
            color: Colors.white,
            fontSize: widget.screenSize.blockWidth >= 1120 ? 16 : 11,
          ),
          rangeStartDecoration: BoxDecoration(
            shape: BoxShape.circle,
            color: UiVariables.primaryColor,
          ),
          rangeEndDecoration: BoxDecoration(
            shape: BoxShape.circle,
            color: UiVariables.primaryColor,
          ),
          defaultTextStyle: const TextStyle(fontSize: 14),
          disabledTextStyle:
              const TextStyle(color: Color(0xFFBFBFBF), fontSize: 14),
          weekendTextStyle: const TextStyle(fontSize: 16),
          outsideTextStyle: const TextStyle(fontSize: 16),
          selectedTextStyle: const TextStyle(fontSize: 16),
          rangeEndTextStyle: TextStyle(
            color: Colors.white,
            fontSize: widget.screenSize.blockWidth >= 1120 ? 16 : 11,
          ),
          todayTextStyle: const TextStyle(fontSize: 16, color: Colors.white),
          holidayTextStyle: const TextStyle(fontSize: 16),
          weekNumberTextStyle: const TextStyle(fontSize: 16),
          withinRangeTextStyle: const TextStyle(fontSize: 16),
        ),
        availableCalendarFormats: const {CalendarFormat.month: "Vista mensual"},
        locale: "es_CO",
        focusedDay: provider.calendarProperties.focusedDay,
        firstDay: provider.calendarProperties.firstDay,
        lastDay: provider.calendarProperties.lastDay,
        selectedDayPredicate: (day) => isSameDay(
          provider.calendarProperties.selectedDay,
          day,
        ),
        calendarFormat: provider.calendarProperties.calendarFormat,
        rangeStartDay: provider.calendarProperties.rangeStart,
        rangeEndDay: provider.calendarProperties.rangeEnd,
        rangeSelectionMode: provider.calendarProperties.rangeSelectionMode,
        onDaySelected: (selectedDay, focusedDay) {
          if (isSameDay(provider.calendarProperties.selectedDay, selectedDay)) {
            return;
          }
          provider.onDaySelected(selectedDay, focusedDay);
        },
        onRangeSelected: (start, end, focusedDay) {
          provider.onRangeSelected(start, end, focusedDay);
          widget.onRangeSelected(start, end);
        },
        onFormatChanged: (format) {
          if (provider.calendarProperties.calendarFormat == format) {
            return;
          }
          setState(() {
            provider.calendarProperties.calendarFormat = format;
          });
        },
        onPageChanged: (focusedDay) {
          provider.calendarProperties.focusedDay = focusedDay;
        },
      ),
    );
  }
}

class CalendarProperties {
  CalendarFormat calendarFormat;
  RangeSelectionMode rangeSelectionMode;
  DateTime focusedDay;
  DateTime firstDay;
  DateTime lastDay;
  DateTime? selectedDay;
  DateTime? rangeStart;
  DateTime? rangeEnd;

  CalendarProperties({
    required this.calendarFormat,
    required this.rangeSelectionMode,
    required this.focusedDay,
    required this.firstDay,
    required this.lastDay,
    required this.selectedDay,
    required this.rangeStart,
    required this.rangeEnd,
  });
}
