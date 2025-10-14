import 'package:flutter/material.dart';
import '../utils/colors.dart';

class NotificationDetailModal extends StatefulWidget {
  final bool show;
  final VoidCallback onClose;
  final Map<String, dynamic> notification;

  const NotificationDetailModal({
    super.key,
    required this.show,
    required this.onClose,
    required this.notification,
  });

  @override
  State<NotificationDetailModal> createState() => _NotificationDetailModalState();
}

class _NotificationDetailModalState extends State<NotificationDetailModal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  late final Animation<double> _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 1),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    if (widget.show) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant NotificationDetailModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.show ? _controller.forward(from: 0) : _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _getTypeIcon(String type, bool isRead, BuildContext context) {
    Color color;
    switch (type) {
      case "error":
        color = AppColors.themedColor(context, AppColors.red500, AppColors.red700);
        break;
      case "warning":
        color = AppColors.themedColor(context, AppColors.orange500, AppColors.orange700);
        break;
      default:
        color = AppColors.themedColor(context, AppColors.blue500, AppColors.blue700);
    }
    if (isRead) color = AppColors.themedColor(context, AppColors.gray500, AppColors.gray700);
    IconData icon = (type == "error")
        ? Icons.error
        : (type == "warning")
            ? Icons.warning
            : Icons.info;
    return Icon(icon, color: color);
  }

  String _formatTime(String isoTime) {
    try {
      final dt = DateTime.parse(isoTime);
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show && _controller.status == AnimationStatus.dismissed) return const SizedBox.shrink();

    final bgColor = AppColors.themedColor(context, AppColors.white, AppColors.gray800);
    final textColor = AppColors.themedColor(context, AppColors.textLight, AppColors.textDark);
    final footerTextColor = AppColors.themedColor(context, AppColors.gray600, AppColors.gray400);

    return FadeTransition(
      opacity: _opacity,
      child: Stack(
        children: [
          // Background overlay
          GestureDetector(
            onTap: widget.onClose,
            child: Container(
              color: Colors.black.withAlpha(150),
              width: double.infinity,
              height: double.infinity,
            ),
          ),

          // Sliding modal
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
                    children: [
                      // Header
                      Row(
                        children: [
                          _getTypeIcon(
                              widget.notification["type"] ?? "info", widget.notification["isRead"] == true, context),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.notification["title"] ?? "",
                              style: TextStyle(
                                fontWeight: widget.notification["isRead"] == true ? FontWeight.normal : FontWeight.bold,
                                fontSize: 16,
                                color: textColor,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: textColor),
                            onPressed: widget.onClose,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Message
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            widget.notification["message"] ?? "",
                            style: TextStyle(color: textColor),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),
                      // Footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatTime(widget.notification["createdAt"] ?? ""),
                            style: TextStyle(fontSize: 12, color: footerTextColor),
                          ),
                          TextButton(
                            onPressed: widget.onClose,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.themedColor(context, AppColors.blue500, AppColors.blue700),
                            ),
                            child: const Text("Close"),
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
