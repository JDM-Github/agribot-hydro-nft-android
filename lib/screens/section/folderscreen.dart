import 'package:android/utils/colors.dart';
import 'package:flutter/material.dart';

class FolderSection extends StatefulWidget {
  const FolderSection({super.key});

  @override
  State<FolderSection> createState() => _FolderSectionState();
}

class _FolderSectionState extends State<FolderSection> {
  List<Map<String, String>> files = [
    {
      "name": "Tomato Leaf",
      "imageUrl": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSJKRPXQYgZjJmuQTgXVQNLoZRxRWe7aW09wg&s"
    },
    {
      "name": "Cucumber Spot",
      "imageUrl": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSJKRPXQYgZjJmuQTgXVQNLoZRxRWe7aW09wg&s"
    },
    {
      "name": "Strawberry Blight",
      "imageUrl": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSJKRPXQYgZjJmuQTgXVQNLoZRxRWe7aW09wg&s"
    },
    {
      "name": "Lettuce Disease",
      "imageUrl": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSJKRPXQYgZjJmuQTgXVQNLoZRxRWe7aW09wg&s"
    },
    {
      "name": "Grape Infection",
      "imageUrl": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSJKRPXQYgZjJmuQTgXVQNLoZRxRWe7aW09wg&s"
    },
    {
      "name": "Apple Rust",
      "imageUrl": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSJKRPXQYgZjJmuQTgXVQNLoZRxRWe7aW09wg&s"
    },
    {
      "name": "Corn Leaf Blight",
      "imageUrl": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSJKRPXQYgZjJmuQTgXVQNLoZRxRWe7aW09wg&s"
    },
  ];

  List<Map<String, String>> filteredFiles = [];
  String searchQuery = "";
  String selectedSort = "Name";
  int gridCount = 4;

  @override
  void initState() {
    super.initState();
    filteredFiles = List.from(files);
  }

  void filterFiles(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      filteredFiles = files.where((file) {
        return file["name"]!.toLowerCase().contains(searchQuery);
      }).toList();
    });
  }

  void sortFiles(String criteria) {
    setState(() {
      selectedSort = criteria;
      if (criteria == "Name") {
        filteredFiles.sort((a, b) => a["name"]!.compareTo(b["name"]!));
      }
    });
  }

  void updateGridSize(int count) {
    setState(() {
      gridCount = count;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.themedColor(context, AppColors.gray200, AppColors.gray800), // 🔥 Fixed Background
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                // 🔍 Search Bar
                Expanded(
                  child: TextField(
                    style: TextStyle(
                      color:
                          AppColors.themedColor(context, AppColors.gray900, AppColors.gray50), // 🔥 Adaptive Text Color
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: "Search...",
                      hintStyle: TextStyle(
                        color: AppColors.themedColor(
                            context, AppColors.gray600, AppColors.gray400), // 🔥 Adaptive Hint Color
                        fontSize: 12,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppColors.themedColor(
                            context, AppColors.gray700, AppColors.gray400), // 🔥 Adaptive Icon Color
                        size: 18,
                      ),
                      filled: true,
                      fillColor:
                          AppColors.themedColor(context, AppColors.gray50, AppColors.gray800), // 🔥 Adaptive Fill Color
                      contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppColors.themedColor(
                              context, AppColors.gray500, AppColors.gray700), // 🔥 Adaptive Border
                          width: 1,
                        ),
                      ),
                    ),
                    onChanged: filterFiles,
                  ),
                ),
                SizedBox(width: 10),

                // 🔄 Sort Button
                PopupMenuButton<String>(
                  color: AppColors.themedColor(context, AppColors.gray50, AppColors.gray900), // 🔥 Adaptive Menu Color
                  onSelected: sortFiles,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: "Name",
                      child: Text("Sort by Name",
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.themedColor(context, AppColors.gray900, AppColors.gray50))),
                    ),
                    PopupMenuItem(
                      value: "Date",
                      child: Text("Sort by Date",
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.themedColor(context, AppColors.gray900, AppColors.gray50))),
                    ),
                  ],
                  icon: Icon(Icons.sort,
                      color: AppColors.themedColor(context, AppColors.gray900, AppColors.gray50),
                      size: 18), // 🔥 Adaptive Icon
                ),
                SizedBox(width: 10),

                DropdownButton<int>(
                  value: gridCount,
                  dropdownColor: AppColors.themedColor(
                      context, AppColors.gray50, AppColors.gray900), // 🔥 Adaptive Dropdown Background
                  icon: Icon(Icons.grid_view,
                      color: AppColors.themedColor(context, AppColors.gray900, AppColors.gray50),
                      size: 18), // 🔥 Adaptive Icon
                  items: [3, 4, 5].map((count) {
                    return DropdownMenuItem(
                      value: count,
                      child: Text(
                        "$count Columns",
                        style: TextStyle(
                          color:
                              AppColors.themedColor(context, AppColors.gray900, AppColors.gray50), // 🔥 Adaptive Text
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      updateGridSize(value);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: gridCount,
                crossAxisSpacing: 5,
                mainAxisSpacing: 5,
                childAspectRatio: 0.9,
              ),
              itemCount: filteredFiles.length,
              itemBuilder: (context, index) {
                var file = filteredFiles[index];
                return GestureDetector(
                    onTap: () {},
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: AppColors.gray800.withAlpha(100),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.folder,
                                size: 50,
                                color: AppColors.gray500, 
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          file["name"]!,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ));
              },
            ),
          ),
        ),
      ],
    );
  }
}
