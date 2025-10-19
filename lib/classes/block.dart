import 'package:android/utils/colors.dart';
import 'package:flutter/material.dart';

class NotConnected extends StatelessWidget {
  const NotConnected({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.themedColor(context, AppColors.gray200, AppColors.gray800),
      alignment: Alignment.center,
      child: Text(
        "You are not connected",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class StopRobot extends StatelessWidget {
  final String whatRunning;
  const StopRobot({super.key, required this.whatRunning});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.themedColor(context, AppColors.gray200, AppColors.gray800),
      alignment: Alignment.center,
      child: Text(
        "Cannot open/start $whatRunning running",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
