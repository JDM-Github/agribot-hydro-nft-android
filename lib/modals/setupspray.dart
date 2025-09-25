import 'package:android/classes/snackbar.dart';
import 'package:android/utils/struct.dart';
import 'package:flutter/material.dart';
import '../utils/colors.dart';

class SetupSprayModal extends StatefulWidget {
  final bool show;
  final VoidCallback onClose;
  final Spray sprays;

  const SetupSprayModal({
    super.key,
    required this.show,
    required this.onClose,
    required this.sprays,
  });

  @override
  State<SetupSprayModal> createState() => _SetupSprayModalState();
}

class _SetupSprayModalState extends State<SetupSprayModal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );
  late final Animation<double> _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  late final Animation<double> _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);

  late Spray _tempSpray;
  Map<String, dynamic>? selectedSpray;
  Offset tooltipPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _tempSpray = widget.sprays.copy();
    if (widget.show) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant SetupSprayModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    _tempSpray = widget.sprays.copy();
    widget.show ? _controller.forward(from: 0) : _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void applyRecommended(int index, String sprayName) => setState(() => _tempSpray.spray[index] = sprayName);

  void showSprayInfo(TapDownDetails details, Map<String, dynamic> spray) => setState(() {
        selectedSpray = spray;
        tooltipPosition = details.globalPosition;
      });

  void hideSprayInfo() => setState(() => selectedSpray = null);

  @override
  Widget build(BuildContext context) {
    if (!widget.show && _controller.status == AnimationStatus.dismissed) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context).brightness;
    final bgColor = AppColors.themedColor(context, AppColors.white, AppColors.gray900);
    final borderColor = AppColors.themedColor(context, AppColors.gray300, AppColors.gray500);
    final textColor = AppColors.themedColor(context, AppColors.textLight, AppColors.textDark);

    Widget inputRow(int i) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Switch(
                value: _tempSpray.active[i],
                onChanged: (v) => setState(() => _tempSpray.active[i] = v),
              ),
              Text('#${i + 1}', style: TextStyle(color: textColor)),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  onChanged: (v) => _tempSpray.spray[i] = v,
                  decoration: InputDecoration(
                    hintText: 'Spray name',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    filled: true,
                    fillColor: theme == Brightness.light ? AppColors.gray100 : AppColors.gray800,
                  ),
                  controller: TextEditingController(
                    text: _tempSpray.spray[i],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 40,
                child: TextField(
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _tempSpray.duration[i] = int.tryParse(v) ?? 2,
                  decoration: InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: borderColor),
                    ),
                  ),
                  controller: TextEditingController(
                    text: '${_tempSpray.duration[i]}',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 4),
              Text('sec', style: TextStyle(color: textColor)),
              IconButton(
                icon: const Icon(Icons.clear, size: 18, color: Colors.red),
                onPressed: () => setState(() {
                  _tempSpray.spray[i] = '';
                  // _tempSpray.duration[i] = 2;
                  // _tempSpray.active[i] = false;
                }),
              )
            ],
          ),
        );

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
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Setup Spray',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children: List.generate(
                        _tempSpray.spray.length,
                        (i) => inputRow(i),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: widget.onClose,
                          style: TextButton.styleFrom(
                            backgroundColor: AppColors.red500,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 6),
                        TextButton(
                          onPressed: () {
                            try {
                              widget.sprays.spray = List.from(_tempSpray.spray);
                              widget.sprays.active = List.from(_tempSpray.active);
                              widget.sprays.duration = List.from(_tempSpray.duration);

                              AppSnackBar.success(context, "Spray settings saved successfully!");
                            } catch (e) {
                              AppSnackBar.error(context, "Failed to save spray settings: $e");
                            }
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: AppColors.green500,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                          ),
                          child: const Text('Save'),
                        ),
                      ],
                    ),
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
