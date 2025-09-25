/// Config.dart
/// Configuration store manager for handling plant detection, spraying,
/// and scheduling settings in Flutter.
/// Provides methods to apply, revert, save, and export configuration states.
///
/// @author      AGRIBOT Team
/// @created     2025-09-21
/// @lastUpdated 2025-09-21
///
/// @note This module integrates with ValueNotifiers and maintains a baseline
///       (initial) config that can be restored if changes need to be reverted.
import 'dart:convert';
import 'package:android/utils/struct.dart';
import 'package:flutter/foundation.dart';

class Config {
  ValueNotifier<List<DetectedPlant>> detectedPlants;
  ValueNotifier<Spray> sprays;
  ValueNotifier<Schedule> schedule;

  ValueNotifier<String> objectDetectionVersion;
  ValueNotifier<String> stageClassificationVersion;
  ValueNotifier<String> diseaseSegmentationVersion;

  ValueNotifier<double> objectDetectionConfidence;
  ValueNotifier<double> stageClassificationConfidence;
  ValueNotifier<double> diseaseSegmentationConfidence;

  late ConfigType _initialConfig;

  Config(ConfigType defaultConfig)
      : detectedPlants = ValueNotifier(defaultConfig.detectedPlants),
        sprays = ValueNotifier(defaultConfig.sprays),
        schedule = ValueNotifier(defaultConfig.schedule),
        objectDetectionVersion = ValueNotifier(defaultConfig.objectDetection),
        stageClassificationVersion = ValueNotifier(defaultConfig.stageClassification),
        diseaseSegmentationVersion = ValueNotifier(defaultConfig.diseaseSegmentation),
        objectDetectionConfidence = ValueNotifier(defaultConfig.objectDetectionConfidence),
        stageClassificationConfidence = ValueNotifier(defaultConfig.stageClassificationConfidence),
        diseaseSegmentationConfidence = ValueNotifier(defaultConfig.diseaseSegmentationConfidence) {
    _initialConfig = defaultConfig;
  }

  void applyConfig(ConfigType config) {
    detectedPlants.value = config.detectedPlants;
    sprays.value = config.sprays;
    schedule.value = config.schedule;

    objectDetectionVersion.value = config.objectDetection;
    stageClassificationVersion.value = config.stageClassification;
    diseaseSegmentationVersion.value = config.diseaseSegmentation;

    objectDetectionConfidence.value = config.objectDetectionConfidence;
    stageClassificationConfidence.value = config.stageClassificationConfidence;
    diseaseSegmentationConfidence.value = config.diseaseSegmentationConfidence;
  }

  void revertConfig() {
    applyConfig(_initialConfig);
  }

  void saveConfig() {
    _initialConfig = getCurrentConfig();
  }

  ConfigType getCurrentConfig() {
    return ConfigType(
      detectedPlants: detectedPlants.value,
      sprays: sprays.value,
      schedule: schedule.value,
      objectDetection: objectDetectionVersion.value,
      stageClassification: stageClassificationVersion.value,
      diseaseSegmentation: diseaseSegmentationVersion.value,
      objectDetectionConfidence: objectDetectionConfidence.value,
      stageClassificationConfidence: stageClassificationConfidence.value,
      diseaseSegmentationConfidence: diseaseSegmentationConfidence.value,
    );
  } 

  bool isDirty() {
    final current = jsonEncode(getCurrentConfig().toJson());
    final baseline = jsonEncode(_initialConfig.toJson());
    return current != baseline;
  }

  String exportConfigJson() {
    return jsonEncode(getCurrentConfig().toJson());
  }

  @override
  String toString() {
    final config = getCurrentConfig();
    return '''
Config(
  detectedPlants: ${config.detectedPlants.map((p) => p.toJson()).toList()},
  sprays: ${config.sprays.toJson()},
  schedule: ${config.schedule.toJson()},
  objectDetectionVersion: ${config.objectDetection},
  stageClassificationVersion: ${config.stageClassification},
  diseaseSegmentationVersion: ${config.diseaseSegmentation},
  objectDetectionConfidence: ${config.objectDetectionConfidence},
  stageClassificationConfidence: ${config.stageClassificationConfidence},
  diseaseSegmentationConfidence: ${config.diseaseSegmentationConfidence}
)
''';
  }

}

