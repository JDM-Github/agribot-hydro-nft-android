import 'package:android/utils/struct.dart';

class Models {
  List<dynamic> yoloobjectdetection;
  List<dynamic> yolostageclassification;
  List<dynamic> maskrcnnsegmentation;

  Models({
    this.yoloobjectdetection = const [],
    this.yolostageclassification = const [],
    this.maskrcnnsegmentation = const [],
  });

  factory Models.fromJson(Map<String, dynamic> json) {
    return Models(
      yoloobjectdetection: json['yoloObjectDetection'] ?? [],
      yolostageclassification: json['yoloStageClassification'] ?? [],
      maskrcnnsegmentation: json['maskRCNNSegmentation'] ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'yoloObjectDetection': yoloobjectdetection,
      'yoloStageClassification': yolostageclassification,
      'maskRCNNSegmentation': maskrcnnsegmentation,
    };
  }

  Models copyWith() {
    return Models(
      yoloobjectdetection: List.from(yoloobjectdetection),
      yolostageclassification: List.from(yolostageclassification),
      maskrcnnsegmentation: List.from(maskrcnnsegmentation),
    );
  }
}

class DefaultConfig {
  Map<String, dynamic> user;
  Models models;
  List<Plant> plants;
  List<dynamic> notifications;
  List<dynamic> tailscaleDevices;
  List<FolderRecord> folders;

  DefaultConfig({
    this.user = const {},
    Models? models,
    this.plants = const [],
    this.notifications = const [],
    this.tailscaleDevices = const [],
    this.folders = const [],
  }) : models = models ?? Models();

  factory DefaultConfig.fromJson(Map<String, dynamic> json) {
    List<Plant> plantList = [];
    List<FolderRecord> folderList = [];
    if (json['plants'] != null) {
      plantList = (json['plants'] as List).map<Plant>((p) => Plant.fromJson(p)).toList();
    }
    if (json['folders'] != null) {
      folderList = (json['folders'] as List).map((item) => FolderRecord.fromJson(Map<String, dynamic>.from(item))).toList();
    }
    return DefaultConfig(
      user: json['user'] ?? {},
      models: json['models'] != null ? Models.fromJson(json['models']) : Models(),
      plants: plantList,
      notifications: json['notifications'] ?? [],
      tailscaleDevices: json['tailscaleDevices'] ?? [],
      folders: folderList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user,
      'models': models.toJson(),
      'plants': plants.map((p) => p.toJson()).toList(),
      'notifications': notifications,
      'tailscaleDevices': tailscaleDevices,
      'folders': folders.map((f) => f.toJson()).toList(),
    };
  }

  DefaultConfig copyWith({
    Map<String, dynamic>? user,
    Models? models,
    List<Plant>? plants,
    List<dynamic>? notifications,
    List<dynamic>? tailscaleDevices,
    List<FolderRecord>? folders,
  }) {
    return DefaultConfig(
      user: user ?? Map.from(this.user),
      models: models ?? this.models.copyWith(),
      plants: plants ?? this.plants.map((plant) => plant.copyWith()).toList(),
      notifications: notifications ?? List.from(this.notifications),
      tailscaleDevices: tailscaleDevices ?? List.from(this.tailscaleDevices),
      folders: folders ?? this.folders.map((folder) => folder.copyWith()).toList(),
    );
  }
}
