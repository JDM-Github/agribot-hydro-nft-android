import 'package:flutter/material.dart';
import '../utils/colors.dart';

class AppSnackBar {
  static final Map<String, _SnackbarData> _activeSnackbars = {};

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
    _show(
      context,
      message,
      borderColor: AppColors.blue500,
      textColor: AppColors.blue500,
      autoClose: false,
      id: id,
    );
  }

  static void hide(BuildContext context, {String? id}) {
    if (id != null && _activeSnackbars.containsKey(id)) {
      _activeSnackbars[id]!.dismiss();
      _activeSnackbars.remove(id);
    } else {
      for (var data in _activeSnackbars.values) {
        data.dismiss();
      }
      _activeSnackbars.clear();
    }
  }

  static void _show(
    BuildContext context,
    String message, {
    required Color borderColor,
    required Color textColor,
    bool autoClose = true,
    String? id,
  }) {
    final bgColor = AppColors.themedColor(
      context,
      AppColors.backgroundLight,
      AppColors.backgroundDark,
    );

    final screenWidth = MediaQuery.of(context).size.width;

    late AnimationController controller;
    late OverlayEntry overlayEntry;

    controller = AnimationController(
      vsync: Navigator.of(context),
      duration: const Duration(milliseconds: 300),
    );

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 20,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: FadeTransition(
            opacity: controller.drive(
              Tween<double>(begin: 0, end: 1).chain(CurveTween(curve: Curves.easeInOut)),
            ),
            child: SlideTransition(
              position: controller.drive(
                Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).chain(CurveTween(curve: Curves.easeInOut)),
              ),
              child: Container(
                width: screenWidth - 32,
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
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);
    controller.forward();

    final data = _SnackbarData(entry: overlayEntry, controller: controller);
    if (id != null) {
      _activeSnackbars[id] = data;
    }

    if (autoClose) {
      Future.delayed(const Duration(seconds: 2), () => data.dismiss());
    }
  }
}

class _SnackbarData {
  final OverlayEntry entry;
  final AnimationController controller;
  bool _dismissed = false;

  _SnackbarData({required this.entry, required this.controller});

  void dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    controller.reverse().then((_) {
      entry.remove();
      controller.dispose();
    });
  }
}
