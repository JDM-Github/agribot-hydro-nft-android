import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/struct.dart';

class UserDataStore {
  static final UserDataStore _instance = UserDataStore._internal();
  factory UserDataStore() => _instance;
  UserDataStore._internal();

  ValueNotifier<String> folderLastFetch = ValueNotifier("");
  ValueNotifier<Map<String, dynamic>> user = ValueNotifier({});
  ValueNotifier<Map<String, dynamic>> models = ValueNotifier({});
  ValueNotifier<List<Plant>> allPlants = ValueNotifier([]);
  ValueNotifier<Map<String, Plant>> transformedPlants = ValueNotifier({});
  ValueNotifier<List<dynamic>> notifications = ValueNotifier([]);
  ValueNotifier<List<FolderRecord>> folders = ValueNotifier([]);
  ValueNotifier<Map<String, List<Map<String, dynamic>>>> folderImages = ValueNotifier({});

  static const String _keyUser = 'user';
  static const String _keyModels = 'models';
  static const String _keyPlants = 'plants';
  static const String _keyConfig = 'config';
  static const String _keyNotifications = 'notifications';
  static const String _keyFolderFetch = 'lastFolderFetch';
  static const String _keyFolders = 'folders';
  static const String _keyFolderImages = 'folderImages';

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFolderFetch, folderLastFetch.value);
    await prefs.setString(_keyUser, jsonEncode(user.value));
    await prefs.setString(_keyModels, jsonEncode(models.value));
    await prefs.setString(
      _keyPlants,
      jsonEncode(allPlants.value.map((p) => p.toJson()).toList()),
    );
    await prefs.setString(
      _keyNotifications,
      jsonEncode(notifications.value),
    );
    await prefs.setString(
      _keyFolders,
      jsonEncode(folders.value.map((f) => f.toJson()).toList()),
    );
    await prefs.setString(
      _keyFolderImages,
      jsonEncode(folderImages.value),
    );
    if (user.value.containsKey('config')) {
      await prefs.setString(_keyConfig, jsonEncode(user.value['config']));
    }
  }

  Future<void> saveConfig(Map<String, dynamic> config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyConfig, jsonEncode(config));

    user.value = {
      ...user.value,
      'config': config,
    };
  }

  Future<void> saveNotifications(List<dynamic> notifs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyNotifications, jsonEncode(notifs));
    notifications.value = notifs;
  }

  Future<void> addNotification(Map<String, dynamic> notif) async {
    final updated = [...notifications.value, notif];
    await saveNotifications(updated);
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_keyUser);
    final modelsData = prefs.getString(_keyModels);
    final plantsData = prefs.getString(_keyPlants);
    final configData = prefs.getString(_keyConfig);
    final notifsData = prefs.getString(_keyNotifications);
    final foldersData = prefs.getString(_keyFolders);
    final folderImagesData = prefs.getString(_keyFolderImages);
    final folderFetchData = prefs.getString(_keyFolderFetch);

    if (userData != null) user.value = jsonDecode(userData);
    if (modelsData != null) models.value = jsonDecode(modelsData);
    if (plantsData != null) {
      final List<dynamic> list = jsonDecode(plantsData);
      final plantsList = list.map<Plant>((p) => Plant.fromJson(p)).toList();
      allPlants.value = plantsList;
      transformedPlants.value = {for (var plant in plantsList) plant.name: plant};
    }
    if (configData != null) {
      user.value = {
        ...user.value,
        'config': jsonDecode(configData),
      };
    }
    if (notifsData != null) {
      final List<dynamic> list = jsonDecode(notifsData);
      notifications.value = list.map<Map<String, dynamic>>((n) => Map<String, dynamic>.from(n)).toList();
    }
    if (foldersData != null) {
      final List<dynamic> list = jsonDecode(foldersData);
      folders.value = list.map<FolderRecord>((f) => FolderRecord.fromJson(f)).toList();
    }
    if (folderImagesData != null) {
      final Map<String, dynamic> decoded = jsonDecode(folderImagesData);
      folderImages.value = decoded.map(
        (key, value) => MapEntry(
          key,
          (value as List).map((item) => Map<String, dynamic>.from(item)).toList(),
        ),
      );
    }
    if (folderFetchData != null) {
      folderLastFetch.value = folderFetchData;
    }
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_keyUser);
    await prefs.remove(_keyModels);
    await prefs.remove(_keyPlants);
    await prefs.remove(_keyConfig);
    await prefs.remove(_keyNotifications);
    await prefs.remove(_keyFolders);
    await prefs.remove(_keyFolderImages);
    await prefs.remove(_keyFolderFetch);

    user.value = {};
    models.value = {};
    allPlants.value = [];
    transformedPlants.value = {};
    notifications.value = [];
    folders.value = [];
    folderImages.value = {};
    folderLastFetch.value = "";
  }

  bool hasData() =>
      user.value.isNotEmpty &&
      allPlants.value.isNotEmpty &&
      models.value.isNotEmpty &&
      user.value.containsKey('config');

  bool isLoggedIn() => user.value.isNotEmpty && user.value.containsKey('id');
}
