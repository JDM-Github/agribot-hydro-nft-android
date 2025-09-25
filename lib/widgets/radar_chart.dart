import 'package:android/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class VersionRadarChart extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> models;
  final Color lightColor;
  final Color darkColor;

  const VersionRadarChart({
    super.key,
    required this.title,
    required this.models,
    required this.lightColor,
    required this.darkColor,
  });

  static const List<String> metricKeys = [
    "accuracy_top1",
    "accuracy_top5",
    "precision",
    "recall",
    "mAP50",
    "mAP50_95",
  ];

  static const Map<String, String> metricLabels = {
    "accuracy_top1": "Acc@1",
    "accuracy_top5": "Acc@5",
    "precision": "Precision",
    "recall": "Recall",
    "mAP50": "mAP50",
    "mAP50_95": "mAP50-95",
  };

  List<RadarDataSet> _buildDataSets(BuildContext context) {
    final themedColor = AppColors.themedColor(context, lightColor, darkColor);

    return models.asMap().entries.map((entry) {
      final i = entry.key;
      final model = entry.value;

      final values = metricKeys.map((key) {
        final val = double.tryParse(model[key]?.toString() ?? "-1");
        return (val != null && val >= 0) ? val * 100 : 0.0;
      }).toList();

      // Alternate colors for multiple models
      final baseColor = themedColor.withOpacity(1 - (i * 0.2).clamp(0, 0.8));

      return RadarDataSet(
        fillColor: baseColor.withAlpha(50),
        borderColor: baseColor,
        entryRadius: 3,
        borderWidth: 2,
        dataEntries: values.map((v) => RadarEntry(value: v)).toList(),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      elevation: 3,
      color: AppColors.themedColor(
        context,
        Colors.white,
        AppColors.gray900,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 400),
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.themedColor(
                      context,
                      AppColors.textLight,
                      AppColors.textDark,
                    ),
                  ),
              child: Text(title),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 220,
              child: RadarChart(
                RadarChartData(
                  radarShape: RadarShape.polygon,
                  dataSets: _buildDataSets(context),
                  radarBorderData: const BorderSide(color: AppColors.gray400),
                  tickCount: 4,
                  getTitle: (index, angle) {
                    final label = VersionRadarChart.metricLabels[VersionRadarChart.metricKeys[index]]!;
                    return RadarChartTitle(
                      text: label,
                      angle: angle,
                    );
                  },
                  ticksTextStyle: TextStyle(
                    fontSize: 9,
                    color: AppColors.themedColor(
                      context,
                      AppColors.gray600,
                      AppColors.gray300,
                    ),
                  ),
                  gridBorderData: BorderSide(
                    color: AppColors.themedColor(
                      context,
                      AppColors.gray300,
                      AppColors.gray800,
                    ),
                    width: 0.8,
                  ),
                  radarBackgroundColor: AppColors.themedColor(
                    context,
                    AppColors.gray100,
                    AppColors.gray900,
                  ),
                ),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
