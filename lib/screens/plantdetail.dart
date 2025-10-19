import 'package:android/classes/snackbar.dart';
import 'package:android/utils/dialog_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:android/utils/colors.dart';
import 'package:android/utils/struct.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class PlantDetailScreen extends StatefulWidget {
  final Plant plant;
  final DetectedPlant detectedPlant;
  final void Function(DetectedPlant) onUpdate;
  final void Function(String) onRemove;

  const PlantDetailScreen({
    super.key,
    required this.plant,
    required this.detectedPlant,
    required this.onUpdate,
    required this.onRemove,
  });

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  bool willSprayEarly = false;
  bool disabled = false;
  int? expandedIndex;
  Map<String, List<bool>> slotBindings = {};
  Map<String, List<String>> sprayTimes = {};

  late DetectedPlant _tempDetectedPlant;
  late DetectedPlant detectedPlant;

  @override
  void initState() {
    super.initState();
    detectedPlant = widget.detectedPlant;
    _tempDetectedPlant = widget.detectedPlant.copy();
    willSprayEarly = _tempDetectedPlant.willSprayEarly;
    for (var d in widget.plant.diseases) {
      slotBindings[d.name] = _tempDetectedPlant.disease[d.name] ?? [false, false, false, false];
      sprayTimes[d.name] = _tempDetectedPlant.diseaseTimeSpray[d.name] ?? ["06:00", "18:00"];
    }
  }

  void updatePlant() {
    setState(() {
      detectedPlant = detectedPlant.create(willSprayEarly, slotBindings, sprayTimes, disabled);
    });
    widget.onUpdate(detectedPlant);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.themedColor(context, AppColors.gray200, AppColors.gray800),
      appBar: AppBar(
        title: Text(widget.plant.name, style: TextStyle(fontSize: 18),),
        backgroundColor: AppColors.themedColor(context, AppColors.white, AppColors.gray900),
        actions: [
          Row(
            children: [
              const Text("Spray Early", style: TextStyle(fontSize: 12)),
              Switch(
                value: willSprayEarly,
                onChanged: (v) => setState(() => willSprayEarly = v),
                activeColor: AppColors.green500,
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: AnimatedSlide(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        offset: Offset(0, 0),
        child: SpeedDial(
            icon: Icons.add,
            activeIcon: Icons.close,
            backgroundColor: Colors.green,
            spacing: 10,
            spaceBetweenChildren: 8,
            overlayColor: AppColors.gray900,
            animationDuration: const Duration(milliseconds: 300),
            children: [
              SpeedDialChild(
                child: Icon(Icons.disabled_visible, color: Colors.red[600]),
                label: 'Disable Plant',
                backgroundColor: AppColors.themedColor(context, AppColors.gray100, AppColors.gray800),
                labelBackgroundColor: AppColors.themedColor(context, AppColors.gray200, AppColors.gray700),
                onTap: () {
                  setState(() {
                    disabled = true;
                  });
                  updatePlant();
                  AppSnackBar.success(context, "Successfully disabled ${widget.plant.name}.");
                  Navigator.pop(context);
                },
              ),
              SpeedDialChild(
                child: Icon(Icons.remove, color: AppColors.red500),
                label: 'Remove Plant',
                backgroundColor: AppColors.themedColor(context, AppColors.gray100, AppColors.gray800),
                labelBackgroundColor: AppColors.themedColor(context, AppColors.gray200, AppColors.gray700),
                onTap: () {
                  widget.onRemove(widget.detectedPlant.key);
                  AppSnackBar.success(context, "Successfully removed ${widget.plant.name}.");
                  Navigator.pop(context, null);
                },
              ),
              SpeedDialChild(
                child: Icon(Icons.save, color: AppColors.themedColor(context, AppColors.green500, AppColors.green700)),
                label: 'Save & Close',
                backgroundColor: AppColors.themedColor(context, AppColors.gray100, AppColors.gray800),
                labelBackgroundColor: AppColors.themedColor(context, AppColors.gray200, AppColors.gray700),
                onTap: () {
                  updatePlant();
                  AppSnackBar.success(context, "Successfully update the ${widget.plant.name}.");
                  Navigator.pop(context);
                },
              ),
            ]
          ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 200,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                image: DecorationImage(
                  image: CachedNetworkImageProvider(widget.plant.image),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.plant.description, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Column(
                    children: widget.plant.diseases.asMap().entries.map((entry) {
                      final index = entry.key;
                      final disease = entry.value;
                      final isExpanded = expandedIndex == index;

                      return Card(
                        color: AppColors.themedColor(context, Colors.grey[100]!, AppColors.gray700),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(disease.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                                    onPressed: () {
                                      setState(() {
                                        expandedIndex = isExpanded ? null : index;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              if (isExpanded) ...[
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    height: 120,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                        color: AppColors.themedColor(context, AppColors.gray300, AppColors.gray600)),
                                    child: CachedNetworkImage(
                                      imageUrl: disease.image,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                                      errorWidget: (context, url, error) => Icon(Icons.error),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                              Text(disease.description, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                children: disease.sprays.map((spray) {
                                  return Chip(
                                    label: Text("💧 $spray"),
                                    backgroundColor:
                                        AppColors.themedColor(context, Colors.blue[50]!, AppColors.gray800),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 10),
                              const Text("Spray Time:"),
                              const SizedBox(width: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () async {
                                        TimeOfDay initialTime = TimeOfDay.now();
                                        final currentValue = sprayTimes[disease.name]![0];
                                        final parsed = _parseTime(currentValue);
                                        if (parsed != null) {
                                          initialTime = TimeOfDay(hour: parsed.hour, minute: parsed.minute);
                                        }

                                        final TimeOfDay? picked = await showThemedTimePicker(
                                          context: context,
                                          initialTime: initialTime,
                                        );

                                        if (picked != null) {
                                          int hour = picked.hour;
                                          int minute = picked.minute;

                                          if (hour < 3) {
                                            hour = 3;
                                            minute = 0;
                                          }
                                          if (hour > 22 || (hour == 22 && minute > 0)) {
                                            hour = 22;
                                            minute = 0;
                                          }

                                          final formatted =
                                              '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

                                          final uptoTime = _parseTime(sprayTimes[disease.name]![1]);
                                          if (uptoTime != null) {
                                            final pickedDateTime = DateTime(0, 1, 1, hour, minute);
                                            if (pickedDateTime.isAfter(uptoTime)) {
                                              sprayTimes[disease.name]![0] = sprayTimes[disease.name]![1];
                                            } else {
                                              sprayTimes[disease.name]![0] = formatted;
                                            }
                                          } else {
                                            sprayTimes[disease.name]![0] = formatted;
                                          }

                                          setState(() {});
                                        }
                                      },
                                      child: AbsorbPointer(
                                        child: TextFormField(
                                          controller: TextEditingController(text: sprayTimes[disease.name]![0]),
                                          decoration: InputDecoration(
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                            prefixIcon: const Icon(Icons.access_time, size: 20),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10),
                                              borderSide: BorderSide(
                                                  color: AppColors.themedColor(
                                                      context, AppColors.gray200, AppColors.gray700)),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10),
                                              borderSide: const BorderSide(color: AppColors.green500),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                    child: Text("to"),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () async {
                                        TimeOfDay initialTime = TimeOfDay.now();
                                        final currentValue = sprayTimes[disease.name]![1];
                                        final parsed = _parseTime(currentValue);
                                        if (parsed != null) {
                                          initialTime = TimeOfDay(hour: parsed.hour, minute: parsed.minute);
                                        }

                                        final TimeOfDay? picked = await showThemedTimePicker(
                                          context: context,
                                          initialTime: initialTime,
                                        );

                                        if (picked != null) {
                                          int hour = picked.hour;
                                          int minute = picked.minute;

                                          if (hour < 3) {
                                            hour = 3;
                                            minute = 0;
                                          }
                                          if (hour > 22 || (hour == 22 && minute > 0)) {
                                            hour = 22;
                                            minute = 0;
                                          }

                                          final formatted =
                                              '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

                                          final fromTime = _parseTime(sprayTimes[disease.name]![0]);
                                          if (fromTime != null) {
                                            final pickedDateTime = DateTime(0, 1, 1, hour, minute);
                                            if (pickedDateTime.isBefore(fromTime)) {
                                              sprayTimes[disease.name]![1] = sprayTimes[disease.name]![0];
                                            } else {
                                              sprayTimes[disease.name]![1] = formatted;
                                            }
                                          } else {
                                            sprayTimes[disease.name]![1] = formatted;
                                          }

                                          setState(() {});
                                        }
                                      },
                                      child: AbsorbPointer(
                                        child: TextFormField(
                                          controller: TextEditingController(text: sprayTimes[disease.name]![1]),
                                          decoration: InputDecoration(
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                            prefixIcon: const Icon(Icons.access_time, size: 20),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10),
                                              borderSide: BorderSide(
                                                  color: AppColors.themedColor(
                                                      context, AppColors.gray200, AppColors.gray700)),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10),
                                              borderSide: const BorderSide(color: AppColors.green500),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _buildSlotButton("None", disease.name, reset: true),
                                  for (int i = 0; i < 4; i++)
                                    _buildSlotButton("Bind to Slot ${i + 1}", disease.name, index: i),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotButton(String text, String diseaseName, {int? index, bool reset = false}) {
    final slots = slotBindings[diseaseName]!;
    final isSelected = reset ? !slots.contains(true) : (index != null && slots[index]);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (reset) {
            slotBindings[diseaseName] = [false, false, false, false];
          } else if (index != null) {
            slots[index] = !slots[index];
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? ((text == "None") ? Colors.red : Colors.green) : AppColors.gray300,
          borderRadius: BorderRadius.circular(8),
        ),
        child:
            Text(text, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  DateTime? _parseTime(String input) {
    try {
      final parts = input.split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour != null && minute != null) {
          return DateTime(0, 1, 1, hour, minute);
        }
      }
    } catch (_) {}
    return null;
  }
}
