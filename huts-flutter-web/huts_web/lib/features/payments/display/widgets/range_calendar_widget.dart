import 'package:flutter/material.dart';
import 'package:huts_web/core/utils/ui/ui_variables.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/payments/display/providers/payments_provider.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class RangeCalendarWidget extends StatelessWidget {
  final ScreenSize screenSize;
  const RangeCalendarWidget({
    required this.screenSize,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    PaymentsProvider provider = Provider.of<PaymentsProvider>(context);
    return SizedBox(
      width: (screenSize.blockWidth >= 1300)
          ? screenSize.width * 0.18
          : screenSize.width * 0.3,
      child: TableCalendar(
        headerStyle: const HeaderStyle(
          titleCentered: true,
          titleTextStyle: TextStyle(fontWeight: FontWeight.bold),
        ),
        calendarStyle: CalendarStyle(
          todayDecoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue,
          ),
          rangeHighlightColor: UiVariables.ultraLightRedColor,
          rangeStartTextStyle: const TextStyle(color: Colors.white),
          rangeStartDecoration: BoxDecoration(
            shape: BoxShape.circle,
            color: UiVariables.primaryColor,
          ),
          rangeEndDecoration: BoxDecoration(
            shape: BoxShape.circle,
            color: UiVariables.primaryColor,
          ),
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
          if (!isSameDay(
              provider.calendarProperties.selectedDay, selectedDay)) {
            provider.onDaySelected(selectedDay, focusedDay);
          }
        },
        onRangeSelected: (start, end, focusedDay) {
          provider.onRangeSelected(
            start,
            end,
            context,
          );
        },
        onFormatChanged: (format) {
          if (provider.calendarProperties.calendarFormat == format) return;
          provider.onFormatChanged(format);
        },
        onPageChanged: (focusedDay) {
          provider.calendarProperties.focusedDay = focusedDay;
        },
      ),
    );
  }
}
