import 'package:android/classes/default.dart';
import 'package:android/classes/snackbar.dart';
import 'package:android/handle_request.dart';
import 'package:android/store/data.dart';
import 'package:android/utils/struct.dart';
import 'package:flutter/material.dart';

class AuthService {
  final UserDataStore data = UserDataStore();
  final RequestHandler handler;

  AuthService({bool development = false}) : handler = RequestHandler();

  Future<Map<String, dynamic>> login(
    State state,
    Map<String, dynamic> body,
  ) async {
    if (state.mounted) {
      AppSnackBar.loading(state.context, "Trying to login...", id: "login");
    }
    
    try {
      DefaultConfig defaultConfig = data.userData.value.copyWith();
      final result = await handler.handleRequest(
        'user/login',
        method: 'POST',
        body: {
          ...body,
        },
      );

      if (result['success'] != true) {
        if (state.mounted) {
          AppSnackBar.hide(state.context, id: "login");
          AppSnackBar.error(state.context, result['message'] ?? 'Login failed.');
        }
        return {
          'success': false,
          'message': result['message'] ?? 'Login failed.',
        };
      }

      defaultConfig.user = result['user'];
      Map<String, dynamic> saveLogin = {'success': false};
      try {
        saveLogin = await handler.handleRequest(
          'user/save-login-device',
          method: 'POST',
          body: {
            'userId': result['user']['id'],
            'deviceID': body['deviceID'],
          },
        );
      } catch (err) {
        if (state.mounted) {
          AppSnackBar.hide(state.context, id: "login");
          AppSnackBar.warning(state.context, 'Error saving login device: $err');
        }
      }

      if (saveLogin['success'] == true) {
        try {
          final updateRes = await handler.handleRequest(
            'user/check-update',
            method: 'POST',
            body: {
              'id': result['user']['id'],
              'deviceID': body['deviceID'],
            },
          );

          if (updateRes['success'] == true) {
            final data = updateRes['data'];

            List<Plant> plantList = defaultConfig.plants;
            List<FolderRecord> folderList = defaultConfig.folders;
            if (data['plants'] != null) {
              plantList = (data['plants'] as List).map<Plant>((p) => Plant.fromJson(p)).toList();
            }
            if (data['folders'] != null) {
              folderList = (data['folders'] as List)
                  .map((item) => FolderRecord.fromJson(Map<String, dynamic>.from(item)))
                  .toList();
            }
            defaultConfig = DefaultConfig(
              user: defaultConfig.user,
              models: Models.fromJson(data),
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
        } catch (err) {
          if (state.mounted) {
            AppSnackBar.hide(state.context, id: "login");
            AppSnackBar.warning(state.context, 'Error fetching updates: $err');
          }
        }
      } else {
         AppSnackBar.hide(state.context, id: "login");
      }
      return {
        'success': true,
        'data': defaultConfig,
      };
    } catch (err) {
      if (state.mounted) {
        AppSnackBar.hide(state.context, id: "login");
        AppSnackBar.error(state.context, 'Unexpected error: $err');
      }
      return {
        'success': false,
        'message': 'Internal error during login.',
      };
    }
  }
}
