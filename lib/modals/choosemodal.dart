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
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  late final Animation<double> _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  late final Animation<Offset> _slide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  dynamic selectedVersion;

  @override
  void initState() {
    super.initState();
    selectedVersion = widget.versions.firstWhere(
      (v) => v['version'] == widget.initialVersion,
      orElse: () => widget.versions.isNotEmpty ? widget.versions.first : {},
    );
    if (widget.show) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant ModelVersionModal oldWidget) {
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

    final bgColor = AppColors.themedColor(context, AppColors.white, AppColors.gray800);
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
                          Text(widget.title,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                          IconButton(icon: Icon(Icons.close, color: textColor), onPressed: widget.onClose),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Expanded(
                        child: ListView.builder(
                          itemCount: widget.versions.length,
                          itemBuilder: (context, index) {
                            final v = widget.versions[index];
                            final isSelected = selectedVersion?['version'] == v['version'];
                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              color: AppColors.themedColor(context, AppColors.gray50, AppColors.gray700),
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(v['version'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                          if (v['description'] != null)
                                            Text(v['description'], style: const TextStyle(fontSize: 13)),
                                          if (v['precision'] != null)
                                            Text("Precision: ${v['precision']} | Recall: ${v['recall']}",
                                                style: const TextStyle(fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          selectedVersion = v;
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isSelected ? AppColors.green700 : AppColors.green500,
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: Text(
                                        isSelected ? 'Selected' : 'Select',
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Action buttons
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
                              if (selectedVersion != null) {
                                widget.onSave(selectedVersion['version']);
                                AppSnackBar.success(context, "Version saved!");
                                widget.onClose();
                              }
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
