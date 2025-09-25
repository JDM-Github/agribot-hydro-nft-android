import 'package:android/utils/colors.dart';
import 'package:flutter/material.dart';

class LiveFeedScreen extends StatelessWidget {
  const LiveFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.themedColor(context, AppColors.gray100, AppColors.gray900),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              color: AppColors.themedColor(context, AppColors.gray200, AppColors.gray950),
              alignment: Alignment.center,
              child: Text(
                "Camera Preview",
                style: TextStyle(
                  color: AppColors.themedColor(context, AppColors.gray900, AppColors.gray50),
                  fontSize: 18,
                ),
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.themedColor(context, AppColors.gray50, AppColors.gray800),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "DETECTION HISTORY",
                      style: TextStyle(
                        color: AppColors.themedColor(context, AppColors.gray900, AppColors.gray50),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Divider(color: AppColors.themedColor(context, AppColors.gray300, AppColors.gray700)),

                    Expanded(
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _detectionCard(context, "Tomato Plant", "Late Blight"),
                          _detectionCard(context, "Cucumber Plant", "Powdery Mildew"),
                          _detectionCard(context, "Strawberry Plant", "Bacterial Spot"),
                          _detectionCard(context, "Lettuce", "Downy Mildew"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _controlButton(context, "Run", AppColors.green500, AppColors.green700),
                _controlButton(context, "Pause", AppColors.gray500, AppColors.gray700),
                _controlButton(context, "Stop", AppColors.red500, AppColors.red700),
                _controlButton(context, "View Records", AppColors.blue500, AppColors.blue700),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detectionCard(BuildContext context, String plantName, String disease) {
    return Container(
      width: 140,
      margin: EdgeInsets.only(right: 10),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.themedColor(context, AppColors.gray100, AppColors.gray900),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.themedColor(context, AppColors.gray300, AppColors.gray700),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text("600 x 400",
                  style: TextStyle(color: AppColors.themedColor(context, AppColors.gray700, AppColors.gray400))),
            ),
          ),
          SizedBox(height: 5),
          Text(plantName,
              style: TextStyle(
                  color: AppColors.themedColor(context, AppColors.gray900, AppColors.gray50),
                  fontWeight: FontWeight.bold)),
          Text(disease, style: TextStyle(color: AppColors.red500, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _controlButton(BuildContext context, String text, Color color, Color darkerColor) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: AppColors.gray50,
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(color: darkerColor, width: 1.5),
          ),
          elevation: 3,
        ),
        child: Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
