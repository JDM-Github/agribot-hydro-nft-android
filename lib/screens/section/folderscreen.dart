import 'package:android/widgets/animated_folder_grid_view.dart';
import 'package:flutter/material.dart';
import 'package:android/utils/colors.dart';
import 'package:android/utils/struct.dart';
import 'package:intl/intl.dart';

class FolderSection extends StatefulWidget {
  final String email;
  final List<FolderRecord> records;

  const FolderSection({super.key, required this.records, required this.email});

  @override
  State<FolderSection> createState() => FolderSectionState();
}

class FolderSectionState extends State<FolderSection> {
  late List<FolderRecord> filteredRecords;
  String searchQuery = "";
  String sortOrder = "desc";
  int currentPage = 1;
  int itemsPerPage = 12;

  @override
  void initState() {
    super.initState();
    filteredRecords = List.from(widget.records);
    sortRecords();
  }

  void _filterRecords(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      filteredRecords = widget.records.where((record) {
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
