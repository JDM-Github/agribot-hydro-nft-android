import 'package:android/utils/colors.dart';
import 'package:flutter/material.dart';

class RequestAuthKeyModal extends StatefulWidget {
  final bool show;
  final VoidCallback onClose;
  final Function(String deviceName) onRequest;

  const RequestAuthKeyModal({
    super.key,
    required this.show,
    required this.onClose,
    required this.onRequest,
  });

  @override
  State<RequestAuthKeyModal> createState() => _RequestAuthKeyModalState();
}

class _RequestAuthKeyModalState extends State<RequestAuthKeyModal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
  late final Animation<double> _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  late final Animation<Offset> _slide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  final TextEditingController _deviceNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.show) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant RequestAuthKeyModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.show ? _controller.forward(from: 0) : _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    _deviceNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show && _controller.status == AnimationStatus.dismissed) return const SizedBox.shrink();

    final bgColor = AppColors.themedColor(context, AppColors.white, AppColors.gray800);
    final borderColor = AppColors.themedColor(context, AppColors.gray300, AppColors.gray700);
    final textColor = AppColors.themedColor(context, AppColors.textLight, AppColors.textDark);

    return FadeTransition(
      opacity: _opacity,
      child: Stack(
        children: [
          GestureDetector(
            onTap: widget.onClose,
            child: Container(color: Colors.black.withAlpha(150), width: double.infinity, height: double.infinity),
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
                  height: MediaQuery.of(context).size.height * 0.5,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Request Tailscale Auth Key',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _deviceNameController,
                        decoration: InputDecoration(
                          labelText: 'Enter your Device Name',
                          labelStyle: TextStyle(color: AppColors.gray400),
                          hintText: 'Enter device name',
                          filled: true,
                          fillColor: AppColors.themedColor(context, AppColors.gray100, AppColors.gray800),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: AppColors.green500),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const Spacer(),
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
                              final deviceName = _deviceNameController.text.trim();
                              if (deviceName.isNotEmpty) {
                                widget.onRequest(deviceName);
                                widget.onClose();
                                _deviceNameController.clear();
                              }
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: AppColors.green500,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Request'),
                          ),
                        ],
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
