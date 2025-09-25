import 'package:android/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:android/widgets/radar_chart.dart';

class CompareModelsModal extends StatefulWidget {
  final Map<String, dynamic> models;
  final bool show;
  final VoidCallback onClose;

  const CompareModelsModal({
    super.key,
    required this.models,
    required this.show,
    required this.onClose,
  });

  @override
  State<CompareModelsModal> createState() => _CompareModelsModalState();
}

class _CompareModelsModalState extends State<CompareModelsModal> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);

    if (widget.show) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant CompareModelsModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !_controller.isAnimating) {
      _controller.forward();
    } else if (!widget.show && !_controller.isAnimating) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show && _controller.status == AnimationStatus.dismissed) {
      return const SizedBox.shrink();
    }

    return FadeTransition(
      opacity: _opacity,
      child: Stack(
        children: [
          GestureDetector(
            onTap: widget.onClose,
            child: Container(
              color: Colors.black.withAlpha(200),
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          Center(
            child: ScaleTransition(
              scale: _scale,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: const BoxConstraints(maxWidth: 500),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.themedColor(
                    context,
                    AppColors.backgroundLight,
                    AppColors.gray800,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Center(
                              child: Text(
                                "Compare Model Versions",
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      if (widget.models["yoloObjectDetection"] != null &&
                          (widget.models["yoloObjectDetection"] as List).isNotEmpty)
                        VersionRadarChart(
                          title: "YOLOv8 Object Detection",
                          models: List<Map<String, dynamic>>.from(widget.models["yoloObjectDetection"]),
                          lightColor: AppColors.blue500,
                          darkColor: AppColors.blue700,
                        ),
                      if (widget.models["yoloStageClassification"] != null &&
                          (widget.models["yoloStageClassification"] as List).isNotEmpty)
                        VersionRadarChart(
                          title: "YOLOv8 Stage Classification",
                          models: List<Map<String, dynamic>>.from(widget.models["yoloStageClassification"]),
                          lightColor: AppColors.purple500,
                          darkColor: AppColors.purple700,
                        ),
                      if (widget.models["maskRCNNSegmentation"] != null &&
                          (widget.models["maskRCNNSegmentation"] as List).isNotEmpty)
                        VersionRadarChart(
                          title: "Mask R-CNN Segmentation",
                          models: List<Map<String, dynamic>>.from(widget.models["maskRCNNSegmentation"]),
                          lightColor: AppColors.red500,
                          darkColor: AppColors.red700,
                        ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.themedColor(
                            context,
                            AppColors.red500,
                            AppColors.red500,
                          ),
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        label: const Text("Close", style: TextStyle(color: AppColors.white)),
                        onPressed: widget.onClose,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
