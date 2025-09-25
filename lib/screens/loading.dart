import 'dart:async';
import 'dart:io';

import 'package:android/classes/snackbar.dart';
import 'package:android/handle_request.dart';
import 'package:android/screens/spray.dart';
import 'package:android/store/data.dart';
import 'package:android/utils/struct.dart';
import 'package:flutter/material.dart';

class LoadingScreen extends StatefulWidget {
  final UserDataStore store;
  const LoadingScreen({super.key, required this.store});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  String status = "Loading...";
  String currentTip = "";
  Timer? tipTimer;

  final List<String> tips = [
    "Remember to water your plants regularly!",
    "Check the soil moisture before watering.",
    "Give your plants enough sunlight.",
    "Prune dead leaves to encourage growth.",
    "Rotate your pots to ensure even sunlight.",
    "Use natural fertilizers when possible.",
    "Keep an eye on pests and insects.",
    "Clean your tools regularly to avoid contamination.",
    "Group plants with similar water needs together.",
    "Monitor the temperature and humidity.",
    "Repot plants when they outgrow their container.",
    "Use mulch to retain soil moisture.",
    "Avoid overwatering to prevent root rot.",
    "Label your plants for easy identification.",
    "Inspect leaves for signs of disease.",
    "Keep plants away from drafts and vents.",
    "Water early in the morning or late evening.",
    "Use pots with drainage holes.",
    "Keep a journal of plant growth.",
    "Experiment with companion planting.",
  ];

  @override
  void initState() {
    super.initState();
    _startTipRotation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _startTipRotation() {
    currentTip = tips[0];
    int index = 0;
    tipTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (!mounted) return;
      setState(() {
        index = (index + 1) % tips.length;
        currentTip = tips[index];
      });
    });
  }

  @override
  void dispose() {
    tipTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final store = widget.store;
    if (await _checkInternet()) {
      await store.loadData();
      if (mounted) AppSnackBar.loading(context, "Checking folders...", id: "folderFetch");
      setState(() => status = "Checking folders...");
      await _checkLastFolderFetch(store);
      if (mounted) AppSnackBar.hide(context, id: "folderFetch");

      if (mounted) AppSnackBar.loading(context, "Updating models...", id: "modelUpdate");
      setState(() => status = "Updating models...");
      await _checkForUpdates(store);
      if (mounted) AppSnackBar.hide(context, id: "modelUpdate");
    }
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ScannedPlantsScreen(
            toggleTheme: () {},
            user: widget.store.user.value,
            models: widget.store.models.value,
            folders: widget.store.folders.value,
            notifications: widget.store.notifications.value,
            allPlants: widget.store.allPlants.value,
            transformedPlants: widget.store.transformedPlants.value,
            updateUser: (newUser) => setState(() => widget.store.user.value = newUser),
          ),
        ),
      );
    }
  }

  Future<bool> _checkInternet() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _checkLastFolderFetch(UserDataStore store) async {
    if (!store.isLoggedIn()) return;
    final now = DateTime.now();
    final currentDaySlug = '${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.year}';
    if (currentDaySlug != store.folderLastFetch.value) {
      final handler = RequestHandler();

      try {
        final foldersResponse =
            await handler.handleRequest('folders', method: "POST", body: {'email': store.user.value['email']});
        if (foldersResponse['success'] == true) {
          final List<dynamic> foldersJson = foldersResponse['folders'];
          final List<FolderRecord> foldersList = foldersJson.map((f) => FolderRecord.fromJson(f)).toList();
          store.folders.value = foldersList;
          store.folderLastFetch.value = currentDaySlug;
          await store.saveData();
        }
      } catch (e) {
        debugPrint("Error fetching latest folders.");
      }
    }
  }

  Future<void> _checkForUpdates(UserDataStore store) async {
    final handler = RequestHandler();
    try {
      final response = await handler.handleRequest(
        'user/check-update',
        body: {'id': store.user.value['id']},
      );

      if (response['success'] == true) {
        Map<String, dynamic> data = response['data'];
        if (data.containsKey('user')) {
          store.user.value = data['user'];
          await store.saveConfig(data['user']['config']);
        }
        if (data.containsKey('yoloObjectDetection')) {
          store.models.value['yoloObjectDetection'] = data['yoloObjectDetection'];
        }
        if (data.containsKey('yoloStageClassification')) {
          store.models.value['yoloStageClassification'] = data['yoloStageClassification'];
        }
        if (data.containsKey('maskRCNNSegmentation')) {
          store.models.value['maskRCNNSegmentation'] = data['maskRCNNSegmentation'];
        }
        if (data.containsKey('notification')) {
          store.notifications.value = data['notification'];
        }
        if (data.containsKey('plants')) {
          final plantsJson = data['plants'];
          final List<Plant> allPlants = plantsJson.map<Plant>((p) => Plant.fromJson(p)).toList();
          final Map<String, Plant> transformedPlants = {for (var plant in allPlants) plant.name: plant};
          store.allPlants.value = allPlants;
          store.transformedPlants.value = transformedPlants;
        }
        await store.saveData();
      }
    } catch (e) {
      debugPrint("API check failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/LOGO TEXT.webp', width: 250),
            SizedBox(height: 20),
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(status),
            SizedBox(height: 10),
            Text(
              "Tip: $currentTip",
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
