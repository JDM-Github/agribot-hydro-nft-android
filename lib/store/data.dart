import 'dart:convert';
import 'package:android/classes/default.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/struct.dart';

class UserDataStore {
  static final UserDataStore _instance = UserDataStore._internal();
  factory UserDataStore() => _instance;
  UserDataStore._internal();

  ValueNotifier<Map<String, dynamic>> user = ValueNotifier({});
  ValueNotifier<Models> models = ValueNotifier(Models());
  ValueNotifier<List<dynamic>> notifications = ValueNotifier([]);
  ValueNotifier<List<Plant>> allPlants = ValueNotifier([]);
  ValueNotifier<String> folderLastFetch = ValueNotifier("");
  ValueNotifier<List<FolderRecord>> folders = ValueNotifier([]);
  ValueNotifier<Map<String, List<Map<String, dynamic>>>> folderImages = ValueNotifier({});
  ValueNotifier<String> uuid = ValueNotifier("");
  ValueNotifier<List<dynamic>> tailscales = ValueNotifier([]);

  // SAVE BY VALUES
  ValueNotifier<DefaultConfig> userData = ValueNotifier(DefaultConfig());
  ValueNotifier<Map<String, Plant>> transformedPlants = ValueNotifier({});

  static const String _keyUserData = 'userData';
  static const String _keyUser = 'user';
  static const String _keyModels = 'models';
  static const String _keyPlants = 'plants';
  static const String _keyNotifications = 'notifications';
  static const String _keyFolderFetch = 'folderLastFetch';
  static const String _keyFolders = 'folders';
  static const String _keyFolderImages = 'folderImages';
  static const String _keyUiid = 'uuid';
  static const String _keyTailscales = 'tailscales';

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, jsonEncode(user.value));
    await prefs.setString(_keyModels, jsonEncode(models.value.toJson()));
    await prefs.setString(_keyPlants, jsonEncode(allPlants.value.map((p) => p.toJson()).toList()));
    await prefs.setString(_keyNotifications, jsonEncode(notifications.value));
    await prefs.setString(_keyFolderFetch, folderLastFetch.value);
    await prefs.setString(_keyFolders, jsonEncode(folders.value.map((f) => f.toJson()).toList()));
    await prefs.setString(_keyFolderImages, jsonEncode(folderImages.value));
    await prefs.setString(_keyUiid, uuid.value);
    await prefs.setString(_keyTailscales, jsonEncode(tailscales.value));
  }

  bool checkIfNotNull(String? check)  {
    return check != null;
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final loadUser = prefs.getString(_keyUser);
    final loadModels = prefs.getString(_keyModels);
    final loadPlants = prefs.getString(_keyPlants);
    final loadNotifactions = prefs.getString(_keyNotifications);
    final loadFolderFetch = prefs.getString(_keyFolderFetch);
    final loadFolders = prefs.getString(_keyFolders);
    final loadFolderImages = prefs.getString(_keyFolderImages);
    final loadUiid = prefs.getString(_keyUiid);
    final loadTailscales = prefs.getString(_keyTailscales);

    if (checkIfNotNull(loadUser)) user.value = jsonDecode(loadUser!);
    if (checkIfNotNull(loadModels)) models.value = Models.fromJson(jsonDecode(loadModels!));
    if (checkIfNotNull(loadPlants)) {
      final List<dynamic> list = jsonDecode(loadPlants!);
      final plantsList = list.map<Plant>((p) => Plant.fromJson(p)).toList();
      allPlants.value = plantsList;
      transformedPlants.value = {for (var plant in plantsList) plant.name: plant};
    }
    if (checkIfNotNull(loadNotifactions)) notifications.value = jsonDecode(loadNotifactions!);
    if (checkIfNotNull(loadFolderFetch)) folderLastFetch.value = loadFolderFetch!;
    if (checkIfNotNull(loadFolders)) {
      final List<dynamic> list = jsonDecode(loadFolders!);
      folders.value = list.map<FolderRecord>((f) => FolderRecord.fromJson(f)).toList();
    }
    if (checkIfNotNull(loadFolderImages)) {
      final Map<String, dynamic> decoded = jsonDecode(loadFolderImages!);
      folderImages.value = decoded.map((key, value) =>
        MapEntry(key, (value as List).map((item) => Map<String, dynamic>.from(item)).toList(),),
      );
    }
    if (checkIfNotNull(loadUiid)) uuid.value = loadUiid!;
    if (checkIfNotNull(loadTailscales)) tailscales.value = jsonDecode(loadTailscales!);

    DefaultConfig config = DefaultConfig(
      user: user.value, models: models.value, plants: allPlants.value,
      folders: folders.value, notifications: notifications.value, tailscaleDevices: tailscales.value
    );
    userData.value = config;
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_keyUserData);
    await prefs.remove(_keyUser);
    await prefs.remove(_keyModels);
    await prefs.remove(_keyPlants);
    await prefs.remove(_keyNotifications);
    await prefs.remove(_keyFolderFetch);
    await prefs.remove(_keyFolders);
    await prefs.remove(_keyFolderImages);
    await prefs.remove(_keyUiid);
    await prefs.remove(_keyTailscales);

    user.value = {};
    models.value = Models();
    notifications.value = [];
    allPlants.value = [];
    folderLastFetch.value = "";
    folders.value = [];
    folderImages.value = {};
    uuid.value = "";
    tailscales.value = [];

    userData.value = DefaultConfig();
    transformedPlants.value = {};
  }

  // NOTIFICATIONS
  Future<void> saveNotifications(List<dynamic> notifs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyNotifications, jsonEncode(notifs));
    notifications.value = notifs;
  }
  Future<void> addNotification(Map<String, dynamic> notif) async {
    final updated = [...notifications.value, notif];
    await saveNotifications(updated);
  }

  // SAVE USER
  Future<void> saveConfig(Map<String, dynamic> config) async {
    final prefs = await SharedPreferences.getInstance();
    user.value['config'] = config;
    await prefs.setString(_keyUser, jsonEncode(user.value));
  }

  Future<void> saveTailscale(List<dynamic> tailscale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTailscales, jsonEncode(tailscale));
    tailscales.value = tailscale;
  }

  bool isLoggedIn() => user.value.isNotEmpty && user.value.containsKey('id');
}
