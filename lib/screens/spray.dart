import 'package:android/classes/default.dart';
import 'package:android/classes/snackbar.dart';
import 'package:android/connection/all_states.dart';
import 'package:android/connection/connect.dart';
import 'package:android/connection/socketio.dart';
import 'package:android/handle_request.dart';
import 'package:android/modals/show_confirmation_modal.dart';
import 'package:android/requests/update.dart';
import 'package:android/screens/registration.dart';
import 'package:android/screens/section/folderdetail.dart';
import 'package:android/screens/section/folderscreen.dart';
import 'package:android/screens/section/livefeedscreen.dart';
import 'package:android/screens/section/log_viewer.dart';
import 'package:android/screens/section/notification.dart';
import 'package:android/screens/section/plantlistsection.dart';
import 'package:android/screens/section/profilesection.dart';
import 'package:android/screens/section/robotscreen.dart';
import 'package:android/screens/section/tailscale.dart';
import 'package:android/screens/section/wifiscreen.dart';
import 'package:android/store/data.dart';
import 'package:android/utils/colors.dart';
import 'package:android/utils/enums.dart';
import 'package:android/utils/struct.dart';
import 'package:circular_menu/circular_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class RadialMenuItem {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const RadialMenuItem({required this.icon, required this.color, required this.onTap});
}

class ScannedPlantsScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  const ScannedPlantsScreen({
    super.key,
    required this.toggleTheme,
  });

  @override
  State<ScannedPlantsScreen> createState() => _ScannedPlantsScreenState();
}

class _ScannedPlantsScreenState extends State<ScannedPlantsScreen> {
  final GlobalKey<CircularMenuState> _menuKey = GlobalKey<CircularMenuState>();
  final GlobalKey<TailscaleSectionState> tailscaleKey = GlobalKey<TailscaleSectionState>();
  final GlobalKey<PlantListSectionState> plantListKey = GlobalKey<PlantListSectionState>();
  final GlobalKey<FolderSectionState> folderListKey = GlobalKey<FolderSectionState>();
  final GlobalKey<NotificationScreenState> notificationKey = GlobalKey<NotificationScreenState>();
  OverlayEntry? _currentOverlay;

  late List<Widget> screens;
  String searchQuery = '';
  int selectedIndex = 0;
  int previousIndex = -1;
  bool _uploading = false;
  bool _isBusy = false;

  bool _fabVisible = true;
  String currentActions = '';

  void handleConnection() {
    Connection.onError = (msg) {
      AppSnackBar.hide(context, id: 'connection-loading');
      AppSnackBar.error(context, msg);
    };

    Connection.onConnect = (msg) {
      AppSnackBar.hide(context, id: 'connection-loading');
      AppSnackBar.success(context, msg);
    };

    Connection.onDisconnect = (msg) {
      AppSnackBar.info(context, msg);
    };

    if (!AllStates.allState.value['conn']) {
      AllStates.listenAll();
      AppSnackBar.loading(context, 'Connecting...', id: 'connection-loading');
      Connection.init();
      Connection.connect();
    } else {
      Connection.disconnect();
      AllStates.dispose();
    }
  }

  UserDataStore data = UserDataStore();
  WifiManager wifiManager = WifiManager();

  String getPage(int index) {
    if (index == 1) return "live";
    if (index == 7) return "logs";
    if (index == 8) return "sensor";
    return "";
  }

  void setIndex(int index) {
    previousIndex = selectedIndex;
    setState(() {
      selectedIndex = index;
    });
  }

  void _openCircularMenu({actions = ''}) {
    currentActions = actions;

    _currentOverlay ??= OverlayEntry(
      builder: (_) => Positioned.fill(
        child: Stack(
          children: [
            GestureDetector(
              onTap: _closeCircularMenu,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: 0.8,
                child: Container(color: AppColors.gray900),
              ),
            ),
            Center(
              child: CircularMenu(
                key: _menuKey,
                alignment: Alignment.center,
                toggleButtonColor: AppColors.themedColor(context, AppColors.gray400, AppColors.gray600),
                toggleButtonIconColor: Colors.white,
                toggleButtonAnimatedIconData: AnimatedIcons.home_menu,
                toggleButtonOnPressed: _closeCircularMenu,
                backgroundWidget: null,
                toggleButtonBoxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(60),
                    spreadRadius: 2,
                    blurRadius: 6,
                    offset: const Offset(2, 4),
                  ),
                ],
                items: _getCircleItems(currentActions),
              ),
            ),
          ],
        ),
      ),
    );

    Overlay.of(context).insert(_currentOverlay!);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _menuKey.currentState?.forwardAnimation();
    });
  }

  Future<void> _closeCircularMenu() async {
    _menuKey.currentState?.reverseAnimation();
    await Future.delayed(const Duration(milliseconds: 400));
    _currentOverlay?.remove();
    _currentOverlay = null;
  }

  Future<void> syncEverything(bool isForce) async {
    setState(() => _isBusy = true);
    final plant = plantListKey.currentState;
    final tailscale = tailscaleKey.currentState;
    final folders = folderListKey.currentState;
    final notif = notificationKey.currentState;

    AppSnackBar.loading(context, isForce ? "Force syncing data..." : "Syncing data...", id: "force-sync");

    final result = await CustomUpdater.forceUpdate(
      state: this,
      deviceID: data.uuid.value,
      isForce: isForce,
    );

    DefaultConfig newConfig = result['data'];
    final Map<String, Plant> transformedPlants = {for (var plant in newConfig.plants) plant.name: plant};

    final now = DateTime.now();
    final currentDaySlug = '${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.year}';

    data.userData.value = newConfig;
    data.user.value = newConfig.user;
    data.models.value = newConfig.models;
    data.notifications.value = newConfig.notifications;
    data.allPlants.value = newConfig.plants;
    data.transformedPlants.value = transformedPlants;
    data.folderLastFetch.value = currentDaySlug;
    data.folders.value = newConfig.folders;
    data.tailscales.value = newConfig.tailscaleDevices;
    await data.saveData();

    plant?.updateConfig();
    tailscale?.updateTailscale();
    folders?.updateFolders();
    notif?.updateNotifications();

    if (mounted) {
      AppSnackBar.hide(context, id: "force-sync");
      AppSnackBar.success(context, isForce ? "Force sync data is successful!" : "Sync data is successful!");
    }

    setState(() => _isBusy = false);
  }

  @override
  void initState() {
    super.initState();
    screens = [
      TailscaleSection(
          key: tailscaleKey,
          user: data.user.value,
          show: () => {setState(() => _fabVisible = false)},
          hide: () => {setState(() => _fabVisible = true)}),
      LiveFeedScreen(),
      FolderSection(key: folderListKey, email: data.user.value['email']),
      WifiSection(wifi: wifiManager),
      ProfileSection(),
      NotificationScreen(key: notificationKey, hide: () => {setState(() => _fabVisible = true)}),
      PlantListSection(key: plantListKey, isBusy: _isBusy, hide: () => {setState(() => _fabVisible = true)}),
      LogViewerScreen(),
      RobotScreen(),
    ];
  }

  Future<void> _openFolder(String slug) async {
    UserDataStore store = UserDataStore();
    final folder = store.folders.value.firstWhere(
      (f) => f.slug == slug,
      orElse: () {
        AppSnackBar.error(context, "Folder not found for slug: $slug");
        return FolderRecord(
          slug: slug,
          date: '',
          name: 'Unknown Folder',
          imageUrl: '',
        );
      },
    );
    if (folder.name == 'Unknown Folder') return;
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
        final email = data.user.value['email'];
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
          store.folderImages.value = {...cached, slug: images};
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>>(
        valueListenable: AllStates.allState,
        builder: (_, state, __) {
          if (SocketService.isConnected) {
            SocketService.emit("page_leave", {"id": SocketService.id, "page": getPage(previousIndex)});
            SocketService.emit("page_enter", {"id": SocketService.id, "page": getPage(selectedIndex)});
          }
          final isConnected = state["conn"] == true;
          final hideFab = _isBusy ||
              selectedIndex == 7 ||
              selectedIndex == 8 ||
              selectedIndex == 1 &&
                  (!state["conn"] || state["robot"] != 0 || state["scan"] || state["rscan"] || state["robotLive"]);

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
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "AGRI-BOT STUDIO",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ElevatedButton.icon(
                    onPressed: handleConnection,
                    icon: Icon(
                      Icons.circle,
                      color: isConnected ? Colors.lightGreenAccent : Colors.redAccent,
                      size: 10,
                    ),
                    label: Text(
                      isConnected ? "Connected" : "Disconnected",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (isConnected ? Colors.green : Colors.red).withAlpha(40),
                      foregroundColor: isConnected ? Colors.green.shade800 : Colors.red.shade800,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
              actions: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async => await syncEverything(false),
                    onLongPress: () async => await syncEverything(true),
                    borderRadius: BorderRadius.circular(24),
                    splashColor: Colors.white24,
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.sync),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.brightness_6),
                  onPressed: widget.toggleTheme,
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  color: AppColors.red500,
                  tooltip: 'Logout',
                  onPressed: () async {
                    final confirmed = await showConfirmationModal(
                        context: context,
                        title: "Confirm Logout",
                        message: "Are you sure you want to logout?",
                        buttonText: "Logout");
                    if (confirmed != true) return;
                    if (mounted) {
                      await data.saveData();
                      // ignore: use_build_context_synchronously
                      Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (_) => AuthScreen(
                          toggleTheme: widget.toggleTheme,
                        ),
                      ));
                    }
                  },
                ),
              ],
            ),
            floatingActionButton: hideFab
                ? null
                : AnimatedSlide(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    offset: _fabVisible ? Offset(0, 0) : Offset(2, 0),
                    child: SpeedDial(
                        icon: Icons.add,
                        foregroundColor: Colors.white,
                        activeIcon: Icons.close,
                        backgroundColor: Colors.green,
                        spacing: 10,
                        spaceBetweenChildren: 8,
                        overlayColor: AppColors.gray950,
                        animationDuration: const Duration(milliseconds: 300),
                        children: _getSpeedDialChildren(selectedIndex, this.context)),
                  ),
            backgroundColor: AppColors.themedColor(context, AppColors.gray200, AppColors.gray700),
            body: AnimatedSwitcher(
              duration: const Duration(milliseconds: 100),
              transitionBuilder: (Widget child, Animation<double> animation) {
                final slideAnimation = Tween<Offset>(
                  begin: Offset(selectedIndex > previousIndex ? -1.0 : 1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut));

                return SlideTransition(
                  position: slideAnimation,
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey<int>(selectedIndex),
                child: screens[selectedIndex],
              ),
            ),
            bottomNavigationBar: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeInOut,
              child: BottomAppBar(
                color: AppColors.themedColor(context, AppColors.white, AppColors.gray900),
                shape: const CircularNotchedRectangle(),
                child: Stack(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: isConnected ? 2 : 20),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Align(
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ..._buildNavItems(context, isConnected)
                                  .expand((w) => [w, const SizedBox(width: 12)])
                                  .toList()
                                ..removeLast(),
                              const SizedBox(width: 12),
                              _buildNotificationButton(context),
                              const SizedBox(width: 12),
                              _buildIconButton(Icons.person, 4),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 20,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              AppColors.themedColor(context, AppColors.white, AppColors.gray900),
                              AppColors.themedColor(context, AppColors.white, AppColors.gray900).withAlpha(0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        width: 20,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerRight,
                            end: Alignment.centerLeft,
                            colors: [
                              AppColors.themedColor(context, AppColors.white, AppColors.gray900),
                              AppColors.themedColor(context, AppColors.white, AppColors.gray900).withAlpha(0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }

  List<SpeedDialChild> _getSpeedDialChildren(int selectedIndex, BuildContext context) {
    switch (selectedIndex) {
      case 0:
        return [
          SpeedDialChild(
            child: Icon(Icons.help, color: AppColors.themedColor(context, AppColors.gray700, AppColors.gray300)),
            label: 'Help',
            backgroundColor: AppColors.themedColor(context, AppColors.gray100, AppColors.gray800),
            labelBackgroundColor: AppColors.themedColor(context, AppColors.gray200, AppColors.gray700),
            onTap: () {
              final tailscale = tailscaleKey.currentState!;
              setState(() => _fabVisible = false);
              tailscale.showTutorial.value = true;
            },
          ),
          SpeedDialChild(
              child: Icon(Icons.sync, color: AppColors.themedColor(context, AppColors.blue500, AppColors.blue700)),
              label: 'Force Sync',
              backgroundColor: AppColors.themedColor(context, AppColors.gray100, AppColors.gray800),
              labelBackgroundColor: AppColors.themedColor(context, AppColors.gray200, AppColors.gray700),
              onTap: () async {
                setState(() => _isBusy = true);
                final tailscale = tailscaleKey.currentState!;
                await tailscale.forceSync();
                setState(() => _isBusy = false);
              }),
          SpeedDialChild(
              child: Icon(Icons.key, color: AppColors.themedColor(context, AppColors.green500, AppColors.green700)),
              label: 'Request Auth Key',
              backgroundColor: AppColors.themedColor(context, AppColors.gray100, AppColors.gray800),
              labelBackgroundColor: AppColors.themedColor(context, AppColors.gray200, AppColors.gray700),
              onTap: () {
                setState(() => _isBusy = true);
                setState(() => _fabVisible = false);
                tailscaleKey.currentState?.showRequest.value = true;
                setState(() => _isBusy = false);
              }),
          SpeedDialChild(
              child: Icon(Icons.app_registration,
                  color: AppColors.themedColor(context, AppColors.green500, AppColors.green700)),
              label: 'Manually Register',
              backgroundColor: AppColors.themedColor(context, AppColors.gray100, AppColors.gray800),
              labelBackgroundColor: AppColors.themedColor(context, AppColors.gray200, AppColors.gray700),
              onTap: () {
                setState(() => _isBusy = true);
                setState(() => _fabVisible = false);
                tailscaleKey.currentState?.showManualReg.value = true;
                setState(() => _isBusy = false);
              }),
        ];
      case 1:
        return [
          SpeedDialChild(
              child: Icon(
                Icons.play_arrow,
                color: AppColors.themedColor(context, AppColors.blue500, AppColors.blue700),
              ),
              label: 'Run Livestream',
              backgroundColor: AppColors.themedColor(context, AppColors.gray100, AppColors.gray800),
              labelBackgroundColor: AppColors.themedColor(context, AppColors.gray200, AppColors.gray700),
              onTap: () => {LiveFeedScreen.controlLivestream(this, LiveStreamAction.run)}),
          SpeedDialChild(
              child: Icon(
                Icons.stop,
                color: AppColors.themedColor(context, AppColors.red500, AppColors.red700),
              ),
              label: 'Stop Livestream',
              backgroundColor: AppColors.themedColor(context, AppColors.gray100, AppColors.gray800),
              labelBackgroundColor: AppColors.themedColor(context, AppColors.gray200, AppColors.gray700),
              onTap: () => {LiveFeedScreen.controlLivestream(this, LiveStreamAction.stop)}),
          SpeedDialChild(
              child: Icon(
                Icons.pause,
                color: AppColors.themedColor(context, AppColors.green500, AppColors.green700),
              ),
              label: 'Pause Livestream',
              backgroundColor: AppColors.themedColor(context, AppColors.gray100, AppColors.gray800),
              labelBackgroundColor: AppColors.themedColor(context, AppColors.gray200, AppColors.gray700),
              onTap: () => {LiveFeedScreen.controlLivestream(this, LiveStreamAction.pause)}),
          SpeedDialChild(
            child: Icon(
              Icons.upload_file,
              color: AppColors.themedColor(context, AppColors.green500, AppColors.green700),
            ),
            label: 'Upload Image',
            backgroundColor: AppColors.themedColor(context, AppColors.gray100, AppColors.gray800),
            labelBackgroundColor: AppColors.themedColor(context, AppColors.gray200, AppColors.gray700),
            onTap: () async {
              setState(() => _isBusy = true);
              try {
                if (_uploading) {
                  AppSnackBar.error(context, "Upload already in progress.");
                  return;
                }
                _uploading = true;
                await LiveFeedScreen.uploadImage(this);
              } finally {
                _uploading = false;
              }
              setState(() => _isBusy = false);
            },
          ),
          SpeedDialChild(
            child: Icon(
              Icons.computer,
              color: AppColors.themedColor(context, AppColors.orange500, AppColors.orange700),
            ),
            label: 'View Today Records',
            backgroundColor: AppColors.themedColor(context, AppColors.gray100, AppColors.gray800),
            labelBackgroundColor: AppColors.themedColor(context, AppColors.gray200, AppColors.gray700),
            onTap: () async {
              setState(() => _isBusy = true);
              final now = DateTime.now();
              final todaySlug =
                  '${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.year}';
              await _openFolder(todaySlug);
              setState(() => _isBusy = false);
            },
          ),
        ];
      case 2:
        return [
          SpeedDialChild(
              child: Icon(Icons.sync, color: AppColors.themedColor(context, AppColors.blue500, AppColors.blue700)),
              label: 'Force Sync',
              backgroundColor: AppColors.themedColor(context, AppColors.gray100, AppColors.gray800),
              labelBackgroundColor: AppColors.themedColor(context, AppColors.gray200, AppColors.gray700),
              onTap: () async {
                setState(() => _isBusy = true);
                final folders = folderListKey.currentState!;
                await folders.forceSync();
                setState(() => _isBusy = false);
              }),
          SpeedDialChild(
            child: Icon(Icons.sort_by_alpha,
                color: AppColors.themedColor(context, AppColors.green500, AppColors.green700)),
            label: 'Sort To Newest',
            backgroundColor: AppColors.themedColor(context, AppColors.gray100, AppColors.gray800),
            labelBackgroundColor: AppColors.themedColor(context, AppColors.gray200, AppColors.gray700),
            onTap: () => folderListKey.currentState?.sortRecords('desc'),
          ),
          SpeedDialChild(
            child: Icon(Icons.sort_by_alpha,
                color: AppColors.themedColor(context, AppColors.orange500, AppColors.orange700)),
            label: 'Sort To Oldest',
            backgroundColor: AppColors.themedColor(context, AppColors.gray100, AppColors.gray800),
            labelBackgroundColor: AppColors.themedColor(context, AppColors.gray200, AppColors.gray700),
            onTap: () => folderListKey.currentState?.sortRecords('asc'),
          ),
        ];
      case 3:
        return [
          SpeedDialChild(
              child: Icon(Icons.wifi, color: AppColors.themedColor(context, AppColors.blue500, AppColors.green500)),
              label: 'Scan Networks',
              backgroundColor: AppColors.themedColor(context, AppColors.gray100, AppColors.gray800),
              labelBackgroundColor: AppColors.themedColor(context, AppColors.gray200, AppColors.gray700),
              onTap: () async {
                setState(() => _isBusy = true);
                await wifiManager.scanNetworks(context);
                setState(() => _isBusy = false);
              }),
        ];
      case 5:
        return [
          SpeedDialChild(
              child: Icon(Icons.sync, color: AppColors.themedColor(context, AppColors.blue500, AppColors.blue700)),
              label: 'Force Sync',
              backgroundColor: AppColors.themedColor(context, AppColors.gray100, AppColors.gray800),
              labelBackgroundColor: AppColors.themedColor(context, AppColors.gray200, AppColors.gray700),
              onTap: () async {
                setState(() => _isBusy = true);
                final notif = notificationKey.currentState!;
                await notif.forceSync();
                setState(() => _isBusy = false);
              }),
        ];
      case 6:
        return [
          SpeedDialChild(
              child: Icon(Icons.help, color: AppColors.themedColor(context, AppColors.gray700, AppColors.gray300)),
              label: 'Help',
              backgroundColor: AppColors.themedColor(context, AppColors.gray100, AppColors.gray800),
              labelBackgroundColor: AppColors.themedColor(context, AppColors.gray200, AppColors.gray700),
              onTap: () {
                final plant = plantListKey.currentState!;
                setState(() => _fabVisible = false);
                plant.showTutorial.value = true;
              }),
          SpeedDialChild(
              child: Icon(Icons.sync, color: AppColors.themedColor(context, AppColors.blue500, AppColors.blue700)),
              label: 'Force Sync',
              backgroundColor: AppColors.themedColor(context, AppColors.gray100, AppColors.gray800),
              labelBackgroundColor: AppColors.themedColor(context, AppColors.gray200, AppColors.gray700),
              onTap: () async {
                setState(() => _isBusy = true);
                final plant = plantListKey.currentState!;
                await plant.forceSync();
                setState(() => _isBusy = false);
              }),
          SpeedDialChild(
            child: Icon(Icons.build, color: AppColors.themedColor(context, AppColors.green500, AppColors.green700)),
            label: 'Model Actions',
            backgroundColor: AppColors.themedColor(context, AppColors.gray100, AppColors.gray800),
            labelBackgroundColor: AppColors.themedColor(context, AppColors.gray200, AppColors.gray700),
            onTap: () => _openCircularMenu(actions: 'Model Actions'),
          ),
          SpeedDialChild(
            child:
                Icon(Icons.assessment, color: AppColors.themedColor(context, AppColors.orange500, AppColors.orange700)),
            label: 'Model Confidence',
            backgroundColor: AppColors.themedColor(context, AppColors.gray100, AppColors.gray800),
            labelBackgroundColor: AppColors.themedColor(context, AppColors.gray200, AppColors.gray700),
            onTap: () => _openCircularMenu(actions: 'Model Confidence'),
          ),
          SpeedDialChild(
            child:
                Icon(Icons.settings, color: AppColors.themedColor(context, AppColors.purple500, AppColors.purple700)),
            label: 'Configuration Actions',
            backgroundColor: AppColors.themedColor(context, AppColors.gray100, AppColors.gray800),
            labelBackgroundColor: AppColors.themedColor(context, AppColors.gray200, AppColors.gray700),
            onTap: () => _openCircularMenu(actions: 'Configuration Actions'),
          ),
          SpeedDialChild(
            child: Icon(Icons.play_arrow, color: AppColors.themedColor(context, AppColors.teal500, AppColors.teal700)),
            label: 'Setup Actions',
            backgroundColor: AppColors.themedColor(context, AppColors.gray100, AppColors.gray800),
            labelBackgroundColor: AppColors.themedColor(context, AppColors.gray200, AppColors.gray700),
            onTap: () => _openCircularMenu(actions: 'Setup Actions'),
          ),
        ];

      default:
        return [
        ];
    }
  }

  List<CircularMenuItem> _getCircleItems(String actions) {
    if (actions == 'Model Actions') {
      return [
        buildCircularMenuItem(
          icon: Icons.compare,
          color: AppColors.blue500,
          onTap: () async {
            await _closeCircularMenu();
            final plant = plantListKey.currentState!;
            setState(() => _fabVisible = false);
            plant.compareModal.value = true;
          },
          badgeText: "Compare",
        ),
        buildCircularMenuItem(
          icon: Icons.visibility,
          color: AppColors.green500,
          onTap: () async {
            await _closeCircularMenu();
            final plant = plantListKey.currentState!;
            setState(() => _fabVisible = false);
            plant.chooseModalChange("obj");
          },
          badgeText: "OBJ Model",
        ),
        buildCircularMenuItem(
          icon: Icons.category,
          color: AppColors.orange500,
          onTap: () async {
            await _closeCircularMenu();
            final plant = plantListKey.currentState!;
            setState(() => _fabVisible = false);
            plant.chooseModalChange("cls");
          },
          badgeText: "CLS Model",
        ),
        buildCircularMenuItem(
          icon: Icons.layers,
          color: AppColors.purple500,
          onTap: () async {
            await _closeCircularMenu();
            final plant = plantListKey.currentState!;
            setState(() => _fabVisible = false);
            plant.chooseModalChange("seg");
          },
          badgeText: "SEG Model",
        ),
      ];
    } else if (actions == 'Model Confidence') {
      return [
        buildCircularMenuItem(
          icon: Icons.show_chart,
          color: AppColors.blue500,
          onTap: () async {
            await _closeCircularMenu();
            final plant = plantListKey.currentState!;
            setState(() => _fabVisible = false);
            plant.changeTarget("obj");
          },
          badgeText: "OBJ %",
        ),
        buildCircularMenuItem(
          icon: Icons.bar_chart,
          color: AppColors.green500,
          onTap: () async {
            await _closeCircularMenu();
            final plant = plantListKey.currentState!;
            setState(() => _fabVisible = false);
            plant.changeTarget("cls");
          },
          badgeText: "CLS %",
        ),
        buildCircularMenuItem(
          icon: Icons.layers,
          color: AppColors.purple500,
          onTap: () async {
            await _closeCircularMenu();
            final plant = plantListKey.currentState!;
            setState(() => _fabVisible = false);
            plant.changeTarget("seg");
          },
          badgeText: "SEG %",
        ),
      ];
    } else if (actions == 'Configuration Actions') {
      return [
        buildCircularMenuItem(
          icon: Icons.save,
          color: AppColors.green500,
          onTap: () async {
            setState(() => _isBusy = true);
            await _closeCircularMenu();
            final plant = plantListKey.currentState!;
            await plant.saveConfig(plant);
            setState(() => _isBusy = false);

            final notif = notificationKey.currentState!;
            notif.updateNotifications();
          },
          badgeText: "Save",
        ),
        buildCircularMenuItem(
          icon: Icons.download,
          color: AppColors.blue500,
          onTap: () async {
            setState(() => _isBusy = true);
            await _closeCircularMenu();
            final plant = plantListKey.currentState!;
            await plant.exportOrShareConfig(plant, plant.config);
            setState(() => _isBusy = false);
          },
          badgeText: "Download",
        ),
        buildCircularMenuItem(
          icon: Icons.upload,
          color: AppColors.orange500,
          onTap: () async {
            setState(() => _isBusy = true);
            await _closeCircularMenu();
            final plant = plantListKey.currentState!;
            await plant.uploadConfig(plant, plant.config);
            setState(() => _isBusy = false);
          },
          badgeText: "Upload",
        ),
      ];
    } else if (actions == 'Setup Actions') {
      return [
        buildCircularMenuItem(
          icon: Icons.water_drop,
          color: AppColors.teal500,
          onTap: () async {
            await _closeCircularMenu();
            final plant = plantListKey.currentState!;
            setState(() => _fabVisible = false);
            plant.showSprayModal.value = true;
          },
          badgeText: "Setup Spray",
        ),
        buildCircularMenuItem(
          icon: Icons.schedule,
          color: AppColors.blue500,
          onTap: () async {
            await _closeCircularMenu();
            final plant = plantListKey.currentState!;
            setState(() => _fabVisible = false);
            plant.showScheduleModal.value = true;
          },
          badgeText: "Set Schedule",
        ),
        buildCircularMenuItem(
          icon: Icons.eco,
          color: AppColors.green500,
          onTap: () async {
            await _closeCircularMenu();
            final plant = plantListKey.currentState!;
            setState(() => _fabVisible = false);
            plant.showAddPlantModal.value = true;
          },
          badgeText: "Add Plant",
        ),
      ];
    }

    return [CircularMenuItem(onTap: () => {})];
  }

  List<Widget> _buildNavItems(BuildContext context, bool isConnected) {
    final items = [
      {'icon': Icons.home, 'index': 0},
      {'icon': Icons.eco, 'index': 6},
      if (isConnected) ...[
        {'icon': Icons.live_tv, 'index': 1},
        {'icon': Icons.wifi, 'index': 3},
        {'icon': Icons.smart_toy, 'index': 8},
        {'icon': Icons.history, 'index': 7},
      ],
      {'icon': Icons.folder, 'index': 2},
    ];

    return items.map((item) => _buildIconButton(item['icon'] as IconData, item['index'] as int)).toList();
  }

  Widget _buildIconButton(IconData icon, int index) {
    return AnimatedAlign(
      duration: const Duration(milliseconds: 300),
      alignment: Alignment.center,
      child: IconButton(
          icon: Icon(icon, color: selectedIndex == index ? Colors.green : Colors.grey),
          onPressed: () {
            if (_isBusy) {
              AppSnackBar.error(context, "AGRI-BOT is currently busy...");
              return;
            }
            setIndex(index);
            if (index == 4) {
              setState(() => _fabVisible = false);
            } else {
              setState(() => _fabVisible = true);
            }
          }),
    );
  }

  Widget _buildNotificationButton(BuildContext context) {
    final unreadCount = data.notifications.value.where((n) => n['isRead'] == false).length;
    final hasUnread = unreadCount > 0;

    return AnimatedAlign(
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
          if (hasUnread)
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
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
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
    );
  }

  CircularMenuItem buildCircularMenuItem({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String badgeText,
  }) {
    return CircularMenuItem(
      icon: icon,
      color: AppColors.themedColor(context, AppColors.gray50, AppColors.gray700),
      iconColor: color,
      onTap: onTap,
      enableBadge: true,
      badgeLabel: badgeText,
      badgeTextColor: AppColors.themedColor(context, AppColors.gray700, AppColors.white),
      badgeColor: Colors.transparent,
      badgeTopOffet: 60,
      badgeLeftOffet: 0,
      badgeRightOffet: 0,
      badgeBottomOffet: 0,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha(60),
          spreadRadius: 2,
          blurRadius: 6,
          offset: const Offset(2, 4),
        ),
      ],
      iconSize: 60,
      badgeTextStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: AppColors.themedColor(context, AppColors.gray700, AppColors.white),
      ),
    );
  }
}
