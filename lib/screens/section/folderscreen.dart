import 'package:android/classes/snackbar.dart';
import 'package:android/handle_request.dart';
import 'package:android/screens/section/folderdetail.dart';
import 'package:android/store/data.dart';
import 'package:android/utils/colors.dart';
import 'package:android/utils/struct.dart';
import 'package:flutter/material.dart';

class FolderSection extends StatefulWidget {
  final String email;
  final List<FolderRecord> records;
  const FolderSection({super.key, required this.records, required this.email});

  @override
  State<FolderSection> createState() => _FolderSectionState();
}

class _FolderSectionState extends State<FolderSection> {
  late List<FolderRecord> filteredRecords;
  String searchQuery = "";
  String sortOrder = "desc";
  int currentPage = 1;
  int itemsPerPage = 12;
  FolderRecord? selectedFolder;

  @override
  void initState() {
    super.initState();
    filteredRecords = List.from(widget.records);
    _sortRecords();
  }

  void _filterRecords(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      filteredRecords = widget.records.where((record) {
        return record.date.toLowerCase().contains(searchQuery);
      }).toList();
      currentPage = 1;
      _sortRecords();
    });
  }

  void _sortRecords([String? order]) {
    if (order != null) sortOrder = order;
    filteredRecords.sort((a, b) {
      DateTime dateA = DateTime.parse(a.date);
      DateTime dateB = DateTime.parse(b.date);
      return sortOrder == "asc" ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
    });
  }

  List<FolderRecord> _paginatedRecords() {
    int start = (currentPage - 1) * itemsPerPage;
    int end = start + itemsPerPage;
    return filteredRecords.sublist(
      start,
      end > filteredRecords.length ? filteredRecords.length : end,
    );
  }

  int get totalPages => (filteredRecords.length / itemsPerPage).ceil().clamp(1, 1000);

  void _goToPage(int page) {
    setState(() {
      currentPage = page.clamp(1, totalPages);
    });
  }

  void _deleteFolder(String slug) {
    setState(() {
      filteredRecords.removeWhere((r) => r.slug == slug);
      widget.records.removeWhere((r) => r.slug == slug);
      selectedFolder = null;
      if (currentPage > totalPages) currentPage = totalPages;
    });
  }

  void _openFolder(String slug) async {
    final folder = widget.records.firstWhere((f) => f.slug == slug);
    UserDataStore store = UserDataStore();

    final now = DateTime.now();
    final currentDaySlug = '${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.year}';

    List<Map<String, dynamic>>? images;
    if (slug != currentDaySlug && store.folderImages.value.containsKey(slug)) {
      images = store.folderImages.value[slug];
    }

    final handler = RequestHandler();
    if (images == null) {
      AppSnackBar.loading(context, "Loading folder images...", id: "folder");
      try {
        final email = widget.email;
        if (email.isEmpty) {
          AppSnackBar.hide(context, id: "folder");
          AppSnackBar.error(context, "User email is missing");
          return;
        }

        final response = await handler.handleRequest(
          "folder-images/$slug",
          method: "POST",
          body: {'email': email},
        );

        if (mounted) AppSnackBar.hide(context, id: "folder");

        if (response['success'] == true) {
          final imagesJson = response['images'] as List<dynamic>;
          images = imagesJson.map((img) => img as Map<String, dynamic>).toList();
          final cached = store.folderImages.value;
          if (cached.containsKey(slug)) {
            cached[slug] = images;
            store.folderImages.value = {...cached};
          } else {
            store.folderImages.value = {...cached, slug: images};
          }
          await store.saveData();
        } else {
          if (mounted) {
            AppSnackBar.error(context, response['message'] ?? "Failed to load folder images");
          }
          return;
        }
      } catch (e) {
        if (mounted) {
          AppSnackBar.hide(context, id: "folder");
          AppSnackBar.error(context, "An error occurred: $e");
        }
        return;
      }
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FolderDetailPage(
            slug: slug,
            folderName: folder.name,
            images: images!,
          ),
        ),
      );
    }
  }


  void _showContextMenu(BuildContext context, Offset position, FolderRecord folder) {
    selectedFolder = folder;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(position, position),
        Offset.zero & overlay!.size,
      ),
      items: [
        PopupMenuItem(
          child: Row(
            children: const [
              Icon(Icons.folder_open, size: 18),
              SizedBox(width: 8),
              Text("Open"),
            ],
          ),
          onTap: () => _openFolder(folder.slug),
        ),
        PopupMenuItem(
          child: Row(
            children: const [
              Icon(Icons.delete, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text("Delete", style: TextStyle(color: Colors.red)),
            ],
          ),
          onTap: () => _deleteFolder(folder.slug),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    List<FolderRecord> pageRecords = _paginatedRecords();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          color: AppColors.themedColor(context, AppColors.gray200, AppColors.gray800),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search Records...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: _filterRecords,
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: sortOrder,
                items: const [
                  DropdownMenuItem(value: "desc", child: Text("Newest First")),
                  DropdownMenuItem(value: "asc", child: Text("Oldest First")),
                ],
                onChanged: (value) => setState(() => _sortRecords(value)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 150,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.9,
            ),
            itemCount: pageRecords.length,
            itemBuilder: (context, index) {
              var record = pageRecords[index];
              return GestureDetector(
                onTap: () => _openFolder(record.slug),
                onSecondaryTapDown: (details) => _showContextMenu(context, details.globalPosition, record),
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.themedColor(
                            context,
                            AppColors.gray100,
                            AppColors.gray800.withAlpha(100),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.folder,
                            size: 50,
                            color: AppColors.themedColor(
                              context,
                              AppColors.gray700,
                              AppColors.gray300,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.date,
                      style: TextStyle(
                        color: AppColors.themedColor(
                          context,
                          AppColors.textLight,
                          AppColors.textDark,
                        ),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (filteredRecords.length > itemsPerPage)
          Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: currentPage > 1 ? () => _goToPage(currentPage - 1) : null,
                  child: const Text("← Prev"),
                ),
                const SizedBox(width: 12),
                Text("Page $currentPage of $totalPages"),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: currentPage < totalPages ? () => _goToPage(currentPage + 1) : null,
                  child: const Text("Next →"),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
