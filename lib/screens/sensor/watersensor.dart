import 'package:android/connection/connect.dart';
import 'package:flutter/material.dart';
import 'package:android/utils/colors.dart';

class WaterSensors extends StatelessWidget {
  final bool isActive;

  const WaterSensors({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<bool>>(
      valueListenable: Connection.waterReadings,
      builder: (context, readings, _) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.themedColor(context, AppColors.gray200, AppColors.gray800),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "WATER SENSORS",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: readings.length,
                itemBuilder: (context, index) {
                  final ws = readings[index];
                  final dotColor = !isActive
                      ? AppColors.gray700
                      : ws
                          ? AppColors.blue500
                          : AppColors.gray400;
                  final statusText = !isActive
                      ? 'Not Connected'
                      : ws
                          ? 'Wet'
                          : 'Dry';

                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.themedColor(context, AppColors.gray50, AppColors.gray700),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'WS${index + 1}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '◆',
                          style: TextStyle(fontSize: 20, color: dotColor),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          statusText,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
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
