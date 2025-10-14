import 'dart:async';
import 'dart:io';

import 'package:android/classes/default.dart';
import 'package:android/requests/update.dart';
import 'package:android/screens/spray.dart';
import 'package:android/store/data.dart';
import 'package:android/utils/struct.dart';
import 'package:flutter/material.dart';

class LoadingScreen extends StatefulWidget {
  final Function() toggleTheme;
  const LoadingScreen({super.key, required this.toggleTheme});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  String status = "Loading...";
  String currentTip = "";
  Timer? tipTimer;

  UserDataStore data = UserDataStore();

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
    if (await _checkInternet()) {

      final result = await CustomUpdater.forceUpdate(
        state: this,
        deviceID: data.uuid.value
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
    }
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ScannedPlantsScreen(
            toggleTheme: widget.toggleTheme,
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
