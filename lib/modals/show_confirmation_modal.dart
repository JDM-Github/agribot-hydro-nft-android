import 'package:android/utils/colors.dart';
import 'package:flutter/material.dart';

Future<bool?> showConfirmationModal({
  required BuildContext context,
  required String title,
  required String message,
  String buttonText = "Confirm"
}) async {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: "Confirmation",
    pageBuilder: (context, anim1, anim2) {
      return const SizedBox.shrink();
    },
    transitionBuilder: (context, anim1, anim2, child) {
      final curved = CurvedAnimation(parent: anim1, curve: Curves.easeInOut);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(curved),
          child: Center(
            child: Material(
              color: AppColors.themedColor(context, AppColors.white, AppColors.gray800),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.themedColor(context, AppColors.textLight, AppColors.textDark))),
                    const SizedBox(height: 12),
                    Text(message,
                        style: TextStyle(
                            fontSize: 14,
                            color: AppColors.themedColor(context, AppColors.textLight, AppColors.textDark))),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: TextButton.styleFrom(
                            backgroundColor: AppColors.red500,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text("Cancel"),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: TextButton.styleFrom(
                            backgroundColor: AppColors.green500,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(buttonText),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 250),
  );
}
