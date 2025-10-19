class Schedule {
  String frequency;
  List<Map<String, String>> runs;
  List<String> days;

  Schedule({
    required this.frequency,
    required this.runs,
    required this.days,
  });

  Map<String, dynamic> toJson() => {
        "frequency": frequency,
        "runs": runs,
        "days": days,
      };

  factory Schedule.fromJson(Map<String, dynamic> json) => Schedule(
        frequency: json["frequency"],
        runs: List<Map<String, String>>.from(json["runs"].map((e) => Map<String, String>.from(e))),
        days: List<String>.from(json["days"]),
      );

  Schedule copy() {
    return Schedule(
      frequency: frequency,
      runs: runs.map((e) => Map<String, String>.from(e)).toList(),
      days: List<String>.from(days),
    );
  }

  bool sameAs(Schedule other) {
    return frequency == other.frequency &&
        days.length == other.days.length &&
        days.every((d) => other.days.contains(d)) &&
        runs.length == other.runs.length &&
        List.generate(runs.length, (i) {
          final a = runs[i], b = other.runs[i];
          return a['time'] == b['time'] && a['upto'] == b['upto'];
        }).every((v) => v);
  }
}

class Spray {
  List<String> spray;
  List<bool> active;
  List<int> duration;

  Spray({
    required this.spray,
    required this.active,
    required this.duration,
  });

  Map<String, dynamic> toJson() => {
        "spray": spray,
        "active": active,
        "duration": duration,
      };

  factory Spray.fromJson(Map<String, dynamic> json) => Spray(
        spray: List<String>.from(json["spray"]),
        active: List<bool>.from(json["active"]),
        duration: List<int>.from(json["duration"]),
      );
    
  Spray copy() {
    return Spray(
      spray: List<String>.from(spray),
      active: List<bool>.from(active),
      duration: List<int>.from(duration),
    );
  }
}

class ConfigType {
  List<DetectedPlant> detectedPlants;
  Spray sprays;
  Schedule schedule;

  String objectDetection;
  String stageClassification;
  String diseaseSegmentation;

  double objectDetectionConfidence;
  double stageClassificationConfidence;
  double diseaseSegmentationConfidence;

  ConfigType({
    required this.detectedPlants,
    required this.sprays,
    required this.schedule,
    required this.objectDetection,
    required this.stageClassification,
    required this.diseaseSegmentation,
    required this.objectDetectionConfidence,
    required this.stageClassificationConfidence,
    required this.diseaseSegmentationConfidence,
  });

  Map<String, dynamic> toJson() => {
        "detectedPlants": detectedPlants.map((e) => e.toJson()).toList(),
        "sprays": sprays.toJson(),
        "schedule": schedule.toJson(),
        "objectDetection": objectDetection,
        "stageClassification": stageClassification,
        "diseaseSegmentation": diseaseSegmentation,
        "objectDetectionConfidence": objectDetectionConfidence,
        "stageClassificationConfidence": stageClassificationConfidence,
        "diseaseSegmentationConfidence": diseaseSegmentationConfidence,
      };

  factory ConfigType.fromJson(Map<String, dynamic> json) => ConfigType(
        detectedPlants: List<DetectedPlant>.from(json["detectedPlants"].map((e) => DetectedPlant.fromJson(e))),
        sprays: Spray.fromJson(json["sprays"]),
        schedule: Schedule.fromJson(json["schedule"]),
        objectDetection: json["objectDetection"],
        stageClassification: json["stageClassification"],
        diseaseSegmentation: json["diseaseSegmentation"],
        objectDetectionConfidence: (json["objectDetectionConfidence"] as num).toDouble(),
        stageClassificationConfidence: (json["stageClassificationConfidence"] as num).toDouble(),
        diseaseSegmentationConfidence: (json["diseaseSegmentationConfidence"] as num).toDouble(),
      );
  
  static ConfigType defaultConfigType() {
    return ConfigType(
      detectedPlants: [],
      sprays: Spray(
        spray: ['', '', '', ''],
        active: [true, true, true, true],
        duration: [2, 2, 2, 2],
      ),
      schedule: Schedule(
        frequency: "weekly",
        runs: [
          {"time": "06:00", "upto": "07:00"},
        ],
        days: [],
      ),
      objectDetection: "",
      stageClassification: "",
      diseaseSegmentation: "",
      objectDetectionConfidence: 0.3,
      stageClassificationConfidence: 0.3,
      diseaseSegmentationConfidence: 0.3,
    );
  }

}

class Disease {
  final String name;
  final String description;
  final String image;
  final List<String> sprays;

  Disease({
    required this.name,
    required this.description,
    required this.image,
    required this.sprays,
  });

  factory Disease.fromJson(Map<String, dynamic> json) {
    return Disease(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      image: json['image'] ?? '',
      sprays: List<String>.from(json['sprays'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'image': image,
        'sprays': sprays,
      };
}

class Plant {
  final String name;
  final String image;
  final String description;
  final List<Disease> diseases;

  Plant({
    required this.name,
    required this.image,
    required this.description,
    required this.diseases,
  });

  factory Plant.fromJson(Map<String, dynamic> json) {
    return Plant(
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      description: json['description'] ?? '',
      diseases: json['diseases'] != null
          ? List<Disease>.from(
              (json['diseases'] as List).map((d) => Disease.fromJson(d)),
            )
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'image': image,
        'description': description,
        'diseases': diseases.map((d) => d.toJson()).toList(),
      };

  Plant copyWith({
    String? name,
    String? image,
    String? description,
    List<Disease>? diseases,
  }) {
    return Plant(
      name: name ?? this.name,
      image: image ?? this.image,
      description: description ?? this.description,
      diseases: diseases ?? this.diseases,
    );
  }
}


class DetectedPlant {
  String key;
  String image;
  String timestamp;
  bool disabled;
  bool willSprayEarly;
  Map<String, List<bool>> disease;
  Map<String, List<String>> diseaseTimeSpray;

  DetectedPlant({
    required this.key,
    required this.image,
    required this.timestamp,
    this.disabled = false,
    this.willSprayEarly = false,
    required this.disease,
    required this.diseaseTimeSpray,
  });

    Map<String, dynamic> toJson() => {
        "key": key,
        "timestamp": timestamp,
        "disabled": disabled,
        "willSprayEarly": willSprayEarly,
        "image": image,
        "disease": disease,
        "disease_time_spray": diseaseTimeSpray,
      };

  factory DetectedPlant.fromJson(Map<String, dynamic> json) => DetectedPlant(
        key: json["key"],
        timestamp: json["timestamp"],
        disabled: json["disabled"],
        willSprayEarly: json["willSprayEarly"],
        image: json["image"],
        disease: Map<String, List<bool>>.from(
          json["disease"].map((k, v) => MapEntry(k, List<bool>.from(v))),
        ),
        diseaseTimeSpray: Map<String, List<String>>.from(
          json["disease_time_spray"].map((k, v) => MapEntry(k, List<String>.from(v))),
        ),
      );
  
  DetectedPlant copy() {
    return DetectedPlant(
      key: key,
      image: image,
      timestamp: timestamp,
      disabled: disabled,
      willSprayEarly: willSprayEarly,
      disease: disease.map((k, v) => MapEntry(k, List<bool>.from(v))),
      diseaseTimeSpray: diseaseTimeSpray.map((k, v) => MapEntry(k, List<String>.from(v))),
    );
  }

  DetectedPlant create(bool willSpray,
    Map<String, List<bool>> slotBindings,
    Map<String, List<String>> sprayTimes,
    bool dis)
  {
    return DetectedPlant(
      key: key,
      image: image,
      timestamp: timestamp,
      disabled: dis,
      willSprayEarly: willSpray,
      disease: slotBindings.map((k, v) => MapEntry(k, List<bool>.from(v))),
      diseaseTimeSpray: sprayTimes.map((k, v) => MapEntry(k, List<String>.from(v))),
    );
  }

  update(bool willSpray, Map<String, List<bool>> slotBindings, Map<String, List<String>> sprayTimes) {
    willSprayEarly = willSpray;
    disease = slotBindings;
    diseaseTimeSpray = sprayTimes;
  }

  DetectedPlant set({
    String? key,
    String? image,
    String? timestamp,
    bool? disabled,
    bool? willSprayEarly,
    Map<String, List<bool>>? disease,
    Map<String, List<String>>? diseaseTimeSpray,
  }) {
    return DetectedPlant(
      key: key ?? this.key,
      image: image ?? this.image,
      timestamp: timestamp ?? this.timestamp,
      disabled: disabled ?? this.disabled,
      willSprayEarly: willSprayEarly ?? this.willSprayEarly,
      disease: disease ?? this.disease.map((k, v) => MapEntry(k, List<bool>.from(v))),
      diseaseTimeSpray: diseaseTimeSpray ?? this.diseaseTimeSpray.map((k, v) => MapEntry(k, List<String>.from(v))),
    );
  }
}

class FolderRecord {
  final String slug;
  final String date;
  final String name;
  final String imageUrl;

  FolderRecord({
    required this.slug,
    required this.date,
    required this.name,
    required this.imageUrl,
  });

  factory FolderRecord.fromJson(Map<String, dynamic> json) {
    return FolderRecord(
      slug: json['slug'] ?? '',
      date: json['date'] ?? '',
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slug': slug,
      'date': date,
      'name': name,
      'imageUrl': imageUrl,
    };
  }

  FolderRecord copyWith({
    String? slug,
    String? date,
    String? name,
    String? imageUrl,
  }) {
    return FolderRecord(
      slug: slug ?? this.slug,
      date: date ?? this.date,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}



// final List<Plant> fakePlants = [
//   Plant(
//     name: "Tomato",
//     image: "https://picsum.photos/200?random=1",
//     description: "A common vegetable crop, rich in vitamins A and C.",
//     diseases: [
//       Disease(
//         name: "Early Blight",
//         description: "Fungal disease causing leaf spots and fruit rot.",
//         image: "https://picsum.photos/100?random=11",
//         sprays: ["Copper fungicide", "Neem oil"],
//       ),
//       Disease(
//         name: "Late Blight",
//         description: "Severe disease that rapidly kills leaves and stems.",
//         image: "https://picsum.photos/100?random=12",
//         sprays: ["Chlorothalonil", "Mancozeb"],
//       ),
//     ],
//   ),
//   Plant(
//     name: "Cucumber",
//     image: "https://picsum.photos/200?random=2",
//     description: "A vining plant producing long green fruits.",
//     diseases: [
//       Disease(
//         name: "Powdery Mildew",
//         description: "White powdery fungus covering leaves.",
//         image: "https://picsum.photos/100?random=21",
//         sprays: ["Sulfur spray", "Bicarbonate solution"],
//       ),
//     ],
//   ),
//   Plant(
//     name: "Lettuce",
//     image: "https://picsum.photos/200?random=3",
//     description: "A leafy vegetable grown for fresh salads.",
//     diseases: [
//       Disease(
//         name: "Downy Mildew",
//         description: "Yellow spots and fuzzy growth on leaf undersides.",
//         image: "https://picsum.photos/100?random=31",
//         sprays: ["Copper fungicide", "Phosphorous acid"],
//       ),
//       Disease(
//         name: "Tip Burn",
//         description: "Physiological disorder from calcium deficiency.",
//         image: "https://picsum.photos/100?random=32",
//         sprays: ["Calcium nitrate spray"],
//       ),
//     ],
//   ),
// ];

// final Map<String, Plant> transformedPlants = {
//   for (var plant in fakePlants) plant.name: plant,
// };

// final List<DetectedPlant> fakeDetectedPlants = [
//   DetectedPlant(
//     key: "Tomato",
//     image: fakePlants[0].image,
//     timestamp: DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
//     disabled: false,
//     willSprayEarly: false,
//     disease: {
//       "Early Blight": [true, false, false, false],
//       "Late Blight": [false, false, false, false],
//     },
//     diseaseTimeSpray: {
//       "Early Blight": ["06:00", "18:00"],
//       "Late Blight": ["07:00", "19:00"],
//     },
//   ),
//   DetectedPlant(
//     key: "Cucumber",
//     image: fakePlants[1].image,
//     timestamp: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
//     disabled: false,
//     willSprayEarly: true,
//     disease: {
//       "Powdery Mildew": [false, true, false, false],
//     },
//     diseaseTimeSpray: {
//       "Powdery Mildew": ["05:30", "17:30"],
//     },
//   ),
//   DetectedPlant(
//     key: "Lettuce",
//     image: fakePlants[2].image,
//     timestamp: DateTime.now().toIso8601String(),
//     disabled: true,
//     willSprayEarly: false,
//     disease: {
//       "Downy Mildew": [false, false, false, false],
//       "Tip Burn": [true, true, false, false],
//     },
//     diseaseTimeSpray: {
//       "Downy Mildew": ["04:00", "16:00"],
//       "Tip Burn": ["09:00", "21:00"],
//     },
//   ),
// ];

class PlantHistory {
  final int id;
  final dynamic src;
  final dynamic timestamp;
  final dynamic plantName;
  final dynamic plantHealth;
  final dynamic imageSize;
  final dynamic locationOnCapture;
  final dynamic generatedDescription;

  PlantHistory({
    required this.id,
    this.src,
    this.timestamp,
    this.plantName,
    this.plantHealth,
    this.imageSize,
    this.locationOnCapture,
    this.generatedDescription,
  });

  factory PlantHistory.fromJson(Map<String, dynamic> json) {
    return PlantHistory(
      id: json['id'] ?? 0,
      src: json['src'],
      timestamp: json['timestamp'],
      plantName: json['plantName'],
      plantHealth: json['plantHealth'],
      imageSize: json['imageSize'],
      locationOnCapture: json['locationOnCapture'],
      generatedDescription: json['generatedDescription'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'src': src,
        'timestamp': timestamp,
        'plantName': plantName,
        'plantHealth': plantHealth,
        'imageSize': imageSize,
        'locationOnCapture': locationOnCapture,
        'generatedDescription': generatedDescription,
      };
}

typedef PlantHistories = List<PlantHistory>;
