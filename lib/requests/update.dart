import 'package:android/classes/default.dart';
import 'package:android/classes/snackbar.dart';
import 'package:android/handle_request.dart';
import 'package:android/store/data.dart';
import 'package:android/utils/struct.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CustomUpdater {
  static final UserDataStore data = UserDataStore();
  static RequestHandler requestHandler = RequestHandler();

  static Future<Map<String, dynamic>> forceUpdate({required State state, required String deviceID, bool isForce=false}) async {
    DefaultConfig defaultConfig = CustomUpdater.data.userData.value.copyWith();
    try {
      Map<String, dynamic> body = {'id': defaultConfig.user['id'], 'deviceID': deviceID, 'isForce': isForce};

      Map<String, dynamic> updateRes =
          await CustomUpdater.requestHandler.handleRequest('user/check-update', body: body);

      if (updateRes['success'] == true) {
        final data = updateRes['data'];
        List<Plant> plantList = defaultConfig.plants;
        List<FolderRecord> folderList = defaultConfig.folders;
        if (data['plants'] != null) {
          plantList = (data['plants'] as List).map<Plant>((p) => Plant.fromJson(p)).toList();
        }
        if (data['folders'] != null) {
          folderList =
              (data['folders'] as List).map((item) => FolderRecord.fromJson(Map<String, dynamic>.from(item))).toList();
        }
        Models newModel = Models(
          yoloobjectdetection: data['yoloObjectDetection'] ?? defaultConfig.models.yoloobjectdetection,
          yolostageclassification: data['yoloStageClassification'] ?? defaultConfig.models.yolostageclassification,
          maskrcnnsegmentation: data['maskRCNNSegmentation'] ?? defaultConfig.models.maskrcnnsegmentation,
        );
        defaultConfig = DefaultConfig(
          user: data['user'] ?? defaultConfig.user,
          models: newModel,
          plants: plantList,
          notifications: data['notification'] ?? defaultConfig.notifications,
          tailscaleDevices: data['tailscaleDevices'] ?? defaultConfig.tailscaleDevices,
          folders: folderList,
        );
        if (state.mounted) {
          AppSnackBar.hide(state.context, id: "login");
          AppSnackBar.success(state.context, 'Login successful and updated.');
        }
      } else {
        if (state.mounted) {
          AppSnackBar.hide(state.context, id: "login");
          AppSnackBar.info(state.context, 'Login successful (no updates).');
        }
      }
      return {
        'success': true,
        'data': defaultConfig,
      };
    } catch (err) {
      if (kDebugMode) {
        print('Error in checkCustomUpdate: $err');
      }
      return {'success': false, 'data': defaultConfig};
    }
  }

  static Future<Map<String, dynamic>> checkCustomUpdate({
    required State state,
    required String deviceID,
    bool willUpdateUser = false,
    bool willUpdateModels = false,
    bool willUpdatePlants = false,
    bool willUpdateNotifications = false,
    bool willUpdateTailscale = false,
    bool willUpdateFolders = false,
  }) async {
    DefaultConfig defaultConfig = CustomUpdater.data.userData.value.copyWith();

    try {
      Map<String, dynamic> body = {
        'id': defaultConfig.user['id'],
        'deviceID': deviceID,
        'willUpdateUser': willUpdateUser,
        'willUpdateModels': willUpdateModels,
        'willUpdatePlants': willUpdatePlants,
        'willUpdateNotifications': willUpdateNotifications,
        'willUpdateTailscale': willUpdateTailscale,
        'willUpdateFolders': willUpdateFolders,
      };

      Map<String, dynamic> updateRes =
          await CustomUpdater.requestHandler.handleRequest('user/check-custom-update', body: body);

      if (updateRes['success'] == true) {
        final data = updateRes['data'];

        List<Plant> plantList = defaultConfig.plants;
        if (willUpdatePlants && data['plants'] != null) {
          plantList = (data['plants'] as List).map<Plant>((p) => Plant.fromJson(Map<String, dynamic>.from(p))).toList();
        }

        List<FolderRecord> folderList = defaultConfig.folders;
        if (willUpdateFolders && data['folders'] != null) {
          folderList = (data['folders'] as List)
              .map<FolderRecord>((item) => FolderRecord.fromJson(Map<String, dynamic>.from(item)))
              .toList();
        }

        Models newModel = defaultConfig.models;
        if (willUpdateModels) {
          newModel = Models(
            yoloobjectdetection: data['yoloObjectDetection'] ?? defaultConfig.models.yoloobjectdetection,
            yolostageclassification: data['yoloStageClassification'] ?? defaultConfig.models.yolostageclassification,
            maskrcnnsegmentation: data['maskRCNNSegmentation'] ?? defaultConfig.models.maskrcnnsegmentation,
          );
        }

        defaultConfig = DefaultConfig(
          user: willUpdateUser && data['user'] != null ? data['user'] : defaultConfig.user,
          models: newModel,
          plants: plantList,
          notifications: willUpdateNotifications && data['notification'] != null
              ? data['notification']
              : defaultConfig.notifications,
          tailscaleDevices: willUpdateTailscale && data['tailscaleDevices'] != null
              ? data['tailscaleDevices']
              : defaultConfig.tailscaleDevices,
          folders: folderList,
        );

        if (state.mounted) {
          AppSnackBar.hide(state.context, id: "update");
          AppSnackBar.success(state.context, 'Custom update applied successfully.');
        }
      } else {
        if (state.mounted) {
          AppSnackBar.hide(state.context, id: "update");
          AppSnackBar.info(state.context, 'No custom updates available.');
        }
      }

      return {'success': true, 'data': defaultConfig};
    } catch (err) {
      if (kDebugMode) {
        print('Error in checkCustomUpdate: $err');
      }
      return {'success': false, 'data': defaultConfig};
    }
  }

}
