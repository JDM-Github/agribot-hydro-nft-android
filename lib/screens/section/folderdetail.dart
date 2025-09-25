import 'package:android/widgets/viewpicture.dart';
import 'package:flutter/material.dart';
import 'package:android/utils/colors.dart';

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
  int itemsPerPage = 10;

  List<Map<String, dynamic>> get filteredImages {
    List<Map<String, dynamic>> filtered = widget.images;
    if (filterMode == "SCANBOX") {
      filtered = filtered.where((img) => img["plantName"] == "SCANBOX").toList();
    } else if (filterMode == "ROI") {
      filtered = filtered.where((img) => img["plantName"] != "SCANBOX").toList();
    }
    return filtered;
  }

  List<Map<String, dynamic>> get paginatedImages {
    int start = (currentPage - 1) * itemsPerPage;
    int end = start + itemsPerPage;
    return filteredImages.sublist(
      start,
      end > filteredImages.length ? filteredImages.length : end,
    );
  }

  int get totalPages => (filteredImages.length / itemsPerPage).ceil().clamp(1, 1000);

  void nextPage() {
    if (currentPage < totalPages) setState(() => currentPage++);
  }

  void prevPage() {
    if (currentPage > 1) setState(() => currentPage--);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.slug),
        backgroundColor: AppColors.themedColor(context, AppColors.white, AppColors.gray900),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
            },
            label: const Text("DOWNLOAD ALL"),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.themedColor(context, AppColors.green700, AppColors.green500),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.themedColor(context, AppColors.gray200, AppColors.gray700),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(4),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.themedColor(context, AppColors.green500, AppColors.gray800),
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: AppColors.themedColor(context, AppColors.gray300, AppColors.gray700)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.description, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(widget.folderName,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.themedColor(context, Colors.white, Colors.grey[300]!))),
                                ],
                              ),
                              Row(
                                children: [
                                  _filterButton("ALL"),
                                  const SizedBox(width: 4),
                                  _filterButton("SCANBOX"),
                                  const SizedBox(width: 4),
                                  _filterButton("ROI"),
                                ],
                              )
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),
                        paginatedImages.isNotEmpty
                            ? GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: paginatedImages.length,
                                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 160,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                  childAspectRatio: 1.2,
                                ),
                                itemBuilder: (context, index) {
                                  final image = paginatedImages[index];
                                  return GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        barrierColor: Colors.black54,
                                        builder: (_) => ViewPictureModal(
                                          selectedImage: image,
                                          downloadImage: (src) {
                                          },
                                          onClose: () => Navigator.pop(context),
                                        ),
                                      );
                                    },
                                    child: Stack(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                                color: AppColors.themedColor(
                                                    context, Colors.grey[300]!, Colors.grey[700]!)),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.network(image["src"], fit: BoxFit.cover),
                                          ),
                                        ),
                                        Positioned(
                                          top: 4,
                                          left: 4,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                            decoration: BoxDecoration(
                                                color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                                            child: Text("${image["id"]}",
                                                style: const TextStyle(color: Colors.white, fontSize: 10)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              )
                            : Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.themedColor(context, Colors.grey[200]!, Colors.grey[800]!),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Text("No images found."),
                                ),
                              ),

                        const SizedBox(height: 4),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: currentPage > 1 ? prevPage : null,
                              child: const Text("Prev"),
                            ),
                            const SizedBox(width: 12),
                            Text("Page $currentPage of $totalPages"),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: currentPage < totalPages ? nextPage : null,
                              child: const Text("Next"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _filterButton(String mode) {
    bool active = filterMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          filterMode = mode;
          currentPage = 1;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.green700 : AppColors.themedColor(context, AppColors.green500, AppColors.gray800),
          border: Border.all(color: AppColors.themedColor(context, AppColors.green500, AppColors.gray700)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          mode,
          style: TextStyle(color: active ? Colors.white : Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }
}
