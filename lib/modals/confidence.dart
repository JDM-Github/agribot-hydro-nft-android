import 'package:android/classes/snackbar.dart';
import 'package:android/utils/colors.dart';
import 'package:flutter/material.dart';

class ConfidenceModal extends StatefulWidget {
  final bool show;
  final String title;
  final double initialValue;
  final Function(double) onSave;
  final VoidCallback onClose;

  const ConfidenceModal({
    super.key,
    required this.show,
    required this.title,
    required this.initialValue,
    required this.onSave,
    required this.onClose,
  });

  @override
  State<ConfidenceModal> createState() => _ConfidenceModalState();
}

class _ConfidenceModalState extends State<ConfidenceModal> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _scale;

  late double selectedValue;

  @override
  void initState() {
    super.initState();
    selectedValue = widget.initialValue;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);

    if (widget.show) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant ConfidenceModal oldWidget) {
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
    if (!widget.show && _controller.status == AnimationStatus.dismissed) return const SizedBox.shrink();

    final bgColor = AppColors.themedColor(context, AppColors.white, AppColors.gray900);
    final textColor = AppColors.themedColor(context, AppColors.textLight, AppColors.textDark);
    final borderColor = AppColors.themedColor(context, AppColors.gray300, AppColors.gray700);

    final values = List.generate(10, (i) => 0.1 * (i + 1));

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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(widget.title,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
                        IconButton(icon: Icon(Icons.close, color: textColor), onPressed: widget.onClose),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: values.map((v) {
                        final isSelected = (v - selectedValue).abs() < 0.01;
                        return GestureDetector(
                          onTap: () => setState(() => selectedValue = v),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.green700 : AppColors.green500,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              v.toStringAsFixed(1),
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              try {
                                widget.onSave(selectedValue);
                                AppSnackBar.success(context, 'Confidence updated successfully');
                                widget.onClose();
                              } catch (e) {
                                AppSnackBar.error(context, 'Failed to update confidence');
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
