import 'package:flutter/material.dart';
import '../utils/colors.dart';

class AppSnackBar {
  static final Map<String, ScaffoldFeatureController<SnackBar, SnackBarClosedReason>> _activeSnackbars = {};

  static void success(BuildContext context, String message) {
    _show(
      context,
      message,
      borderColor: AppColors.green500,
      textColor: AppColors.green500,
      autoClose: true,
    );
  }

  static void error(BuildContext context, String message) {
    _show(
      context,
      message,
      borderColor: AppColors.red500,
      textColor: AppColors.red500,
      autoClose: true,
    );
  }

  static void info(BuildContext context, String message) {
    _show(
      context,
      message,
      borderColor: AppColors.blue500,
      textColor: AppColors.blue500,
      autoClose: true,
    );
  }

  static void warning(BuildContext context, String message) {
    _show(
      context,
      message,
      borderColor: AppColors.orange500,
      textColor: AppColors.orange500,
      autoClose: true,
    );
  }

  static void loading(BuildContext context, String message, {String id = "loading"}) {
    hide(context, id: id);
    final controller = _show(
      context,
      message,
      borderColor: AppColors.blue500,
      textColor: AppColors.blue500,
      autoClose: false,
    );
    _activeSnackbars[id] = controller;
  }

  static void hide(BuildContext context, {String? id}) {
    if (id != null && _activeSnackbars.containsKey(id)) {
      _activeSnackbars[id]?.close();
      _activeSnackbars.remove(id);
    } else {
      ScaffoldMessenger.of(context).clearSnackBars();
      _activeSnackbars.clear();
    }
  }

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> _show(
    BuildContext context,
    String message, {
    required Color borderColor,
    required Color textColor,
    bool autoClose = true,
  }) {
    final bgColor = AppColors.themedColor(
      context,
      AppColors.backgroundLight,
      AppColors.backgroundDark,
    );

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final snackBar = SnackBar(
      padding: EdgeInsets.zero,
      behavior: SnackBarBehavior.fixed,
      backgroundColor: Colors.transparent,
      elevation: 0,
      duration: autoClose ? const Duration(seconds: 2) : const Duration(days: 1),
      content: SizedBox(
        width: screenWidth,
        height: screenHeight,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: screenHeight / 2,
              child: IgnorePointer(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black54,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor, width: 2),
                ),
                child: Text(
                  message,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
