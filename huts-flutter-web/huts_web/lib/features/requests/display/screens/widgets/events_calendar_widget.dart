import 'package:flutter/material.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/requests/display/providers/get_requests_provider.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../../core/utils/ui/ui_variables.dart';

class EventsCalendarWidget extends StatelessWidget {
  final String clientId;
  final ScreenSize screenSize;
  const EventsCalendarWidget({
    required this.clientId,
    required this.screenSize,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    GetRequestsProvider provider = Provider.of<GetRequestsProvider>(context);
    return SizedBox(
      width: (screenSize.blockWidth >= 1300)
          ? screenSize.width * 0.3
          : screenSize.width,
      child: TableCalendar(
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
            clientId,
            start,
            end,
            focusedDay,
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
