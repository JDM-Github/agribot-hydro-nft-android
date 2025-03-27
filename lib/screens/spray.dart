import 'package:android/modals/camera.dart';
import 'package:android/screens/plantdetail.dart';
import 'package:android/screens/section/folderscreen.dart';
import 'package:android/screens/section/livefeedscreen.dart';
import 'package:android/screens/section/plantlistsection.dart';
import 'package:android/screens/section/profilesection.dart';
import 'package:android/utils/colors.dart';
import 'package:flutter/material.dart';

class ScannedPlantsScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  const ScannedPlantsScreen({super.key, required this.toggleTheme});

  @override
  State<ScannedPlantsScreen> createState() => _ScannedPlantsScreenState();
}

class _ScannedPlantsScreenState extends State<ScannedPlantsScreen> {
  final List<Map<String, dynamic>> detectedPlants = [
    {
      'id': 1,
      'imageUrl': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSJKRPXQYgZjJmuQTgXVQNLoZRxRWe7aW09wg&s',
      'description': 'Healthy tomato',
      'name': 'Tomato',
      'spray': 'Insecticide A',
      'row': 3,
      'column': 5,
      'timestamp': '2025-03-03 10:15:32',
      'confidence': 98
    },
    {
      'id': 2,
      'imageUrl': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSJKRPXQYgZjJmuQTgXVQNLoZRxRWe7aW09wg&s',
      'description': 'Blooming rose plant.',
      'name': 'Rose',
      'spray': 'Fungicide B',
      'row': 2,
      'column': 4,
      'timestamp': '2025-03-03 10:16:12',
      'confidence': 95
    },
  ];

  String searchQuery = '';
  int selectedIndex = 0;
  int previousIndex = -1;

  void setIndex(int index) {
    setState(() {
      previousIndex = selectedIndex;
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    var filteredPlants = detectedPlants.where((plant) {
      return plant['name'].toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    // List of screens based on selected index
    final List<Widget> screens = [
      PlantListSection(filteredPlants: filteredPlants), // Home
      // PlantListSection(filteredPlants: filteredPlants), // Home
      // PlantListSection(filteredPlants: filteredPlants), // Home
      // PlantListSection(filteredPlants: filteredPlants), // Home
      LiveFeedScreen(), // Live Camera Feed (Placeholder)
      FolderSection(), // Folder Section (Placeholder)
      ProfileSection(), // Profile Section (Placeholder)
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.themedColor(context, AppColors.white, AppColors.gray900),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/icons/LOGO.ico',
            width: 24,
            height: 24,
            fit: BoxFit.contain,
          ),
        ),
        title: Row(
          children: [
            Text(
              "AGRI-BOT STUDIO",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(width: 10),
            Icon(Icons.circle, color: Colors.lightGreenAccent, size: 12),
            SizedBox(width: 5),
            Text(
              "Connected",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.brightness_6),
            onPressed: widget.toggleTheme,
          )
        ],
      ),
      backgroundColor: AppColors.themedColor(context, AppColors.gray200, AppColors.gray700),
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          final slideAnimation = Tween<Offset>(
            begin: Offset(selectedIndex > previousIndex ? 1.0 : -1.0, 0.0), 
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut, 
          ));

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: slideAnimation,
              child: child,
            ),
          );
        },
        child: screens[selectedIndex],
      ),

      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        child: selectedIndex == 0
            ? CameraModal()
            : selectedIndex == 3
                ? FloatingActionButton(
                    key: const ValueKey("logoutButton"), 
                    onPressed: () {
                    },
                    backgroundColor: AppColors.red500,
                    foregroundColor: AppColors.gray50,
                    shape: CircleBorder(),
                    child: const Icon(Icons.logout, size: 24),
                  )
                : const SizedBox(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: AnimatedContainer(
        duration: Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: BottomAppBar(
          color: AppColors.themedColor(context, AppColors.white, AppColors.gray900),
          shape: CircularNotchedRectangle(),
          notchMargin: selectedIndex == 0 || selectedIndex == 3 ? 16.0 : 0.0,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                AnimatedAlign(
                  duration: Duration(milliseconds: 300),
                  alignment: Alignment.center,
                  child: IconButton(
                    icon: Icon(Icons.settings, color: selectedIndex == 0 ? Colors.green : Colors.grey),
                    onPressed: () {
                      setIndex(0);
                    },
                  ),
                ),
                Spacer(),
                AnimatedAlign(
                  duration: Duration(milliseconds: 300),
                  alignment: Alignment.center,
                  child: IconButton(
                    icon: Icon(Icons.live_tv, color: selectedIndex == 1 ? Colors.green : Colors.grey),
                    onPressed: () { setIndex(1); },
                  ),
                ),
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: selectedIndex == 0 || selectedIndex == 3 ? 40 : 0, 
                ),
                Spacer(),
                AnimatedAlign(
                  duration: Duration(milliseconds: 300),
                  alignment: Alignment.center,
                  child: IconButton(
                    icon: Icon(Icons.folder, color: selectedIndex == 2 ? Colors.green : Colors.grey),
                    onPressed: () {
                      setIndex(2);
                    },
                  ),
                ),
                Spacer(),
                AnimatedAlign(
                  duration: Duration(milliseconds: 300),
                  alignment: Alignment.center,
                  child: IconButton(
                    icon: Icon(Icons.person, color: selectedIndex == 3 ? Colors.green : Colors.grey),
                    onPressed: () {
                      setIndex(3);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
