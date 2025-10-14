import 'dart:convert';
import 'package:android/classes/config.dart';
import 'package:android/classes/snackbar.dart';
import 'package:android/handle_request.dart';
import 'package:android/modals/addplantmodal.dart';
import 'package:android/modals/choosemodal.dart';
import 'package:android/modals/compare.dart';
import 'package:android/modals/confidence.dart';
import 'package:android/modals/setschedule.dart';
import 'package:android/modals/setupspray.dart';
import 'package:android/modals/show_confirmation_modal.dart';
import 'package:android/screens/plantdetail.dart';
import 'package:android/store/data.dart';
import 'package:android/utils/colors.dart';
import 'package:android/utils/struct.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PlantListSection extends StatefulWidget {
  final Set<void> Function() hide;
  const PlantListSection({
    super.key,
    required this.hide,
  });

  @override
  State<PlantListSection> createState() => PlantListSectionState();
}

class PlantListSectionState extends State<PlantListSection> with SingleTickerProviderStateMixin {
  ValueNotifier<bool> showSprayModal = ValueNotifier<bool>(false);
  ValueNotifier<bool> showScheduleModal = ValueNotifier<bool>(false);
  ValueNotifier<bool> showAddPlantModal = ValueNotifier<bool>(false);
  ValueNotifier<bool> showConfidenceModal = ValueNotifier<bool>(false);
  ValueNotifier<bool> showModalVersion = ValueNotifier<bool>(false);
  ValueNotifier<bool> compareModal = ValueNotifier<bool>(false);
  String confidenceTitle = "";
  String confidenceModalShownTarget = "";
  double initialValueConfidence = 0.0;

  String versionTitle = "";
  String initialValueVersion = "";
  String versionModalShownTarget = "";
  List<dynamic> allCurrentVersion = [];

  late final AnimationController _controller;
  late final List<Animation<Offset>> _animations;

  UserDataStore data = UserDataStore();
  void changeTarget(target) {
    setState(() {
      confidenceModalShownTarget = target;
      showConfidenceModal.value = true;

      if (target == "obj") {
        confidenceTitle = "YOLOv8 Object Detection Confidence";
        initialValueConfidence = config.objectDetectionConfidence.value;
      } else if (target == "cls") {
        confidenceTitle = "YOLOv8 Classification Confidence";
        initialValueConfidence = config.stageClassificationConfidence.value;
      } else {
        confidenceTitle = "Mask R-CNN Segmentation Confidence";
        initialValueConfidence = config.diseaseSegmentationConfidence.value;
      }
    });
  }

  void chooseModalChange(target) {
    setState(() {
      versionModalShownTarget = target;
      showModalVersion.value = true;
      if (target == "obj") {
        versionTitle = "YOLOv8 Object Detection Versions";
        allCurrentVersion = data.models.value.yoloobjectdetection;
        initialValueVersion = config.objectDetectionVersion.value;
      } else if (target == "cls") {
        versionTitle = "YOLOv8 Classification Versions";
        allCurrentVersion = data.models.value.yolostageclassification;
        initialValueVersion = config.stageClassificationVersion.value;
      } else {
        versionTitle = "Mask R-CNN Segmentation Versions";
        allCurrentVersion = data.models.value.maskrcnnsegmentation;
        initialValueVersion = config.diseaseSegmentationVersion.value;
      }
    });
  }

  late ConfigType configType;
  late Config config;

  @override
  void initState() {
    super.initState();
    final userConfig = data.user.value['config'];
    if (userConfig == null || (userConfig is Map && userConfig.isEmpty)) {
      configType = ConfigType.defaultConfigType();
    } else {
      configType = ConfigType.fromJson(userConfig);
    }
    config = Config(configType);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _animations = List.generate(config.detectedPlants.value.length, (index) {
      final start = index * 0.05;
      final end = start + 0.5;
      return Tween<Offset>(begin: const Offset(0, 0.6), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> uploadConfig(State state, Config config) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        if (state.mounted) {
          AppSnackBar.error(context, '❌ No file selected.');
        }
        return;
      }
      final fileBytes = result.files.first.bytes;
      final filePath = result.files.first.path;
      String jsonString;

      if (fileBytes != null) {
        jsonString = utf8.decode(fileBytes);
      } else if (filePath != null) {
        final file = File(filePath);
        jsonString = await file.readAsString();
      } else {
        if (state.mounted) {
          AppSnackBar.error(context, '❌ Cannot read the file.');
        }
        return;
      }
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      final newConfig = ConfigType.fromJson(jsonMap);
      config.applyConfig(newConfig);

      if (state.mounted) {
        AppSnackBar.success(context, '✅ Config uploaded successfully!');
      }
    } catch (e) {
      if (state.mounted) {
        AppSnackBar.error(context, '❌ Failed to upload config: $e');
      }
    }
  }

  Future<void> exportOrShareConfig(State state, Config config) async {
    final jsonString = config.exportConfigJson();

    if (Platform.isAndroid || Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      String? outputPath = await FilePicker.platform.getDirectoryPath();
      if (outputPath != null) {
        final file = File('$outputPath/config.json');
        await file.writeAsString(jsonString);

        if (state.mounted) {
          AppSnackBar.success(context, '✅ Config saved at: ${file.path}');
        }
      } else {
        if (state.mounted) {
          AppSnackBar.error(context, '❌ User canceled directory picking');
        }
      }
    } else if (Platform.isIOS) {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/config.json');
      await file.writeAsString(jsonString);

      final shareParams = ShareParams(
        text: 'Here is my config file',
        files: [XFile(file.path)],
      );

      final result = await SharePlus.instance.share(shareParams);

      if (state.mounted) {
        if (result.status == ShareResultStatus.success) {
          AppSnackBar.success(context, '✅ Config shared successfully!');
        } else {
          AppSnackBar.error(context, '❌ Sharing canceled or failed');
        }
      }
    } else {
      if (state.mounted) {
        AppSnackBar.error(context, 'Platform not supported for export');
      }
    }
  }

  Future<void> saveConfig(State state) async {
    final store = UserDataStore();

    final confirmed = await showConfirmationModal(
      context: context,
      title: "Save Configuration?",
      message: "This will overwrite your current settings.",
    );

    if (confirmed != true) return;
    final toastId = "saveConfig";
    if (state.mounted) {
      AppSnackBar.loading(context, "Updating configuration...", id: toastId);
    }

    try {
      final handler = RequestHandler();
      final currentConfig = config.getCurrentConfig().toJson();

      final response = await handler.handleRequest(
        'user/update-config',
        method: "POST",
        body: {
          "id": data.user.value['id'],
          "config": currentConfig,
          'deviceID': data.uuid.value
        },
      );
      if (state.mounted) {
        AppSnackBar.hide(context, id: toastId);
      }

      if (response['success'] == true) {
        await store.saveConfig(currentConfig);
        // final updateRobot = await handler.handleRequest(
        //   'update-config',
        //   method: "POST",
        //   body: {"config": currentConfig},
        // );

        // if (updateRobot['success'] != true) {
        //   if (state.mounted) {
        //     AppSnackBar.error(context, "Configuration saved to cloud, but robot not updated.");
        //   }
        // }
        if (state.mounted) {
          AppSnackBar.success(context, "Configuration saved successfully.");
        }
      } else {
        if (state.mounted) {
          AppSnackBar.error(context, response['message'] ?? "Updating configuration failed.");
        }
      }
    } catch (e) {
      if (state.mounted) {
        AppSnackBar.hide(context, id: toastId);
        AppSnackBar.error(context, "An unexpected error occurred.");
      }
      debugPrint("saveConfig error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            const SizedBox(height: 10),
            Expanded(
              child: ValueListenableBuilder<List<DetectedPlant>>(
                valueListenable: config.detectedPlants,
                builder: (context, detectedPlants, _) {
                  if (detectedPlants.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.eco, size: 60, color: AppColors.gray500),
                          const SizedBox(height: 12),
                          Text(
                            "No plants detected",
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.gray500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: detectedPlants.length,
                    itemBuilder: (context, index) {
                      final plant = detectedPlants[index];
                      final isDisabled = plant.disabled;

                      return AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _controller.value >= (index * 0.05) ? 1 : 0,
                              child: SlideTransition(
                                position: _animations[index],
                                child: child,
                              ),
                            );
                          },
                          child: Card(
                            color: isDisabled
                                ? AppColors.themedColor(
                                    context,
                                    AppColors.gray300,
                                    AppColors.gray900,
                                  )
                                : AppColors.themedColor(
                                    context,
                                    AppColors.white,
                                    AppColors.gray800,
                                  ),
                            margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: CachedNetworkImageProvider(plant.image),
                                foregroundColor: isDisabled ? Colors.grey : null,
                              ),
                              title: Text(
                                plant.key,
                                style: TextStyle(
                                  color: isDisabled ? Colors.grey : null,
                                  decoration: isDisabled ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              subtitle: Text(
                                "Detected at ${DateTime.parse(plant.timestamp).toLocal()}",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isDisabled ? Colors.grey : null,
                                ),
                              ),
                              trailing: isDisabled
                                  ? TextButton(
                                      onPressed: () {
                                        final list = List<DetectedPlant>.from(config.detectedPlants.value);
                                        list[index] = plant.set(disabled: false);
                                        config.detectedPlants.value = list;
                                        AppSnackBar.success(context, "Plant enabled again");
                                      },
                                      style: TextButton.styleFrom(
                                        backgroundColor: AppColors.green500,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                      ),
                                      child: const Text("Enable"),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              plant.timestamp.split("T").first,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            if (plant.willSprayEarly)
                                              const Text(
                                                "Spray Early",
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.redAccent,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                                      ],
                                    ),
                              onTap: isDisabled
                                  ? null
                                  : () {
                                      final newPlant = data.transformedPlants.value[plant.key];
                                      if (newPlant != null) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => PlantDetailScreen(
                                              plant: newPlant,
                                              detectedPlant: plant,
                                              onUpdate: (updatedPlant) {
                                                final list = List<DetectedPlant>.from(config.detectedPlants.value);
                                                final idx = list.indexWhere((p) => p.key == updatedPlant.key);
                                                if (idx != -1) {
                                                  list[idx] = updatedPlant;
                                                  config.detectedPlants.value = list;
                                                }
                                              },
                                              onRemove: (plantKey) {
                                                final list = List<DetectedPlant>.from(config.detectedPlants.value);
                                                list.removeWhere((p) => p.key == plantKey);
                                                config.detectedPlants.value = list;
                                              },
                                            ),
                                          ),
                                        );
                                      } else {
                                        AppSnackBar.info(context, "Plant details not found");
                                      }
                                    },
                            ),
                          ));
                    },
                  );
                },
              ),
            ),
          ],
        ),
        ValueListenableBuilder<bool>(
            valueListenable: showConfidenceModal,
            builder: (context, value, child) {
              return value
                  ? ConfidenceModal(
                      show: true,
                      title: confidenceTitle,
                      onClose: () {
                        widget.hide();
                        showConfidenceModal.value = false;
                      },
                      initialValue: initialValueConfidence,
                      onSave: (double value) {
                        final snappedValue = double.parse(value.toStringAsFixed(1));
                        if (confidenceModalShownTarget == "obj") {
                          config.objectDetectionConfidence.value = snappedValue;
                        } else if (confidenceModalShownTarget == "cls") {
                          config.stageClassificationConfidence.value = snappedValue;
                        } else {
                          config.diseaseSegmentationConfidence.value = snappedValue;
                        }
                        setState(() {});
                      },
                    )
                  : const SizedBox.shrink();
            }),
        ValueListenableBuilder<bool>(
            valueListenable: showModalVersion,
            builder: (context, value, child) {
              return value
                  ? ModelVersionModal(
                      show: true,
                      title: versionTitle,
                      onClose: () {
                        widget.hide();
                        showModalVersion.value = false;
                      },
                      initialVersion: initialValueVersion,
                      versions: allCurrentVersion,
                      onSave: (String selected) {
                        if (versionModalShownTarget == "obj") {
                          config.objectDetectionVersion.value = selected;
                        } else if (versionModalShownTarget == "cls") {
                          config.stageClassificationVersion.value = selected;
                        } else {
                          config.diseaseSegmentationVersion.value = selected;
                        }
                        setState(() {});
                      },
                    )
                  : const SizedBox.shrink();
            }),
        ValueListenableBuilder<bool>(
            valueListenable: compareModal,
            builder: (context, value, child) {
              return value
                  ? ValueListenableBuilder<Spray>(
                      valueListenable: config.sprays,
                      builder: (context, sprays, child) {
                        return CompareModelsModal(
                          show: true,
                          onClose: () {
                            widget.hide();
                            compareModal.value = false;
                          },
                          models: data.models.value,
                        );
                      },
                    )
                  : const SizedBox.shrink();
            }),
        ValueListenableBuilder<bool>(
            valueListenable: showSprayModal,
            builder: (context, value, child) {
              return value
                  ? ValueListenableBuilder<Spray>(
                      valueListenable: config.sprays,
                      builder: (context, sprays, child) {
                        return SetupSprayModal(
                          show: true,
                          onClose: () {
                            widget.hide();
                            showSprayModal.value = false;
                          },
                          sprays: sprays,
                        );
                      },
                    )
                  : const SizedBox.shrink();
            }),
        ValueListenableBuilder<bool>(
            valueListenable: showScheduleModal,
            builder: (context, value, child) {
              return value
                  ? ValueListenableBuilder<Schedule>(
                      valueListenable: config.schedule,
                      builder: (context, schedule, child) {
                        return SetScheduleModal(
                          show: true,
                          onClose: () {
                            widget.hide();
                            showScheduleModal.value = false;
                          },
                          schedule: schedule,
                        );
                      },
                    )
                  : const SizedBox.shrink();
            }),
        ValueListenableBuilder<bool>(
          valueListenable: showAddPlantModal,
          builder: (context, value, child) {
            return value
                ? ValueListenableBuilder<List<DetectedPlant>>(
                    valueListenable: config.detectedPlants,
                    builder: (context, detected, _) {
                      return AddPlantModal(
                        show: value,
                        onClose: () {
                          widget.hide();
                          showAddPlantModal.value = false;
                        },
                        allPlants: data.allPlants.value,
                        allPlantsTransformed: data.transformedPlants.value,
                        detectedPlants: detected,
                        onUpdate: (List<DetectedPlant> updated) {
                          config.detectedPlants.value = updated;
                        },
                      );
                    },
                  )
                : const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}
