import 'package:android/classes/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:android/widgets/viewpicture.dart';
import 'package:android/utils/colors.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';

class FolderDetailPage extends StatefulWidget {
  final String slug;
  final String folderName;
  final List<Map<String, dynamic>> images;

  const FolderDetailPage({
    super.key,
    required this.slug,
    required this.folderName,
    required this.images,
  });

  @override
  State<FolderDetailPage> createState() => _FolderDetailPageState();
}

class _FolderDetailPageState extends State<FolderDetailPage> {
  String filterMode = "ROI";
  int currentPage = 1;
  static const int itemsPerPage = 10;
  late List<Map<String, dynamic>> allImages;

  @override
  void initState() {
    super.initState();
    allImages = List<Map<String, dynamic>>.from(widget.images);
  }

  void _removeImageById(String id) {
    setState(() {
      allImages.removeWhere((img) => img['id'] == id);
    });
  }

  List<Map<String, dynamic>> get filteredImages {
    if (filterMode == "SCANBOX") {
      return allImages.where((img) => img["plantName"] == "SCANBOX").toList();
    }
    if (filterMode == "ROI") {
      return allImages.where((img) => img["plantName"] != "SCANBOX").toList();
    }
    return allImages;
  }

  int get totalPages => (filteredImages.length / itemsPerPage).ceil().clamp(1, 1000);

  List<Map<String, dynamic>> get paginatedImages {
    final start = (currentPage - 1) * itemsPerPage;
    final end = (start + itemsPerPage).clamp(0, filteredImages.length);
    return filteredImages.sublist(start, end);
  }

  void changePage(int delta) {
    setState(() => currentPage = (currentPage + delta).clamp(1, totalPages));
  }

  Future<void> _downloadAllImages() async {
    final imagesToDownload = filteredImages;
    if (imagesToDownload.isEmpty) {
      AppSnackBar.warning(context, "No images to download.");
      return;
    }

    AppSnackBar.loading(context, "Preparing ZIP file...", id: "download");

    try {
      final archive = Archive();

      for (final img in imagesToDownload) {
        try {
          final url = img["src"];
          final id = img["id"].toString();
          final response = await http.get(Uri.parse(url));

          if (response.statusCode == 200) {
            archive.addFile(
              ArchiveFile("$id.jpg", response.bodyBytes.length, response.bodyBytes),
            );
          } else {
            debugPrint("Failed to download $url -> ${response.statusCode}");
          }
        } catch (e, st) {
          debugPrint("Error downloading image: $e\n$st");
        }
      }

      if (archive.isEmpty) {
        if (mounted) {
          AppSnackBar.hide(context, id: "download");
          AppSnackBar.error(context, "Failed to collect image data.");
        }
        return;
      }

      final zipData = ZipEncoder().encode(archive);
      final dir = await getTemporaryDirectory();
      final zipPath = "${dir.path}/${widget.folderName}_${filterMode.toLowerCase()}.zip";
      final zipFile = File(zipPath);
      await zipFile.writeAsBytes(zipData);

      final params = SaveFileDialogParams(
        sourceFilePath: zipFile.path,
        fileName: "${widget.folderName}_${filterMode.toLowerCase()}.zip",
      );

      await FlutterFileDialog.saveFile(params: params);
      if (mounted) {
        AppSnackBar.hide(context, id: "download");
        AppSnackBar.success(context, "ZIP file downloaded successfully.");
      }
    } catch (e, st) {
      debugPrint("ZIP creation error: $e\n$st");
      if (mounted) {
        AppSnackBar.hide(context, id: "download");
        AppSnackBar.error(context, "An error occurred: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = AppColors.themedColor(context, AppColors.gray200, AppColors.gray700);
    final appBarColor = AppColors.themedColor(context, AppColors.white, AppColors.gray900);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.slug,
          style: TextStyle(fontSize: 18),
        ),
        backgroundColor: appBarColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: _downloadAllImages,
            icon: Icon(
              Icons.download,
              color: AppColors.themedColor(
                context,
                AppColors.green700,
                AppColors.green500,
              ),
            ),
            label: const Text("DOWNLOAD ALL"),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.themedColor(context, AppColors.green700, AppColors.green500),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              _buildHeader(context),
              const SizedBox(height: 8),
              Expanded(
                child: paginatedImages.isNotEmpty ? _buildImageGrid() : _buildEmptyPlaceholder(context),
              ),
              const SizedBox(height: 8),
              _buildPagination(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.themedColor(context, AppColors.green500, AppColors.gray800),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.themedColor(context, AppColors.gray300, AppColors.gray700),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.folder, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                widget.folderName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.themedColor(context, Colors.white, Colors.grey[300]!),
                ),
              ),
            ],
          ),
          Row(
            children: ["ALL", "SCANBOX", "ROI"].map(_filterButton).toList(),
          ),
        ],
      ),
    );
  }

  Widget _filterButton(String mode) {
    final active = filterMode == mode;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () => setState(() {
          filterMode = mode;
          currentPage = 1;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: active ? AppColors.green700 : AppColors.themedColor(context, AppColors.green500, AppColors.gray800),
            border: Border.all(
              color: AppColors.themedColor(context, AppColors.green500, AppColors.gray700),
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            mode,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: paginatedImages.length,
      itemBuilder: (context, i) => _ImageCard(image: paginatedImages[i], onDelete: _removeImageById,
      ),
    );
  }

  Widget _buildEmptyPlaceholder(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.themedColor(context, Colors.grey[200]!, AppColors.gray800),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text("No images found."),
      ),
    );
  }

  Widget _buildPagination(BuildContext context) {
    final textColor = AppColors.themedColor(context, AppColors.textLight, AppColors.textDark);
    final buttonBg = AppColors.themedColor(context, AppColors.green500, AppColors.green700);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: buttonBg, foregroundColor: textColor),
          onPressed: currentPage > 1 ? () => changePage(-1) : null,
          child: const Text("Prev"),
        ),
        const SizedBox(width: 12),
        Text("Page $currentPage of $totalPages", style: TextStyle(color: textColor)),
        const SizedBox(width: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: buttonBg, foregroundColor: textColor),
          onPressed: currentPage < totalPages ? () => changePage(1) : null,
          child: const Text("Next"),
        ),
      ],
    );
  }
}

class _ImageCard extends StatelessWidget {
  final Map<String, dynamic> image;
  final void Function(String id) onDelete;
  const _ImageCard({required this.image, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        barrierColor: Colors.black54,
        builder: (_) => ViewPictureModal(
          selectedImage: image,
          downloadImage: (src) async {
            try {
              AppSnackBar.loading(context, "Downloading image...", id: "imgDownload");

              final response = await http.get(Uri.parse(src));
              if (response.statusCode == 200) {
                final dir = await getTemporaryDirectory();
                final filePath = "${dir.path}/image_${DateTime.now().millisecondsSinceEpoch}.jpg";
                final file = File(filePath);
                await file.writeAsBytes(response.bodyBytes);

                final params = SaveFileDialogParams(
                  sourceFilePath: file.path,
                  fileName: "downloaded_image.jpg",
                );
                await FlutterFileDialog.saveFile(params: params);

                if (context.mounted) {
                  AppSnackBar.hide(context, id: "imgDownload");
                  AppSnackBar.success(context, "Image downloaded successfully.");
                }
              } else {
                if (context.mounted) {
                  AppSnackBar.hide(context, id: "imgDownload");
                  AppSnackBar.error(context, "Failed to download image.");
                }
              } 
            } catch (e) {
              if (context.mounted) {
                AppSnackBar.hide(context, id: "imgDownload");
                AppSnackBar.error(context, "Download error: $e");
              }
            }
          },
          onClose: () => Navigator.pop(context),
          closeUpdate: (id) {
            Navigator.pop(context);
            onDelete(id);
          }
        ),
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.themedColor(context, Colors.grey[300]!, AppColors.gray800),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.network(
                  image["src"],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
          ),
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                "${image["id"]}",
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
