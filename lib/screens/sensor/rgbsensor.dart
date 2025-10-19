import 'package:android/connection/connect.dart';
import 'package:flutter/material.dart';
import 'package:android/utils/colors.dart';

class RgbSensor extends StatelessWidget {
  final bool isActive;

  const RgbSensor({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>>(
      valueListenable: Connection.tcs34725,
      builder: (context, value, _) {
        final normalized = value['normalized'] ?? {};
        final r = normalized['r'] ?? 0;
        final g = normalized['g'] ?? 0;
        final b = normalized['b'] ?? 0;
        final colorName = value['color_name'] ?? 'NOT SET';

        return Container(
          width: 125,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.themedColor(context, AppColors.gray200, AppColors.gray800),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Text(
                "RGB SENSOR",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: isActive ? Color.fromARGB(255, r, g, b) : AppColors.gray500,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gray300),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "R:$r  G:$g  B:$b",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Detected: $colorName",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
