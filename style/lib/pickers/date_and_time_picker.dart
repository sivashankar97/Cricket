import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/platform.dart';

import '../theme/colors.dart';

Future<void> selectDate(
  BuildContext context, {
  String? helpText,
  DateTime? startDate,
  DateTime? endDate,
  required DateTime initialDate,
  required Function(DateTime) onDateSelected,
}) async {
  final now = DateTime.now();
  final minDate = startDate ?? (initialDate.isBefore(now) ? initialDate : now);
  final maxDate = endDate ?? DateTime(now.year + 1, now.month, now.day);

  if (isIOS) {
    DateTime tempDate = initialDate;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext modalContext) {
        return Container(
          height: 300,
          padding: const EdgeInsets.only(top: 6.0),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(modalContext).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: modalContext.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: modalContext.colorScheme.outline,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.of(modalContext).pop(),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: modalContext.colorScheme.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (helpText != null)
                        Text(
                          helpText,
                          style: TextStyle(
                            color: modalContext.colorScheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          DateTime selectedDateTime = DateTime(
                            tempDate.year,
                            tempDate.month,
                            tempDate.day,
                            initialDate.hour,
                            initialDate.minute,
                          );
                          onDateSelected.call(selectedDateTime);
                          Navigator.of(modalContext).pop();
                        },
                        child: Text(
                          'Done',
                          style: TextStyle(
                            color: modalContext.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: initialDate.isBefore(minDate)
                        ? minDate
                        : (initialDate.isAfter(maxDate) ? maxDate : initialDate),
                    minimumDate: minDate,
                    maximumDate: maxDate,
                    onDateTimeChanged: (DateTime newDate) {
                      tempDate = newDate;
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    return;
  }

  showDatePicker(
    context: context,
    helpText: helpText,
    initialDate: initialDate,
    firstDate: minDate,
    lastDate: maxDate,
    builder: (context, child) {
      return Theme(
        data: context.brightness == Brightness.dark
            ? materialThemeDataDark
            : materialThemeDataLight,
        child: child!,
      );
    },
  ).then((selectedDate) {
    if (selectedDate != null) {
      DateTime selectedDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        initialDate.hour,
        initialDate.minute,
      );
      onDateSelected.call(selectedDateTime);
    }
  });
}

Future<void> selectTime(
  BuildContext context, {
  required DateTime initialTime,
  required Function(DateTime) onTimeSelected,
}) async {
  if (isIOS) {
    DateTime tempTime = initialTime;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext modalContext) {
        return Container(
          height: 300,
          padding: const EdgeInsets.only(top: 6.0),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(modalContext).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: modalContext.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: modalContext.colorScheme.outline,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.of(modalContext).pop(),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: modalContext.colorScheme.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          DateTime selectedDateTime = DateTime(
                            initialTime.year,
                            initialTime.month,
                            initialTime.day,
                            tempTime.hour,
                            tempTime.minute,
                          );
                          onTimeSelected.call(selectedDateTime);
                          Navigator.of(modalContext).pop();
                        },
                        child: Text(
                          'Done',
                          style: TextStyle(
                            color: modalContext.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: initialTime,
                    use24hFormat: false,
                    onDateTimeChanged: (DateTime newDateTime) {
                      tempTime = newDateTime;
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    return;
  }

  showTimePicker(
    context: context,
    initialTime: TimeOfDay(
      hour: initialTime.hour,
      minute: initialTime.minute,
    ),
    builder: (context, child) {
      return Theme(
        data: context.brightness == Brightness.dark
            ? materialThemeDataDark
            : materialThemeDataLight,
        child: child!,
      );
    },
  ).then((selectedTime) {
    if (selectedTime != null) {
      DateTime selectedDateTime = DateTime(
        initialTime.year,
        initialTime.month,
        initialTime.day,
        selectedTime.hour,
        selectedTime.minute,
      );
      onTimeSelected.call(selectedDateTime);
    }
  });
}
