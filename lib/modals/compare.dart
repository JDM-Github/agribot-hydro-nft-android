import 'package:android/classes/default.dart';
import 'package:android/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:android/widgets/radar_chart.dart';

class CompareModelsModal extends StatefulWidget {
  final Models models;
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
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
  late final Animation<double> _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  late final Animation<Offset> _slide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    if (widget.show) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant CompareModelsModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.show ? _controller.forward(from: 0) : _controller.reverse();
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

    final bgColor = AppColors.themedColor(context, AppColors.gray200, AppColors.gray800);
    final textColor = AppColors.themedColor(context, AppColors.textLight, AppColors.textDark);

    return FadeTransition(
      opacity: _opacity,
      child: Stack(
        children: [
          GestureDetector(
            onTap: widget.onClose,
            child: Container(
              color: Colors.black.withAlpha(150),
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          SlideTransition(
            position: _slide,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Material(
                color: bgColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                elevation: 16,
                child: Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.75,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Compare Model Versions",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                          IconButton(icon: Icon(Icons.close, color: textColor), onPressed: widget.onClose),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              if (widget.models.yoloobjectdetection.isNotEmpty)
                                VersionRadarChart(
                                  title: "YOLOv8 Object Detection",
                                  models: List<Map<String, dynamic>>.from(widget.models.yoloobjectdetection),
                                  lightColor: AppColors.blue500,
                                  darkColor: AppColors.blue700,
                                ),
                              if (widget.models.yolostageclassification.isNotEmpty)
                                VersionRadarChart(
                                  title: "YOLOv8 Stage Classification",
                                  models: List<Map<String, dynamic>>.from(widget.models.yolostageclassification),
                                  lightColor: AppColors.purple500,
                                  darkColor: AppColors.purple700,
                                ),
                              if (widget.models.maskrcnnsegmentation.isNotEmpty)
                                VersionRadarChart(
                                  title: "Mask R-CNN Segmentation",
                                  models: List<Map<String, dynamic>>.from(widget.models.maskrcnnsegmentation),
                                  lightColor: AppColors.red500,
                                  darkColor: AppColors.red700,
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: TextButton(
                          onPressed: widget.onClose,
                          style: TextButton.styleFrom(
                            backgroundColor: AppColors.red500,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Close"),
                        ),
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
