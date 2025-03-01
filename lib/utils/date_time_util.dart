import 'package:flutter/material.dart';

class DateTimeUtil {
  static String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static String formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  static TimeOfDay parseTimeString(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length == 2) {
      return TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 0,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    }
    return const TimeOfDay(hour: 0, minute: 0);
  }

  static List<String> generateTimeSlots() {
    List<String> slots = [];
    DateTime time = DateTime(2024, 1, 1, 8, 0);
    final DateTime endTime = DateTime(2024, 1, 1, 22, 30);

    while (time.isBefore(endTime) || time.isAtSameMomentAs(endTime)) {
      slots.add(
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      );
      time = time.add(const Duration(minutes: 30));
    }

    return slots;
  }

  static Map<String, dynamic> initializeDefaultDateTime() {
    final now = DateTime.now();
    const defaultStartTime = TimeOfDay(hour: 18, minute: 30);
    const defaultEndTime = TimeOfDay(hour: 22, minute: 30);

    DateTime selectedDate = now;
    TimeOfDay startTime;
    TimeOfDay endTime;

    if (now.hour > 22 || (now.hour == 22 && now.minute >= 30)) {
      selectedDate = DateTime(now.year, now.month, now.day + 1);
    }

    if (selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day) {
      final currentMinute = now.minute;
      final roundedMinute = ((currentMinute + 29) ~/ 30) * 30;
      final currentHour = now.hour + (roundedMinute >= 60 ? 1 : 0);
      final roundedMinuteAdjusted = roundedMinute % 60;

      if (currentHour > 22 ||
          (currentHour == 22 && roundedMinuteAdjusted > 30)) {
        selectedDate = DateTime(now.year, now.month, now.day + 1);
        startTime = defaultStartTime;
        endTime = defaultEndTime;
      } else {
        startTime = TimeOfDay(hour: currentHour, minute: roundedMinuteAdjusted);

        final endHour = startTime.hour + 2;
        if (endHour <= 22) {
          endTime = TimeOfDay(hour: endHour, minute: startTime.minute);
        } else {
          endTime = defaultEndTime;
        }
      }
    } else {
      startTime = defaultStartTime;
      endTime = defaultEndTime;
    }

    return {
      'selectedDate': selectedDate,
      'startTime': startTime,
      'endTime': endTime,
    };
  }
}
