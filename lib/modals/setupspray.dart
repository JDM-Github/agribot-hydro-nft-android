import 'package:flutter/material.dart';
import 'package:android/classes/snackbar.dart';
import 'package:android/utils/struct.dart';
import 'package:android/widgets/duration_input.dart';
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
    duration: const Duration(milliseconds: 300),
  );
  late final Animation<double> _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 1),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  late Spray _tempSpray;

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

  @override
  Widget build(BuildContext context) {
    if (!widget.show && _controller.status == AnimationStatus.dismissed) {
      return const SizedBox.shrink();
    }

    final bgColor = AppColors.themedColor(context, AppColors.gray200, AppColors.gray800);
    final textColor = AppColors.themedColor(context, AppColors.textLight, AppColors.textDark);
    final borderColor = AppColors.themedColor(context, AppColors.gray200, AppColors.gray700);

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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Setup Spray',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: textColor),
                            onPressed: widget.onClose,
                            splashRadius: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Expanded(
                        child: Scrollbar(
                          thumbVisibility: true,
                          child: ListView.separated(
                            itemCount: _tempSpray.spray.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final active = _tempSpray.active[i];
                              final sprayName = _tempSpray.spray[i];
                              final duration = _tempSpray.duration[i];

                              return Card(
                                elevation: 2,
                                color: AppColors.themedColor(context, AppColors.gray50, AppColors.gray700),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Switch(
                                            value: active,
                                            onChanged: (v) => setState(() => _tempSpray.active[i] = v),
                                            activeColor: AppColors.green500,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: TextField(
                                              controller: TextEditingController(text: sprayName),
                                              onChanged: (v) => _tempSpray.spray[i] = v,
                                              style: const TextStyle(fontSize: 14),
                                              maxLength: 20,
                                              decoration: InputDecoration(
                                                hintText: 'Spray name',
                                                counterText: '',
                                                isDense: true,
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                  borderSide: BorderSide(color: borderColor),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                  borderSide: const BorderSide(color: AppColors.green500),
                                                ),
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.clear, size: 20, color: AppColors.red500),
                                            onPressed: () => setState(() => _tempSpray.spray[i] = ''),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 10),

                                      Row(
                                        children: [
                                          const Text(
                                            'Duration:',
                                            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                                          ),
                                          const SizedBox(width: 8),
                                          DurationInput(
                                            initialValue: duration,
                                            onChanged: (value) => _tempSpray.duration[i] = value,
                                          ),
                                          const SizedBox(width: 6),
                                          const Text(
                                            'sec',
                                            style: TextStyle(fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
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
                            child: const Text(
                              'Cancel',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: () {
                              widget.onClose();
                              widget.sprays.spray = List.from(_tempSpray.spray);
                              widget.sprays.active = List.from(_tempSpray.active);
                              widget.sprays.duration = List.from(_tempSpray.duration);
                              AppSnackBar.success(context, "Spray settings saved!");
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: AppColors.green500,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text(
                              'Save',
                              style: TextStyle(fontSize: 14),
                            ),
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
