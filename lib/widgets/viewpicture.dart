import 'package:flutter/material.dart';
import 'package:android/utils/colors.dart';

class ViewPictureModal extends StatefulWidget {
  final Map<String, dynamic> selectedImage;
  final Function(String src) downloadImage;
  final VoidCallback onClose;
  final bool noDownloadDelete;

  const ViewPictureModal({
    super.key,
    required this.selectedImage,
    required this.downloadImage,
    required this.onClose,
    this.noDownloadDelete = false,
  });

  @override
  State<ViewPictureModal> createState() => _ViewPictureModalState();
}

class _ViewPictureModalState extends State<ViewPictureModal> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isScanbox = widget.selectedImage["plantName"] == "SCANBOX";
    final maxHeight = MediaQuery.of(context).size.height * 0.9;

    return FadeTransition(
      opacity: _opacity,
      child: Stack(
        children: [
          // Background overlay with gradient
          GestureDetector(
            onTap: widget.onClose,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withAlpha(155), Colors.black.withAlpha(200)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Center(
            child: ScaleTransition(
              scale: _scale,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 350,
                  maxHeight: maxHeight,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.themedColor(context, AppColors.white, AppColors.gray900),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(60),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        children: [
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.themedColor(context, AppColors.gray200, AppColors.gray800),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                              child: Image.network(
                                widget.selectedImage["src"],
                                fit: BoxFit.contain,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                          ),
                          // Positioned(
                          //   bottom: 10,
                          //   left: 10,
                          //   child: Container(
                          //     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          //     decoration: BoxDecoration(
                          //       color: Colors.black54,
                          //       borderRadius: BorderRadius.circular(8),
                          //     ),
                          //     child: Text(
                          //       "${widget.selectedImage["id"]} | Captured at: ${widget.selectedImage["timestamp"]}",
                          //       style: const TextStyle(
                          //         color: Colors.white,
                          //         fontSize: 12,
                          //         fontWeight: FontWeight.w500,
                          //       ),
                          //     ),
                          //   ),
                          // ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              backgroundColor: Colors.black26,
                              child: IconButton(
                                icon: const Icon(Icons.close, size: 22),
                                color: AppColors.themedColor(context, AppColors.gray900, AppColors.white),
                                onPressed: widget.onClose,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Info & actions scrollable
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              isScanbox ? "SCANBOX" : "ROI PLANT",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.themedColor(context, AppColors.green700, AppColors.green500),
                              ),
                            ),
                            const SizedBox(height: 2),
                            if (!isScanbox) ...[
                              _infoRow("Plant", widget.selectedImage["plantName"]),
                              _infoRow("Plant Health", widget.selectedImage["diseaseName"]),
                              _infoRow("Image Size", widget.selectedImage["imageSize"]),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.themedColor(context, AppColors.gray100, AppColors.gray800),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                constraints: const BoxConstraints(
                                  maxHeight: 120,
                                ),
                                child: SingleChildScrollView(
                                  child: Text(
                                    "AI Analysis:\n${widget.selectedImage["generatedDescription"]}Cupidatat Lorem culpa exercitation cillum consectetur. Sint nostrud minim veniam proident do sit nisi dolore. Veniam proident enim ex quis commodo minim Lorem magna incididunt ea exercitation. Occaecat officia veniam adipisicing aliquip culpa ad officia.",
                                    style: TextStyle(
                                      fontSize: 14,
                                      height: 1.4,
                                      color: AppColors.themedColor(context, AppColors.gray800, AppColors.gray300),
                                    ),
                                  ),
                                ),
                              ),
                            ] else
                              _infoRow("Image Size", widget.selectedImage["imageSize"]),
                          ],
                        ),
                      ),
                      if (!widget.noDownloadDelete) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: SizedBox(
                            width: double.infinity,
                            child: _actionButton(
                              icon: Icons.download,
                              label: "Download",
                              color: AppColors.green500,
                              onTap: () => widget.downloadImage(widget.selectedImage["src"]),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: SizedBox(
                            width: double.infinity,
                            child: _actionButton(
                              icon: Icons.delete,
                              label: "Delete",
                              color: AppColors.red500,
                              onTap: () {},
                            ),
                          ),
                        ),
                      ],

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: SizedBox(
                          width: double.infinity,
                          child: _actionButton(
                            icon: Icons.close,
                            label: "Close",
                            color: AppColors.themedColor(context, AppColors.gray400, AppColors.gray700),
                            textColor: AppColors.themedColor(context, AppColors.gray900, AppColors.white),
                            onTap: widget.onClose,
                          ),
                        ),
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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    Color textColor = Colors.white,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: textColor),
      label: Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
      ),
    );
  }
}
