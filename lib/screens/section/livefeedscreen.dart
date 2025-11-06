import 'dart:convert';
import 'dart:typed_data';
import 'package:android/classes/snackbar.dart';
import 'package:android/connection/all_states.dart';
import 'package:android/connection/connect.dart';
import 'package:android/handle_request.dart';
import 'package:android/store/data.dart';
import 'package:android/utils/colors.dart';
import 'package:android/utils/enums.dart';
import 'package:android/utils/struct.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class LiveFeedScreen extends StatelessWidget {
  LiveFeedScreen({super.key});

  final List<Map<String, String>> fakeDetections = [
    {"plant": "Tomato Plant", "disease": "Late Blight"},
    {"plant": "Cucumber Plant", "disease": "Powdery Mildew"},
    {"plant": "Strawberry Plant", "disease": "Bacterial Spot"},
  ];

  static Future<void> captureImageAndDisplay(BuildContext context) async {
    final state = AllStates.allState.value;

    final isConnected = state["conn"] as bool;
    final robotState = state["robot"] as int;
    final scannerState = state["scan"] as bool;
    final robotScanState = state["rscan"] as bool;
    final performing = state["performing"] as bool;
    final stopCapture = state["stopCapture"] as bool;
    final robotLive = state["robotLive"] as bool;
    final liveState = state["live"] as int;

    if (!isConnected) {
      AppSnackBar.error(context, "You are currently not connected to AGRIBOT.");
      return;
    }
    if (robotState != 0) {
      AppSnackBar.error(context, "AGRIBOT Robot is currently running.");
      return;
    }
    if (scannerState) {
      AppSnackBar.error(context, "Scanner is currently running.");
      return;
    }
    if (robotScanState) {
      AppSnackBar.error(context, "AGRIBOT Robot scanner is currently scanning.");
      return;
    }
    if (liveState == 0) {
      AppSnackBar.error(context, "Cannot capture image when livestreaming is stopped.");
      return;
    }
    if (performing) {
      AppSnackBar.error(context, "Cannot capture image while performing a scan.");
      return;
    }
    if (stopCapture) {
      AppSnackBar.error(context, "Cannot capture image while another capture is in progress.");
      return;
    }
    if (robotLive) {
      AppSnackBar.error(context, "Cannot capture image while robot is live.");
      return;
    }

    UserDataStore data = UserDataStore();
    final userEmail = data.user.value['email'];
    if (userEmail.isEmpty) {
      AppSnackBar.error(context, "User email not found.");
      return;
    }

    AppSnackBar.loading(context, "Capturing image...", id: "capture-image");

    try {
      final folderName = userEmail.split('@').first;
      final handler = RequestHandler();

      final [success, data] = await handler.authFetch(
        "capture_and_return_blob?folder=$folderName",
        method: "POST",
      );

      AppSnackBar.hide(context, id: "capture-image");

      if (!success) {
        AppSnackBar.error(context, "Failed to capture image!");
        return;
      }

      final length = data['length'] ?? 0;
      AppSnackBar.success(context, "$length plant(s) detected!");
    } catch (e) {
      AppSnackBar.hide(context, id: "capture-image");
      AppSnackBar.error(context, "Failed to capture image: $e");
    }
  }

  static Future<void> controlLivestream(State newState, LiveStreamAction action) async {
    final state = AllStates.allState.value;

    final isConnected = state["conn"] as bool;
    final robotState = state["robot"] as int;
    final scannerState = state["scan"] as bool;
    final robotScanState = state["rscan"] as bool;
    final performing = state["performing"] as bool;
    final stopCapture = state["stopCapture"] as bool;
    final robotLive = state["robotLive"] as bool;
    final liveState = state["live"] as int;

    if (!isConnected) {
      AppSnackBar.error(newState.context, "You are currently not connected to AGRIBOT.");
      return;
    }
    if (robotState != 0) {
      AppSnackBar.error(newState.context, "AGRIBOT Robot is currently running.");
      return;
    }
    if (scannerState) {
      AppSnackBar.error(newState.context, "Scanner is currently running.");
      return;
    }
    if (robotScanState) {
      AppSnackBar.error(newState.context, "AGRIBOT Robot scanner is currently scanning.");
      return;
    }
    if (performing) {
      AppSnackBar.error(newState.context, "Cannot perform action while scanning.");
      return;
    }
    if (stopCapture) {
      AppSnackBar.error(newState.context, "Cannot perform action while capturing image.");
      return;
    }
    if (robotLive) {
      AppSnackBar.error(newState.context, "Cannot perform action when robot is live.");
      return;
    }
    if (liveState == 0 && action == LiveStreamAction.pause) {
      AppSnackBar.error(newState.context, "Livestream cannot paused when it's not running.");
      return;
    }

    final stateText = {
      LiveStreamAction.run: 'already running',
      LiveStreamAction.stop: 'already stopped',
      LiveStreamAction.pause: 'already paused'
    }[action];

    final isAlready = (liveState == 1 && action == LiveStreamAction.run) ||
        (liveState == 0 && action == LiveStreamAction.stop) ||
        (liveState == 2 && action == LiveStreamAction.pause);

    if (isAlready) {
      AppSnackBar.error(newState.context, "Livestream is $stateText.");
      return;
    }

    final actionLabel = {
      LiveStreamAction.run: "Starting robot livestream",
      LiveStreamAction.stop: "Stopping robot livestream",
      LiveStreamAction.pause: "Pausing robot livestream"
    }[action];

    AppSnackBar.loading(newState.context, "$actionLabel", id: "control-robot");
    try {
      final handler = RequestHandler();

      final response = await handler.authFetch(
        action.name.toLowerCase(),
        method: 'POST',
      );

      if (newState.mounted) {
        AppSnackBar.hide(newState.context, id: "control-robot");
      }
      if (response[0] == true) {
        if (newState.mounted) {
          AppSnackBar.success(
              newState.context,
              "Robot livestream ${action == LiveStreamAction.run ? 'started' : action == LiveStreamAction.pause ? 'stopped' : 'paused'} successfully.");
        }
      } else {
        if (newState.mounted) {
          AppSnackBar.error(newState.context, "Failed to ${action.name.toLowerCase()} robot livestream.");
        }
      }
    } catch (e) {
      if (newState.mounted) {
        AppSnackBar.hide(newState.context, id: "control-robot");
        AppSnackBar.error(newState.context, "Network error: $e");
      }
    }
  }

  static Future<void> uploadImage(State newState) async {
    final state = AllStates.allState.value;

    final isConnected = state["conn"] as bool;
    final robotState = state["robot"] as int;
    final scannerState = state["scan"] as bool;
    final robotScanState = state["rscan"] as bool;
    final performing = state["performing"] as bool;
    final stopCapture = state["stopCapture"] as bool;
    final robotLive = state["robotLive"] as bool;
    final liveState = state["live"] as int;

    if (!isConnected) {
      AppSnackBar.error(newState.context, "You are currently not connected to AGRIBOT.");
      return;
    }
    if (robotState != 0) {
      AppSnackBar.error(newState.context, "AGRIBOT Robot is currently running.");
      return;
    }
    if (scannerState) {
      AppSnackBar.error(newState.context, "Scanner is currently running.");
      return;
    }
    if (robotScanState) {
      AppSnackBar.error(newState.context, "AGRIBOT Robot scanner is currently scanning.");
      return;
    }
    if (liveState != 0) {
      AppSnackBar.error(newState.context, "Cannot upload when livestreaming.");
      return;
    }
    if (performing) {
      AppSnackBar.error(newState.context, "Cannot upload when performing a scan.");
      return;
    }
    if (stopCapture) {
      AppSnackBar.error(newState.context, "Cannot upload when capturing image.");
      return;
    }
    if (robotLive) {
      AppSnackBar.error(newState.context, "Cannot upload when robot is live.");
      return;
    }

    UserDataStore data = UserDataStore();
    final email = data.user.value['email'] ?? '';
    if (email.isEmpty) {
      AppSnackBar.error(newState.context, "User email not found.");
      return;
    }

    if (newState.mounted) {
      AppSnackBar.loading(newState.context, "Uploading image...", id: "upload-image");
    }

    try {
      final picker = ImagePicker();
      final XFile? selectedFile = await picker.pickImage(source: ImageSource.gallery);
      
      if (selectedFile != null) {
        final bytes = await selectedFile.readAsBytes();
        final folderName = email.split('@').first;

        final handler = RequestHandler();
        final [success, data] = await handler.authFetch(
          "upload-image",
          method: "POST",
          body: {
            "file": bytes,
            "fileName": selectedFile.name,
            "folder": folderName,
          },
          isMultipart: true,
        );
        if (newState.mounted) {
          AppSnackBar.hide(newState.context, id: "upload-image");
        }
        if (!success) {
          if (newState.mounted) {
            AppSnackBar.error(newState.context, "Failed to upload image!");
          }
          return;
        }
        final length = data['length'] ?? 0;
        if (newState.mounted) {
          AppSnackBar.success(newState.context, "$length plant(s) detected!");
        }
      } else if (newState.mounted) {
        AppSnackBar.hide(newState.context, id: "upload-image");
        AppSnackBar.error(newState.context, "No image selected.");
      }
    } catch (e) {
      if (newState.mounted) {
        AppSnackBar.hide(newState.context, id: "upload-image");
        AppSnackBar.error(newState.context, "Upload failed: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>>(
      valueListenable: AllStates.allState,
      builder: (context, state, _) {

        if (!state["conn"]) {
          return _NotConnected();
        } else if (state["robot"] != 0) {
          return _StopRobot(whatRunning: "robot");
        } else if (state["scan"]) {
          return _StopRobot(whatRunning: "scanner");
        } else if (state["rscan"]) {
          return _StopRobot(whatRunning: "robot scanner");
        } else if (state["robotLive"]) {
          return _StopRobot(whatRunning: "robot live");
        }

        return Stack(
          children: [
            Column(
              children: [
                Expanded(
                  flex: 2,
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        color: AppColors.themedColor(context, AppColors.gray200, AppColors.gray950),
                        alignment: Alignment.center,
                        child: ValueListenableBuilder<Uint8List?>(
                          valueListenable: Connection.liveFrame,
                          builder: (context, frame, _) {
                            if (frame == null || frame.isEmpty) {
                              return Text(
                                "CAMERA FEED",
                                style: TextStyle(
                                  color: AppColors.themedColor(context, AppColors.gray900, AppColors.gray50),
                                  fontSize: 18,
                                ),
                              );
                            }
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                frame,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                gaplessPlayback: true,
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: GestureDetector(
                          onTap: () async => await captureImageAndDisplay(context),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              color: AppColors.green500,
                              size: 28,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.themedColor(context, AppColors.gray50, AppColors.gray700),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "DETECTION HISTORY",
                          style: TextStyle(
                            color: AppColors.themedColor(context, AppColors.gray900, AppColors.gray50),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Divider(color: AppColors.themedColor(context, AppColors.gray300, AppColors.gray500)),
                        Expanded(
                          child: ValueListenableBuilder<PlantHistories>(
                            valueListenable: Connection.plantHistories,
                            builder: (context, histories, _) {
                              print(histories);
                              if (histories.isEmpty) {
                                return Center(
                                  child: Text(
                                    "No records",
                                    style: TextStyle(
                                      color: AppColors.themedColor(context, AppColors.gray500, AppColors.gray400),
                                      fontSize: 14,
                                    ),
                                  ),
                                );
                              }
                              return ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: histories.length,
                                itemBuilder: (context, index) {
                                  final detection = histories[index];
                                  return _detectionCard(context, detection);
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _detectionCard(BuildContext context, PlantHistory history) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.themedColor(context, AppColors.gray100, AppColors.gray800),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.themedColor(context, AppColors.gray300, AppColors.gray700),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: history.src != null && history.src.toString().isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Scaffold(
                              backgroundColor: Colors.black,
                              body: Stack(
                                children: [
                                  Center(
                                    child: InteractiveViewer(
                                      panEnabled: true,
                                      minScale: 0.8,
                                      maxScale: 5.0,
                                      child: Image.memory(
                                        base64Decode(history.src.toString().split(',').last),
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) => const Icon(
                                          Icons.broken_image,
                                          color: Colors.white54,
                                          size: 80,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 40,
                                    left: 10,
                                    child: IconButton(
                                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      child: Hero(
                        tag: "imageHero",
                        child: Image.memory(
                          base64Decode(history.src.toString().split(',').last),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 150,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.broken_image,
                            color: AppColors.themedColor(context, AppColors.gray600, AppColors.gray400),
                          ),
                        ),
                      ),
                    ),
                  )
                : Text(
                    "No Image",
                    style: TextStyle(
                      color: AppColors.themedColor(
                        context,
                        AppColors.gray700,
                        AppColors.gray400,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            history.plantName?.toString() ?? "Unknown Plant",
            style: TextStyle(
              color: AppColors.themedColor(context, AppColors.gray900, AppColors.gray50),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            history.plantHealth?.toString() ?? "Unknown",
            style: TextStyle(
              color: AppColors.red500,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _NotConnected extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.themedColor(context, AppColors.gray200, AppColors.gray800),
      alignment: Alignment.center,
      child: Text(
        "You are not connected",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _StopRobot extends StatelessWidget {
  final String whatRunning;
  const _StopRobot({required this.whatRunning});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.themedColor(context, AppColors.gray200, AppColors.gray800),
      alignment: Alignment.center,
      child: Text(
        "Cannot start livestream: $whatRunning running",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
