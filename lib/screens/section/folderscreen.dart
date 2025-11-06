import 'package:android/classes/default.dart';
import 'package:android/classes/snackbar.dart';
import 'package:android/requests/update.dart';
import 'package:android/store/data.dart';
import 'package:android/widgets/animated_folder_grid_view.dart';
import 'package:flutter/material.dart';
import 'package:android/utils/colors.dart';
import 'package:android/utils/struct.dart';
import 'package:intl/intl.dart';

class FolderSection extends StatefulWidget {
  final String email;

  const FolderSection({super.key, required this.email});

  @override
  State<FolderSection> createState() => FolderSectionState();
}

class FolderSectionState extends State<FolderSection> {
  late List<FolderRecord> filteredRecords;
  String searchQuery = "";
  String sortOrder = "desc";
  int currentPage = 1;
  int itemsPerPage = 12;
  UserDataStore data = UserDataStore();

  Future<void> forceSync() async {
    AppSnackBar.loading(context, "Force syncing records folder...", id: "force-sync");
    final result = await CustomUpdater.checkCustomUpdate(
      state: this,
      deviceID: data.uuid.value,
      willUpdateFolders: true,
    );
    DefaultConfig newConfig = result['data'];
    final now = DateTime.now();
    final currentDaySlug = '${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.year}';
    data.folderLastFetch.value = currentDaySlug;
    data.folders.value = newConfig.folders;
    await data.saveData();
    if (mounted) {
      AppSnackBar.hide(context, id: "force-sync");
      AppSnackBar.success(context, "Force sync of records folder is successful!");
    }
    updateFolders();
  }

  void updateFolders() {
    _filterRecords(searchQuery);
  }

  @override
  void initState() {
    super.initState();
    filteredRecords = List.from(data.folders.value);
    sortRecords();
  }

  void _filterRecords(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      filteredRecords = data.folders.value.where((record) {
        return record.name.toLowerCase().contains(searchQuery) || record.date.toLowerCase().contains(searchQuery);
      }).toList();
      currentPage = 1;
      sortRecords();
    });
  }

  void sortRecords([String? order]) {
    setState(() {
      if (order != null) sortOrder = order;

      final dateFormat = DateFormat('MMMM d, yyyy');

      filteredRecords.sort((a, b) {
        DateTime dateA = dateFormat.parse(a.date);
        DateTime dateB = dateFormat.parse(b.date);
        return sortOrder == "asc" ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
      });
    });
  }

  List<FolderRecord> _paginatedRecords() {
    int start = (currentPage - 1) * itemsPerPage;
    int end = (start + itemsPerPage).clamp(0, filteredRecords.length);
    return filteredRecords.sublist(start, end);
  }

  int get totalPages => (filteredRecords.length / itemsPerPage).ceil().clamp(1, 1000);

  void _goToPage(int page) {
    setState(() {
      currentPage = page.clamp(1, totalPages);
    });
  }

  @override
  Widget build(BuildContext context) {
    List<FolderRecord> pageRecords = _paginatedRecords();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          color: AppColors.themedColor(context, AppColors.gray100, AppColors.gray800),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search Folders...",
                    hintStyle: const TextStyle(fontSize: 13),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: AppColors.gray600)
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.green500),
                    ),
                  ),
                  style: const TextStyle(fontSize: 13),
                  onChanged: _filterRecords,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: AnimatedGridView(records: pageRecords, email: widget.email)
        ),
        if (filteredRecords.length > itemsPerPage)
          Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.themedColor(
                      context,
                      AppColors.gray200,
                      AppColors.gray800,
                    ),
                    foregroundColor: AppColors.themedColor(
                      context,
                      AppColors.gray900,
                      AppColors.gray100,
                    ),
                    disabledBackgroundColor: AppColors.themedColor(
                      context,
                      AppColors.gray100,
                      AppColors.gray900.withAlpha(80),
                    ),
                    disabledForegroundColor: AppColors.themedColor(
                      context,
                      AppColors.gray400,
                      AppColors.gray500,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onPressed: currentPage > 1 ? () => _goToPage(currentPage - 1) : null,
                  child: const Text("← Prev"),
                ),
                const SizedBox(width: 12),
                Text(
                  "Page $currentPage of $totalPages",
                  style: TextStyle(
                    color: AppColors.themedColor(
                      context,
                      AppColors.gray700,
                      AppColors.gray300,
                    ),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.themedColor(
                      context,
                      AppColors.gray200,
                      AppColors.gray800,
                    ),
                    foregroundColor: AppColors.themedColor(
                      context,
                      AppColors.gray900,
                      AppColors.gray100,
                    ),
                    disabledBackgroundColor: AppColors.themedColor(
                      context,
                      AppColors.gray100,
                      AppColors.gray900.withAlpha(80),
                    ),
                    disabledForegroundColor: AppColors.themedColor(
                      context,
                      AppColors.gray400,
                      AppColors.gray500,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onPressed: currentPage < totalPages ? () => _goToPage(currentPage + 1) : null,
                  child: const Text("Next →"),
                ),
              ],
            ),
          )

      ],
    );
  }
}
