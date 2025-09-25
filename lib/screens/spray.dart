import 'package:android/screens/registration.dart';
import 'package:android/screens/section/folderscreen.dart';
import 'package:android/screens/section/livefeedscreen.dart';
import 'package:android/screens/section/notification.dart';
import 'package:android/screens/section/plantlistsection.dart';
import 'package:android/screens/section/profilesection.dart';
import 'package:android/screens/section/wifiscreen.dart';
import 'package:android/store/connection.dart';
import 'package:android/store/data.dart';
import 'package:android/utils/colors.dart';
import 'package:android/utils/struct.dart';
import 'package:flutter/material.dart';

class ScannedPlantsScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final dynamic user;
  final Function(dynamic newUser) updateUser;
  final Map<String, dynamic> models;
  final List<Plant> allPlants;
  final Map<String, Plant> transformedPlants;
  final List<dynamic> notifications;
  final List<FolderRecord> folders;
  const ScannedPlantsScreen(
      {super.key,
      required this.toggleTheme,
      required this.user,
      required this.updateUser,
      required this.models,
      required this.allPlants,
      required this.transformedPlants,
      required this.notifications,
      required this.folders});

  @override
  State<ScannedPlantsScreen> createState() => _ScannedPlantsScreenState();
}

class _ScannedPlantsScreenState extends State<ScannedPlantsScreen> {
  String searchQuery = '';
  int selectedIndex = 0;
  int previousIndex = -1;
  WifiManager wifiManager = WifiManager()..loadFakeNetworks();

  void setIndex(int index) {
    setState(() {
      previousIndex = selectedIndex;
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      PlantListSection(
          user: widget.user,
          updateUser: widget.updateUser,
          models: widget.models,
          allPlants: widget.allPlants,
          transformedPlants: widget.transformedPlants),
      LiveFeedScreen(),
      FolderSection(email: widget.user['email'], records: widget.folders),
      WifiSection(wifi: wifiManager),
      ProfileSection(),
      NotificationScreen(notifications: widget.notifications),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.themedColor(context, AppColors.white, AppColors.gray900),
        leading: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Image.asset(
            'assets/icons/LOGO.ico',
            width: 8,
            height: 8,
            fit: BoxFit.contain,
          ),
        ),
        title: Row(
          children: [
            Text(
              "AGRI-BOT STUDIO",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            SizedBox(width: 10),
            Icon(Icons.circle, color: Colors.lightGreenAccent, size: 12),
            SizedBox(width: 5),
            Text(
              "Connected",
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.brightness_6),
            onPressed: widget.toggleTheme,
          ),
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Confirm Logout"),
                  content: const Text("Are you sure you want to logout?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.red500),
                      onPressed: () async {
                        UserDataStore store = UserDataStore();
                        store.user.value = {};
                        await store.saveData();
                        if (mounted) {
                          Navigator.of(this.context).pushReplacement(MaterialPageRoute(
                            builder: (_) => AuthScreen(
                              toggleTheme: widget.toggleTheme,
                              user: widget.user,
                              updateUser: widget.updateUser,
                            ),
                          ));
                        }
                      },
                      child: const Text("Logout", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          ),
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
      bottomNavigationBar: AnimatedContainer(
        duration: Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: BottomAppBar(
          color: AppColors.themedColor(context, AppColors.white, AppColors.gray900),
          shape: CircularNotchedRectangle(),
          notchMargin: selectedIndex == 0 || selectedIndex == 3 ? 16.0 : 0.0,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              AnimatedAlign(
                duration: Duration(milliseconds: 300),
                alignment: Alignment.center,
                child: IconButton(
                  icon: Icon(Icons.settings, color: selectedIndex == 0 ? Colors.green : Colors.grey),
                  onPressed: () => setIndex(0),
                ),
              ),
              if (ConnectionService().isConnected.value) ...[
                Spacer(),
                AnimatedAlign(
                  duration: Duration(milliseconds: 300),
                  alignment: Alignment.center,
                  child: IconButton(
                    icon: Icon(Icons.live_tv, color: selectedIndex == 1 ? Colors.green : Colors.grey),
                    onPressed: () => setIndex(1),
                  ),
                ),
                Spacer(),
                AnimatedAlign(
                  duration: Duration(milliseconds: 300),
                  alignment: Alignment.center,
                  child: IconButton(
                    icon: Icon(Icons.wifi, color: selectedIndex == 3 ? Colors.green : Colors.grey),
                    onPressed: () => setIndex(3),
                  ),
                ),
                Spacer(),
                AnimatedAlign(
                  duration: Duration(milliseconds: 300),
                  alignment: Alignment.center,
                  child: IconButton(
                    icon: Icon(Icons.history, color: selectedIndex == 4 ? Colors.green : Colors.grey),
                    onPressed: () => setIndex(4),
                  ),
                ),
              ],
              Spacer(),
              AnimatedAlign(
                duration: Duration(milliseconds: 300),
                alignment: Alignment.center,
                child: IconButton(
                  icon: Icon(Icons.folder, color: selectedIndex == 2 ? Colors.green : Colors.grey),
                  onPressed: () => setIndex(2),
                ),
              ),
              Spacer(),
              AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                alignment: Alignment.center,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.notifications,
                        color: selectedIndex == 5 ? Colors.green : Colors.grey,
                      ),
                      onPressed: () => setIndex(5),
                    ),
                    if (selectedIndex != 5 && widget.notifications.any((n) => n['isRead'] == false))
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text(
                            () {
                              final unreadCount = widget.notifications.where((n) => n['isRead'] == false).length;
                              return unreadCount > 99 ? '99+' : unreadCount.toString();
                            }(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
