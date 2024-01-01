import 'package:flutter/material.dart';
import 'package:huts_web/core/services/navigation_service.dart';
import 'package:huts_web/core/utils/code/code_utils.dart';
import 'package:huts_web/core/utils/ui/widgets/general/custom_cupertino_date_picker.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/requests/display/providers/create_event_provider.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class DateTimePickerDialog {
  static Future<DateTime?> show(ScreenSize screenSize, bool isCalendarEnabled,
      DateTime? startDate, DateTime? currentDate,
      {bool isTimeEnabled = true,
      DateTime? eventDate,
      int maxDaysFromStart = 90,
      bool fromClientEditRequestEndTime = false}) async {
    BuildContext? globalContext = NavigationService.getGlobalContext();

    if (globalContext == null) return null;
    DateTime? dateResp = await showDialog(
      context: globalContext,
      barrierDismissible: false,
      builder: (BuildContext dialogCtx) {
        return WillPopScope(
          child: AlertDialog(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(15)),
            ),
            titlePadding: EdgeInsets.zero,
            title: DateTimePicker(
              screenSize: screenSize,
              isCalendarEnabled: isCalendarEnabled,
              startDate: startDate,
              currentSelectedDate: currentDate,
              isTimeEnabled: isTimeEnabled,
              eventDate: eventDate,
              maxDaysFromStart: maxDaysFromStart,
              fromClientEditRequestEndTime: fromClientEditRequestEndTime,
            ),
          ),
          onWillPop: () async => false,
        );
      },
    );

    return dateResp;
  }
}

class DateTimePicker extends StatefulWidget {
  final ScreenSize screenSize;
  final bool isCalendarEnabled;
  final DateTime? startDate;
  final DateTime? currentSelectedDate;
  final bool isTimeEnabled;
  final DateTime? eventDate;
  final int maxDaysFromStart;
  final bool fromClientEditRequestEndTime;
  const DateTimePicker({
    Key? key,
    required this.screenSize,
    required this.isCalendarEnabled,
    required this.startDate,
    required this.isTimeEnabled,
    required this.eventDate,
    required this.maxDaysFromStart,
    this.currentSelectedDate,
    required this.fromClientEditRequestEndTime,
  }) : super(key: key);

  @override
  State<DateTimePicker> createState() => _DateTimePickerState();
}

class _DateTimePickerState extends State<DateTimePicker> {
  final ScrollController scrollController = FixedExtentScrollController();

  bool isWidgetLoaded = false;
  DateTime currentDate = DateTime.now().add(
    Duration(
      minutes: 30 - DateTime.now().minute % 30,
    ),
  );
  bool isFirst = false;
  late DateTime focusedDay;
  late DateTime firstDay;
  late DateTime lastDay;
  DateTime? selectedDay;
  DateTime? rangeStart;
  DateTime? rangeEnd;
  RangeSelectionMode rangeSelectionMode = RangeSelectionMode.disabled;
  late TimeOfDay selectedTime;
  late CreateEventProvider createEventProvider;
  DateTime? finishedDate;
  @override
  void didChangeDependencies() {
    if (isWidgetLoaded) return;
    isWidgetLoaded = true;
    createEventProvider = Provider.of<CreateEventProvider>(context);

    if (widget.currentSelectedDate == null) {
      selectedDay = (widget.startDate != null)
          ? widget.startDate!
          : (!widget.isCalendarEnabled)
              ? createEventProvider.currentStartDate
              : currentDate;
      focusedDay = (widget.startDate != null)
          ? widget.startDate!
          : (!widget.isCalendarEnabled)
              ? createEventProvider.currentStartDate!
              : currentDate;
    } else {
      selectedDay = widget.currentSelectedDate;
      focusedDay = widget.currentSelectedDate!;
    }

    selectedTime =
        TimeOfDay(hour: currentDate.hour, minute: currentDate.minute);
    firstDay = currentDate;
    lastDay = firstDay.add(Duration(days: widget.maxDaysFromStart));

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.screenSize.blockWidth >= 920
          ? widget.screenSize.blockWidth * 0.5
          : widget.screenSize.blockWidth,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          buildBody(),
          buildHeader(),
          buildConfirmBtn(),
        ],
      ),
    );
  }

  Positioned buildConfirmBtn() {
    return Positioned(
      bottom: 20,
      right: 30,
      left: 20,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop(selectedDay);
        },
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              "Confirmar",
              style: TextStyle(
                color: Colors.white,
                fontSize: widget.screenSize.width * 0.011,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Container buildBody() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      width: widget.screenSize.blockWidth >= 920
          ? widget.screenSize.blockWidth * 0.5
          : widget.screenSize.blockWidth,
      height: widget.screenSize.blockWidth >= 920
          ? widget.screenSize.height * 0.5
          : widget.screenSize.height * 0.55,
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Container(
        margin: const EdgeInsets.only(top: 60),
        child: (widget.isTimeEnabled)
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  buildDatePicker(),
                  buildTimePicker(),
                ],
              )
            : buildDatePicker(),
      ),
    );
  }

  Widget buildDatePicker() {
    DateTime firstDate = DateTime.now().subtract(
      const Duration(days: 365),
    );

    finishedDate ??= selectedDay;

    if (widget.fromClientEditRequestEndTime) {
      DateTime currentDate = DateTime.now();

      if (!(currentDate.isBefore(widget.startDate!) &&
          widget.startDate!.difference(currentDate).inHours >= 12)) {
        firstDate = finishedDate ??
            DateTime.now().subtract(
              const Duration(days: 365),
            );
      }
    }

    return SizedBox(
      width: widget.isTimeEnabled && widget.screenSize.blockWidth <= 920
          ? widget.screenSize.blockWidth * 0.48
          : widget.isTimeEnabled
              ? widget.screenSize.blockWidth * 0.3
              : widget.screenSize.blockWidth,
      child: TableCalendar(
        rowHeight: 40,
        calendarStyle: CalendarStyle(
          defaultTextStyle: TextStyle(
              fontSize: widget.screenSize.blockWidth >= 920 ? 14 : 10),
          holidayTextStyle: TextStyle(
            color: const Color(0xFF5C6BC0),
            fontSize: widget.screenSize.blockWidth >= 920 ? 14 : 10,
          ),
          disabledTextStyle: TextStyle(
            color: const Color(0xFFBFBFBF),
            fontSize: widget.screenSize.blockWidth >= 920 ? 14 : 10,
          ),
          outsideTextStyle: TextStyle(
            color: const Color(0xFFAEAEAE),
            fontSize: widget.screenSize.blockWidth >= 920 ? 14 : 10,
          ),
          weekendTextStyle: TextStyle(
            color: const Color(0xFF5A5A5A),
            fontSize: widget.screenSize.blockWidth >= 920 ? 14 : 10,
          ),
          withinRangeTextStyle: TextStyle(
              fontSize: widget.screenSize.blockWidth >= 1120 ? 14 : 10),
          isTodayHighlighted: false,
          selectedDecoration: const BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
        ),
        availableCalendarFormats: const {CalendarFormat.month: "Vista mensual"},
        locale: "es_CO",
        focusedDay: focusedDay,
        rangeSelectionMode: rangeSelectionMode,
        firstDay: firstDate,
        lastDay: lastDay,
        rangeStartDay: rangeStart,
        rangeEndDay: rangeEnd,
        selectedDayPredicate: (day) => isSameDay(
          selectedDay,
          day,
        ),
        onDaySelected: (newSelectedDay, newFocusedDay) {
          if (!isSameDay(selectedDay, newSelectedDay)) {
            setState(() {
              selectedDay = DateTime(
                newSelectedDay.year,
                newSelectedDay.month,
                newSelectedDay.day,
                selectedTime.hour,
                selectedTime.minute,
              );
              focusedDay = newFocusedDay;
              rangeStart = null;
              rangeEnd = null;
              rangeSelectionMode = RangeSelectionMode.disabled;
            });
          }
        },
        onRangeSelected: (newStart, newEnd, newFocusedDay) {
          setState(() {
            selectedDay = null;
            focusedDay = newFocusedDay;
            rangeStart = newStart;
            rangeEnd = newEnd;
            rangeSelectionMode = RangeSelectionMode.disabled;
          });
        },
        onPageChanged: (newFocusedDay) {
          focusedDay = newFocusedDay;
        },
        enabledDayPredicate: (DateTime? date) => widget.isCalendarEnabled,
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            color: const Color(0xFF4F4F4F),
            fontSize: widget.screenSize.blockWidth >= 1120 ? 15 : 10,
            fontWeight: FontWeight.bold,
          ),
          weekendStyle: TextStyle(
            color: const Color(0xFF4F4F4F),
            fontSize: widget.screenSize.blockWidth >= 1120 ? 15 : 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  bool isSameDatesDay(DateTime? firstDate, DateTime? secondDate) {
    if (firstDate == null || secondDate == null) return false;
    if (firstDate.year != secondDate.year) return false;
    if (firstDate.month != secondDate.month) return false;
    if (firstDate.day != secondDate.day) return false;
    if (firstDate.day < secondDate.day) return false;

    return true;
  }

  Widget buildTimePicker() {
    DateTime? minimumDate;
    finishedDate ??= selectedDay;

    if (!widget.fromClientEditRequestEndTime) {
      minimumDate = widget.eventDate;
    } else {
      DateTime currentDate = DateTime.now();

      if (currentDate.isBefore(widget.startDate!) &&
          widget.startDate!.difference(currentDate).inHours >= 12) {
        minimumDate = widget.eventDate;
      } else {
        minimumDate = (isSameDatesDay(selectedDay, finishedDate))
            ? finishedDate
            : widget.eventDate;
      }
    }

    return SizedBox(
      height: 350,
      width: widget.screenSize.blockWidth >= 920
          ? widget.screenSize.blockWidth * 0.1
          : widget.screenSize.blockWidth * 0.2,
      child: Transform.scale(
        scale: widget.screenSize.blockWidth >= 920 ? 0.8 : 0.5,
        child: CustomCupertinoDatePicker(
          minimumDate: minimumDate,
          minuteInterval: 30,
          initialDateTime: widget.eventDate ?? selectedDay,
          use24hFormat: true,
          mode: CustomCupertinoDatePickerMode.time,
          onDateTimeChanged: (DateTime date) {
            if (selectedDay == null) return;
            setState(() {
              isFirst = true;
              selectedDay = DateTime(
                selectedDay!.year,
                selectedDay!.month,
                selectedDay!.day,
                date.hour,
                date.minute,
              );
            });
          },
        ),
      ),
    );
  }

  Widget buildHeader() {
    return Container(
      width: (widget.screenSize.blockWidth >= 920)
          ? widget.screenSize.blockWidth * 0.5
          : widget.screenSize.blockWidth,
      decoration: const BoxDecoration(
        color: Colors.blue, //UiVariables.primaryColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () {
              Navigator.of(context).pop(null);
            },
            child: Icon(
              Icons.close,
              color: Colors.white,
              size: widget.screenSize.width * 0.018,
            ),
          ),
          Text(
            (widget.isTimeEnabled)
                ? CodeUtils.formatDate(selectedDay!)
                : CodeUtils.formatDate(selectedDay!).split(" ")[0],
            style: TextStyle(
              color: Colors.white,
              fontSize: widget.screenSize.width * 0.013,
            ),
          ),
        ],
      ),
    );
  }
}
