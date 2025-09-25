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
import 'package:android/screens/plantdetail.dart';
import 'package:android/store/data.dart';
import 'package:android/utils/colors.dart';
import 'package:android/utils/struct.dart';
import 'package:flutter/material.dart';

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ActionAccordion extends StatefulWidget {
  final ValueNotifier<bool> showSprayModal;
  final ValueNotifier<bool> showScheduleModal;
  final ValueNotifier<bool> showAddPlantModal;
  final ValueNotifier<bool> compareModal;
  final Config config;
  final Function() onExportConfig;
  final Function() onUploadConfig;
  final Function() saveConfig;
  final Function(String target) onOpenConfidence;
  final Function(String target) onOpenVersion;

  const ActionAccordion(
      {super.key,
      required this.showSprayModal,
      required this.showScheduleModal,
      required this.showAddPlantModal,
      required this.compareModal,
      required this.config,
      required this.onExportConfig,
      required this.onUploadConfig,
      required this.onOpenConfidence,
      required this.onOpenVersion,
      required this.saveConfig});

  @override
  State<ActionAccordion> createState() => _ActionAccordionState();
}

class _ActionAccordionState extends State<ActionAccordion> with SingleTickerProviderStateMixin {
  String? openSection;
  final Map<String, GlobalKey> _buttonKeys = {};
  OverlayEntry? _overlayEntry;

  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
  late final Animation<double> _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  late final Animation<double> _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    super.dispose();
  }

  void _removeOverlay({bool animated = true}) {
    if (_overlayEntry != null) {
      if (animated) {
        _controller.reverse().then((_) {
          _overlayEntry?.remove();
          _overlayEntry = null;
          openSection = null;
        });
      } else {
        _overlayEntry?.remove();
        _overlayEntry = null;
        openSection = null;
      }
    } else {
      openSection = null;
    }
  }

  void _showOverlay(Widget content, GlobalKey key) {
    _removeOverlay(animated: false);

    if (key.currentContext == null) return;
    final box = key.currentContext!.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;

        return Material(
          color: Colors.black26,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => _removeOverlay(),
                  behavior: HitTestBehavior.translucent,
                  child: const SizedBox.expand(),
                ),
              ),
              Positioned(
                top: offset.dy - 10 - 80,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) => Opacity(
                      opacity: _opacity.value,
                      child: Transform.scale(
                        scale: _scale.value,
                        child: child,
                      ),
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: screenWidth * 0.9,
                        maxHeight: 180,
                      ),
                      child: Material(
                        elevation: 6,
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.themedColor(context, AppColors.gray100, AppColors.gray900),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: AbsorbPointer(
                            absorbing: false,
                            child: content,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final sections = [
      {
        'title': 'Model Actions',
        'content': Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _mediumButton(context, 'Compare Models', backgroundColor: AppColors.blue500, onPressed: () {
              _removeOverlay(animated: false);
              widget.compareModal.value = true;
            }),
            _mediumButton(context, 'ObjectDetectionModel', backgroundColor: AppColors.orange500, onPressed: () {
              _removeOverlay(animated: false);
              widget.onOpenVersion("obj");
            }),
            _mediumButton(context, 'ClassificationModel', backgroundColor: AppColors.purple500, onPressed: () {
              _removeOverlay(animated: false);
              widget.onOpenVersion("cls");
            }),
            _mediumButton(context, 'SegmentationModel', backgroundColor: AppColors.teal500, onPressed: () {
              _removeOverlay(animated: false);
              widget.onOpenVersion("seg");
            }),
          ],
        ),
      },
      {
        'title': 'Model Confidence',
        'content': Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _mediumButton(context, 'Object Detection Model (${widget.config.objectDetectionConfidence.value})',
                backgroundColor: AppColors.orange500, onPressed: () {
              _removeOverlay(animated: false);
              widget.onOpenConfidence("obj");
            }),
            _mediumButton(context, 'Classification Model (${widget.config.stageClassificationConfidence.value})',
                backgroundColor: AppColors.purple500, onPressed: () {
              _removeOverlay(animated: false);
              widget.onOpenConfidence("cls");
            }),
            _mediumButton(context, 'Segmentation Model (${widget.config.diseaseSegmentationConfidence.value})',
                backgroundColor: AppColors.teal500, onPressed: () {
              _removeOverlay(animated: false);
              widget.onOpenConfidence("seg");
            }),
          ],
        ),
      },
      {
        'title': 'Configuration Actions',
        'content': Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _mediumButton(context, 'Save Configuration', backgroundColor: AppColors.green700, onPressed: () {
              _removeOverlay(animated: false);
              widget.saveConfig();
            }),
            _mediumButton(context, 'Download Configuration', backgroundColor: AppColors.yellow500, onPressed: () {
              _removeOverlay(animated: false);
              widget.onExportConfig();
            }),
            _mediumButton(context, 'Upload Configuration', backgroundColor: AppColors.red500, onPressed: () {
              _removeOverlay(animated: false);
              widget.onUploadConfig();
            }),
          ],
        ),
      },
      {
        'title': 'Setup Actions',
        'content': Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _mediumButton(context, 'Setup Spray', backgroundColor: AppColors.blue700, onPressed: () {
              setState(() {
                _removeOverlay(animated: true);
                widget.showSprayModal.value = true;
              });
            }),
            _mediumButton(context, 'Set Schedule', backgroundColor: AppColors.orange700, onPressed: () {
              setState(() {
                _removeOverlay(animated: false);
                widget.showScheduleModal.value = true;
              });
            }),
            _mediumButton(context, 'Add Plant', backgroundColor: AppColors.purple700, onPressed: () {
              setState(() {
                _removeOverlay(animated: false);
                widget.showAddPlantModal.value = true;
              });
            }),
          ],
        ),
      },
    ];

    return SizedBox(
      height: 50,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: sections.map((section) {
            final keyName = section['title'] as String;
            _buttonKeys.putIfAbsent(keyName, () => GlobalKey());

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: GestureDetector(
                onTap: () {
                  if (openSection == keyName) {
                    _removeOverlay();
                  } else {
                    setState(() => openSection = keyName);
                    _showOverlay(section['content'] as Widget, _buttonKeys[keyName]!);
                  }
                },
                child: _accordionButton(
                  key: _buttonKeys[keyName],
                  context: context,
                  title: keyName,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _accordionButton({
    Key? key,
    required BuildContext context,
    required String title,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.themedColor(context, AppColors.gray200, AppColors.gray800),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.themedColor(context, AppColors.gray300, AppColors.gray700),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.themedColor(context, AppColors.textLight, AppColors.textDark),
        ),
      ),
    );
  }

  Widget _mediumButton(
    BuildContext context,
    String label, {
    VoidCallback? onPressed,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    final bgColor = backgroundColor ?? AppColors.green500;
    final fgColor = foregroundColor ?? AppColors.white;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        minimumSize: const Size(0, 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label),
    );
  }
}

class PlantListSection extends StatefulWidget {
  final dynamic user;
  final Function(dynamic newUser) updateUser;

  final Map<String, dynamic> models;
  final List<Plant> allPlants;
  final Map<String, Plant> transformedPlants;
  const PlantListSection(
      {super.key,
      required this.user,
      required this.updateUser,
      required this.models,
      required this.allPlants,
      required this.transformedPlants});

  @override
  State<PlantListSection> createState() => _PlantListSectionState();
}

class _PlantListSectionState extends State<PlantListSection> {
  ValueNotifier<bool> showSprayModal = ValueNotifier<bool>(false);
  ValueNotifier<bool> showScheduleModal = ValueNotifier<bool>(false);
  ValueNotifier<bool> showAddPlantModal = ValueNotifier<bool>(false);
  ValueNotifier<bool> showConfidenceModal = ValueNotifier<bool>(false);
  ValueNotifier<bool> showModalVersion = ValueNotifier<bool>(false);
  ValueNotifier<bool> compareModal = ValueNotifier<bool>(false);
  String confidenceTitle = "";
  String confidenceModalShownTarget = "";
  double initialValueConfidence = 0.0;

  // VERSION
  String versionTitle = "";
  String initialValueVersion = "";
  String versionModalShownTarget = "";
  List<dynamic> allCurrentVersion = [];

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
        allCurrentVersion = widget.models['yoloObjectDetection'];
        initialValueVersion = config.objectDetectionVersion.value;
        
      } else if (target == "cls") {
        versionTitle = "YOLOv8 Classification Versions";
        allCurrentVersion = widget.models['yoloStageClassification'];
        initialValueVersion = config.stageClassificationVersion.value;
      } else {
        versionTitle = "Mask R-CNN Segmentation Versions";
        allCurrentVersion = widget.models['maskRCNNSegmentation'];
        initialValueVersion = config.diseaseSegmentationVersion.value;
      }
    });
  }

  late ConfigType configType;
  late Config config;

  @override
  void initState() {
    super.initState();
    final userConfig = widget.user['config'];
    if (userConfig == null || (userConfig is Map && userConfig.isEmpty)) {
      configType = ConfigType.defaultConfigType();
    } else {
      configType = ConfigType.fromJson(userConfig);
    }
    config = Config(configType);
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Save Configuration?"),
        content: const Text("This will overwrite your current settings."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Confirm")),
        ],
      ),
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
          "email": widget.user['email'],
          "config": currentConfig,
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
                  return ListView.builder(
                    itemCount: detectedPlants.length,
                    itemBuilder: (context, index) {
                      final plant = detectedPlants[index];
                      final isDisabled = plant.disabled;

                      return Card(
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
                            backgroundImage: NetworkImage(plant.image),
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
                                  final newPlant = widget.transformedPlants[plant.key];
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
                      );
                    },
                  );
                },
              ),
            ),
            ActionAccordion(
                showSprayModal: showSprayModal,
                showScheduleModal: showScheduleModal,
                showAddPlantModal: showAddPlantModal,
                compareModal: compareModal,
                config: config,
                onExportConfig: () {
                  exportOrShareConfig(this, config);
                },
                onUploadConfig: () {
                  uploadConfig(this, config);
                },
                saveConfig: () {
                  saveConfig(this);
                },
                onOpenConfidence: changeTarget,
                onOpenVersion: chooseModalChange),
          ],
        ),
        ValueListenableBuilder<bool>(
            valueListenable: showConfidenceModal,
            builder: (context, value, child) {
              return value
                  ? ConfidenceModal(
                      show: true,
                      title: confidenceTitle,
                      onClose: () => showConfidenceModal.value = false,
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
                      onClose: () => showModalVersion.value = false,
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
                          onClose: () => compareModal.value = false,
                          models: widget.models,
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
                          onClose: () => showSprayModal.value = false,
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
                          onClose: () => showScheduleModal.value = false,
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
                        onClose: () => showAddPlantModal.value = false,
                        allPlants: widget.allPlants,
                        allPlantsTransformed: widget.transformedPlants,
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
