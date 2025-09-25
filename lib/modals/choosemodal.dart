import 'package:android/classes/snackbar.dart';
import 'package:android/utils/colors.dart';
import 'package:flutter/material.dart';

class ModelVersionModal extends StatefulWidget {
  final bool show;
  final String title;
  final List<dynamic> versions;
  final String? initialVersion;
  final Function(String) onSave;
  final VoidCallback onClose;

  const ModelVersionModal({
    super.key,
    required this.show,
    required this.title,
    required this.versions,
    this.initialVersion,
    required this.onSave,
    required this.onClose,
  });

  @override
  State<ModelVersionModal> createState() => _ModelVersionModalState();
}

class _ModelVersionModalState extends State<ModelVersionModal> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _scale;

  dynamic selectedVersion;

  @override
  void initState() {
    super.initState();
    selectedVersion = widget.versions.firstWhere(
      (v) => v['version'] == widget.initialVersion,
      orElse: () => widget.versions.isNotEmpty ? widget.versions.first : {},
    );

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);

    if (widget.show) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant ModelVersionModal oldWidget) {
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

    final bgColor = AppColors.themedColor(context, AppColors.white, AppColors.gray900);
    final textColor = AppColors.themedColor(context, AppColors.textLight, AppColors.textDark);
    final borderColor = AppColors.themedColor(context, AppColors.gray300, AppColors.gray700);

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
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(widget.title,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
                        IconButton(icon: Icon(Icons.close, color: textColor), onPressed: widget.onClose),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Versions List
                    ...widget.versions.map((v) {
                      final isSelected = selectedVersion?['version'] == v['version'];
                      return GestureDetector(
                        onTap: () => setState(() => selectedVersion = v),
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.green700 : AppColors.green500,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                v['version'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (v['description'] != null)
                                Text(
                                  v['description'],
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              if (v['precision'] != null)
                                Text(
                                  "Precision: ${v['precision']} | Recall: ${v['recall']}",
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              if (v['accuracy_top1'] != null)
                                Text(
                                  "Accuracy Top 1: ${v['accuracy_top1']} | Accuracy Top 5: ${v['accuracy_top5']}",
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              try {
                                if (selectedVersion != null) {
                                  widget.onSave(selectedVersion['version']!);
                                  AppSnackBar.success(context, 'Model updated successfully');
                                }
                                widget.onClose();
                              } catch (e) {
                                AppSnackBar.error(context, 'Failed to update model');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.green500,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            child: const Text('Save', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: widget.onClose,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.gray500),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
