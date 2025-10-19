import 'package:android/connection/connect.dart';
import 'package:flutter/material.dart';
import 'package:android/utils/colors.dart';

class UltrasonicSensor extends StatelessWidget {
  final bool isActive;

  const UltrasonicSensor({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<num>(
      valueListenable: Connection.ultrasonic,
      builder: (context, distance, _) {
        final barWidthPercent = distance.clamp(0, 100).toDouble();

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.themedColor(
              context,
              AppColors.gray200,
              AppColors.gray800,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "ULTRASONIC DISTANCE",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                isActive ? "${distance.toStringAsFixed(1)} cm" : "NOT CONNECTED",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.gray300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Container(
                        height: 8,
                        width: isActive ? constraints.maxWidth * (barWidthPercent / 100) : 0,
                        decoration: BoxDecoration(
                          color: AppColors.green500,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
