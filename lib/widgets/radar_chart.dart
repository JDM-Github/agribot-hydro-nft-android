import 'package:android/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class VersionRadarChart extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> models;
  final Color lightColor;
  final Color darkColor;

  VersionRadarChart({
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

  final List<Color> _defaultColors = [
    Colors.blueAccent,
    Colors.greenAccent,
    Colors.orangeAccent,
    Colors.purpleAccent,
  ];

  List<RadarDataSet> _buildDataSets(BuildContext context) {
    return models.asMap().entries.map((entry) {
      final i = entry.key;
      final model = entry.value;

      final values = metricKeys.map((key) {
        final val = double.tryParse(model[key]?.toString() ?? "-1");
        return (val != null && val >= 0) ? val * 100 : 0.0;
      }).toList();

      final baseColor = _defaultColors[i % _defaultColors.length].withOpacity(0.8);

      return RadarDataSet(
        fillColor: baseColor.withAlpha(70),
        borderColor: baseColor,
        borderWidth: 3,
        entryRadius: 4.5,
        dataEntries: values.map((v) => RadarEntry(value: v)).toList(),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      elevation: 4,
      color: AppColors.themedColor(
        context,
        Colors.white,
        AppColors.gray900,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                  radarShape: RadarShape.circle,
                  dataSets: _buildDataSets(context),
                  radarBorderData: BorderSide(
                    color: AppColors.themedColor(
                      context,
                      AppColors.gray400,
                      AppColors.gray600,
                    ),
                  ),
                  tickCount: 4,
                  ticksTextStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.themedColor(
                      context,
                      AppColors.gray700,
                      AppColors.gray200,
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
                  tickBorderData: const BorderSide(color: AppColors.gray600),
                  getTitle: (index, angle) {
                    final label = VersionRadarChart.metricLabels[VersionRadarChart.metricKeys[index]]!;
                    return RadarChartTitle(text: label, angle: angle);
                  },
                  // radarTouchData: RadarTouchData(
                  //   enabled: true,
                  //   touchCallback: (event, response) {
                  //     if (response != null && response.touchedSpot != null) {
                  //       final touchedEntry = response.touchedSpot!.touchedRadarEntry;
                  //       final value = touchedEntry.value;
                  //       ScaffoldMessenger.of(context).showSnackBar(
                  //         SnackBar(
                  //           content: Text('Touched value: ${value.toStringAsFixed(2)}%'),
                  //           duration: const Duration(milliseconds: 800),
                  //         ),
                  //       );
                  //     }
                  //   },
                  // ),

                ),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: models.asMap().entries.map((entry) {
                final i = entry.key;
                final modelName = entry.value['name'] ?? 'Model ${i + 1}';
                final color = _defaultColors[i % _defaultColors.length];
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 12, height: 12, color: color),
                    const SizedBox(width: 4),
                    Text(
                      modelName,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.themedColor(
                          context,
                          AppColors.gray800,
                          AppColors.gray200,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
