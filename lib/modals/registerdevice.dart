import 'package:android/utils/colors.dart';
import 'package:flutter/material.dart';

class RegisterDeviceModal extends StatefulWidget {
  final bool show;
  final VoidCallback onClose;
  final Function(String hostName, String ip) onConfirm;
  final String deviceName;

  const RegisterDeviceModal({
    super.key,
    required this.show,
    required this.onClose,
    required this.onConfirm,
    required this.deviceName,
  });

  @override
  State<RegisterDeviceModal> createState() => _RegisterDeviceModalState();
}

class _RegisterDeviceModalState extends State<RegisterDeviceModal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
  late final Animation<double> _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  late final Animation<Offset> _slide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _ipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.show) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant RegisterDeviceModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.show ? _controller.forward(from: 0) : _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    _hostController.dispose();
    _ipController.dispose();
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
                  height: MediaQuery.of(context).size.height * 0.5,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Register New Device',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                      const SizedBox(height: 12),
                      Text(
                        'Enter the host name and IPv4 assigned to ${widget.deviceName} in your Tailscale app:',
                        style: TextStyle(color: textColor),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _hostController,
                        decoration: InputDecoration(
                          labelText: "Enter your Host Name",
                          labelStyle: TextStyle(color: AppColors.gray400),
                          hintText: 'e.g. vivo-1906',
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
                      const SizedBox(height: 8),
                      TextField(
                        controller: _ipController,
                        decoration: InputDecoration(
                          labelText: "Enter you IP",
                          labelStyle: TextStyle(color: AppColors.gray400),
                          hintText: 'e.g. 100.101.102.103',
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
                        keyboardType: TextInputType.number,
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
                              final host = _hostController.text.trim();
                              final ip = _ipController.text.trim();
                              if (host.isNotEmpty && ip.isNotEmpty) {
                                widget.onConfirm(ip, host);
                                widget.onClose();
                                _hostController.clear();
                                _ipController.clear();
                              }
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: AppColors.green500,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Confirm'),
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
