import 'package:android/utils/colors.dart';
import 'package:flutter/material.dart';

Future<DateTime?> showThemedDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate ?? DateTime(2000),
    lastDate: lastDate ?? DateTime(2100),
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme(
            brightness: isDark ? Brightness.dark : Brightness.light,
            primary: AppColors.green500, 
            onPrimary: AppColors.white,
            secondary: AppColors.green500,
            onSecondary: AppColors.white,
            surface: AppColors.themedColor(context, AppColors.white, AppColors.gray800),
            onSurface: AppColors.themedColor(context, AppColors.textLight, AppColors.textDark),
            error: AppColors.red500,
            onError: AppColors.white,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.green500,
            ),
          ),
        ),
        child: child!,
      );
    },
  );
}

Future<TimeOfDay?> showThemedTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return showTimePicker(
    context: context,
    initialTime: initialTime,
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme(
            brightness: isDark ? Brightness.dark : Brightness.light,
            primary: AppColors.themedColor(context, AppColors.gray200, AppColors.gray500),
            onPrimary: AppColors.white,
            secondary: AppColors.green500,
            onSecondary: AppColors.white,
            surface: AppColors.themedColor(context, AppColors.white, AppColors.gray800),
            onSurface: AppColors.themedColor(context, AppColors.textLight, AppColors.textDark),
            error: AppColors.red500,
            onError: AppColors.white,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.green500, 
            ),
          ),
          timePickerTheme: TimePickerThemeData(
            dialHandColor: AppColors.green500,
            hourMinuteTextColor: AppColors.themedColor(context, AppColors.green500, AppColors.white),
            entryModeIconColor: AppColors.green500,
          ),
        ),
        child: child!,
      );
    },
  );
}
