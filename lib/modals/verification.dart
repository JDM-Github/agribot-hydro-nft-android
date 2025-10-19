import 'package:android/classes/snackbar.dart';
import 'package:android/utils/colors.dart';
import 'package:flutter/material.dart';

class VerificationCodeModal extends StatefulWidget {
  final bool show;
  final String email;
  final Function(String) onVerify;
  final VoidCallback onClose;

  const VerificationCodeModal({
    super.key,
    required this.show,
    required this.email,
    required this.onVerify,
    required this.onClose,
  });

  @override
  State<VerificationCodeModal> createState() => _VerificationCodeModalState();
}

class _VerificationCodeModalState extends State<VerificationCodeModal> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _scale;
  final TextEditingController _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);

    if (widget.show) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant VerificationCodeModal oldWidget) {
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
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show && _controller.status == AnimationStatus.dismissed) {
      return const SizedBox.shrink();
    }

    final bgColor = AppColors.themedColor(context, AppColors.gray200, AppColors.gray900);
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
                        Text("Verify Email",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
                        IconButton(icon: Icon(Icons.close, color: textColor), onPressed: widget.onClose),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Text(
                      "Enter the 6-digit code sent to ${widget.email}",
                      style: TextStyle(fontSize: 13, color: textColor),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Code Input
                    TextField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        letterSpacing: 8,
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        counterText: "",
                        hintText: "••••••",
                        hintStyle: TextStyle(
                            letterSpacing: 8,
                            color: AppColors.themedColor(context, AppColors.gray400, AppColors.gray600)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (_codeController.text.length == 6) {
                                widget.onVerify(_codeController.text);
                                widget.onClose();
                              } else {
                                AppSnackBar.error(context, 'Please enter a 6-digit code.');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.green500,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            child: const Text('Verify', style: TextStyle(color: Colors.white)),
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
