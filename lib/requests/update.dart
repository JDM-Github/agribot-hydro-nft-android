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

  static Future<Map<String, dynamic>> forceUpdate({required State state, required String deviceID}) async {
    DefaultConfig defaultConfig = CustomUpdater.data.userData.value.copyWith();
    try {
      Map<String, dynamic> body = {'id': defaultConfig.user['id'], 'deviceID': deviceID, 'isForce': false};

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
          user: defaultConfig.user,
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
    required Map<String, dynamic> userData,
    required String deviceID,
    bool willUpdateUser = false,
    bool willUpdateModels = false,
    bool willUpdatePlants = false,
    bool willUpdateNotifications = false,
    bool willUpdateTailscale = false,
    bool willUpdateFolders = false,
  }) async {
    try {
      Map<String, dynamic> updatedData = {
        'user': userData['user'] ?? {},
        'models': userData['models'] ??
            {'yoloobjectdetection': [], 'yolostageclassification': [], 'maskrcnnsegmentation': []},
        'plants': userData['plants'] ?? [],
        'notifications': userData['notifications'] ?? [],
        'tailscale_devices': userData['tailscale_devices'] ?? [],
        'folders': userData['folders'] ?? [],
      };

      Map<String, dynamic> body = {
        'id': updatedData['user']['id'],
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

        if (willUpdateUser && data['user'] != null) {
          updatedData['user'] = data['user'];
        }
        if (willUpdateModels) {
          updatedData['models'] = {
            'yoloobjectdetection': data['yoloObjectDetection'] ?? updatedData['models']['yoloobjectdetection'],
            'yolostageclassification':
                data['yoloStageClassification'] ?? updatedData['models']['yolostageclassification'],
            'maskrcnnsegmentation': data['maskRCNNSegmentation'] ?? updatedData['models']['maskrcnnsegmentation'],
          };
        }
        if (willUpdatePlants && data['plants'] != null) {
          updatedData['plants'] = data['plants'];
        }
        if (willUpdateNotifications && data['notification'] != null) {
          updatedData['notifications'] = data['notification'];
        }
        if (willUpdateTailscale && data['tailscaleDevices'] != null) {
          updatedData['tailscale_devices'] = data['tailscaleDevices'];
        }
        if (willUpdateFolders && data['folders'] != null) {
          updatedData['folders'] = data['folders'];
        }
      }

      return {'success': true, 'data': updatedData};
    } catch (err) {
      if (kDebugMode) {
        print('Error in checkCustomUpdate: $err');
      }
      return {'success': false, 'message': 'Internal server error.'};
    }
  }
}
