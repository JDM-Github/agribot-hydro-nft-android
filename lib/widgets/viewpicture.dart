import 'package:android/handle_request.dart';
import 'package:android/store/data.dart';
import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../classes/snackbar.dart';

class ViewPictureModal extends StatefulWidget {
  final Map<String, dynamic> selectedImage;
  final Function(String src) downloadImage;
  final VoidCallback onClose;
  final Function(String id) closeUpdate;
  final bool noDownloadDelete;

  const ViewPictureModal({
    super.key,
    required this.selectedImage,
    required this.downloadImage,
    required this.onClose,
    required this.closeUpdate,
    this.noDownloadDelete = false,
  });

  @override
  State<ViewPictureModal> createState() => _ViewPictureModalState();
}

class _ViewPictureModalState extends State<ViewPictureModal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  late final Animation<double> _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 1),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> deleteImage(String id) async {
    final handler = RequestHandler();
    AppSnackBar.loading(context, "Deleting image...", id: "delete-image");
    try {
      final response = await handler.handleRequest('cloudinary/delete-image', method: "POST", body: {"public_id": id});
      if (mounted) {
        AppSnackBar.hide(context, id: "delete-image");
      }
      if (response['success'] == true) {
        if (mounted) {
          AppSnackBar.hide(context, id: "delete-image");
          AppSnackBar.success(context, "Image deleted successfully.");
        }
        final store = UserDataStore();
        final cached = store.folderImages.value;
        final updated = <String, List<Map<String, dynamic>>>{};
        cached.forEach((slug, imgs) {
          updated[slug] = imgs.where((img) => img['id'] != id).toList();
        });

        store.folderImages.value = updated;
        await store.saveData();
        widget.closeUpdate(id);
      } else {
        if (mounted) {
          AppSnackBar.error(context, response['message'] ?? "Failed to delete image");
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.hide(context, id: "delete-image");
        AppSnackBar.error(context, "Error deleting image: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = widget.selectedImage;
    final isScanbox = image["plantName"] == "SCANBOX";
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
                elevation: 20,
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.85,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isScanbox ? "Scanbox Image" : "ROI Image",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          IconButton(
                            onPressed: widget.onClose,
                            icon: Icon(Icons.close, color: textColor),
                            splashRadius: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.themedColor(context, AppColors.gray200, AppColors.gray900),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.themedColor(context, AppColors.gray300, AppColors.gray700),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => Scaffold(
                                    backgroundColor: Colors.black,
                                    body: Stack(
                                      children: [
                                        Center(
                                          child: InteractiveViewer(
                                            panEnabled: true,
                                            minScale: 0.8,
                                            maxScale: 5.0,
                                            child: Image.network(
                                              image["src"],
                                              fit: BoxFit.contain,
                                              errorBuilder: (_, __, ___) => const Icon(
                                                Icons.broken_image,
                                                color: Colors.white54,
                                                size: 80,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 40,
                                          left: 10,
                                          child: IconButton(
                                            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                                            onPressed: () => Navigator.pop(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: Image.network(
                              image["src"],
                              fit: BoxFit.contain,
                              width: double.infinity,
                              height: 220,
                              errorBuilder: (_, __, ___) => Container(
                                height: 220,
                                color: AppColors.gray300,
                                alignment: Alignment.center,
                                child: const Icon(Icons.broken_image, size: 40),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _infoRow("Plant", image["plantName"]),
                              _infoRow("Plant Health", image["diseaseName"]),
                              _infoRow("Image Size", image["imageSize"]),
                              const SizedBox(height: 10),
                              if (!isScanbox)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.themedColor(context, AppColors.gray100, AppColors.gray700),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    image["generatedDescription"] ?? "No AI analysis available for this image.",
                                    style: TextStyle(
                                      color: AppColors.themedColor(context, AppColors.gray800, AppColors.gray300),
                                      height: 1.4,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (!widget.noDownloadDelete) ...[
                              TextButton(
                                onPressed: () => widget.downloadImage(image["src"]),
                                style: TextButton.styleFrom(
                                  backgroundColor: AppColors.green500,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text(
                                  'Download',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(width: 12),
                              TextButton(
                                onPressed: () async {
                                  await deleteImage(image["id"]);
                                },
                                style: TextButton.styleFrom(
                                  backgroundColor: AppColors.red500,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            TextButton(
                              onPressed: widget.onClose,
                              style: TextButton.styleFrom(
                                backgroundColor: AppColors.gray500,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text(
                                'Close',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
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

  Widget _infoRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
