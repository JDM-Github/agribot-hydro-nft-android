import 'package:android/connection/connect.dart';
import 'package:flutter/material.dart';
import 'package:android/utils/colors.dart';

class Tcrt5000 extends StatelessWidget {
  final bool isActive;

  const Tcrt5000({super.key, required this.isActive});

  Color _bgColor(bool value) => !isActive ? AppColors.gray700 : (value ? AppColors.black : AppColors.white);

  Color _borderColor(bool value) => !isActive ? AppColors.gray700 : (value ? AppColors.gray600 : AppColors.gray300);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth - 135;

        return Container(
          width: width,
          height: 145,
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
                "TCRT5000",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder<Map<String, dynamic>>(
                valueListenable: Connection.tcrt5000,
                builder: (context, value, _) {
                  final leftValue = value['left'] ?? false;
                  final rightValue = value['right'] ?? false;

                  return Row(
                    children: [
                      _sensorBox("Left", _bgColor(leftValue), _borderColor(leftValue)),
                      const SizedBox(width: 8),
                      _sensorBox("Right", _bgColor(rightValue), _borderColor(rightValue)),
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

  Widget _sensorBox(String label, Color bgColor, Color borderColor) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 70,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
