import 'package:android/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class ModelViewerWidget extends StatefulWidget {
  const ModelViewerWidget({super.key});

  @override
  State<ModelViewerWidget> createState() => _ModelViewerWidgetState();
}

class _ModelViewerWidgetState extends State<ModelViewerWidget> with SingleTickerProviderStateMixin {
  bool _show3DModel = true;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.gray900,
          borderRadius: BorderRadius.circular(10),
        ),
        child: ModelViewer(
          src: 'assets/models/AGRIBOT.glb',
          alt: "3D Model of Agribot",
          ar: true,
          autoRotate: true,
          cameraControls: true,
          disableZoom: true,
          backgroundColor: AppColors.gray800,
        ),
      ),
    );
  }
}
