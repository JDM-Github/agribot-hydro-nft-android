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
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
  late final Animation<double> _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  late final Animation<Offset> _slide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  late double selectedValue;

  @override
  void initState() {
    super.initState();
    selectedValue = widget.initialValue;
    if (widget.show) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant ConfidenceModal oldWidget) {
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

    final values = List.generate(10, (i) => 0.1 * (i + 1));

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
                  height: MediaQuery.of(context).size.height * 0.35,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(widget.title,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
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
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.green700 : AppColors.green500,
                                borderRadius: BorderRadius.circular(8),
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
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: widget.onClose,
                            style: TextButton.styleFrom(
                              backgroundColor: AppColors.red500,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: () {
                              widget.onSave(selectedValue);
                              AppSnackBar.success(context, 'Confidence updated successfully');
                              widget.onClose();
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: AppColors.green500,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Save'),
                          ),
                        ],
                      )
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
