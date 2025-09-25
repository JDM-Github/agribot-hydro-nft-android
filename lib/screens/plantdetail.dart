import 'package:android/classes/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:android/utils/colors.dart';
import 'package:android/utils/struct.dart';

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
        title: Text(widget.plant.name),
        backgroundColor: AppColors.themedColor(context, AppColors.white, AppColors.gray900),
        actions: [
          Row(
            children: [
              const Text("Spray Early", style: TextStyle(fontSize: 12)),
              Switch(
                value: willSprayEarly,
                onChanged: (v) => setState(() => willSprayEarly = v),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 200,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: NetworkImage(widget.plant.image),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Text(widget.plant.description, style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 16),
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
                            child: Image.network(disease.image, height: 120, width: double.infinity, fit: BoxFit.cover),
                          ),
                          const SizedBox(height: 8),
                          Text(disease.description, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                        ],

                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          children: disease.sprays.map((spray) {
                            return Chip(
                              label: Text("💧 $spray"),
                              backgroundColor: AppColors.themedColor(context, Colors.blue[50]!, AppColors.gray800),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Text("Spray Time:"),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                initialValue: sprayTimes[disease.name]![0],
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                onChanged: (val) => sprayTimes[disease.name]![0] = val,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text("to"),
                            ),
                            Expanded(
                              child: TextFormField(
                                initialValue: sprayTimes[disease.name]![1],
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                onChanged: (val) => sprayTimes[disease.name]![1] = val,
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
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600]),
                  onPressed: () {
                    setState(() {
                      disabled = true;
                    });
                    updatePlant();
                    AppSnackBar.success(context, "Successfully disabled ${widget.plant.name}.");
                    Navigator.pop(context);
                  },
                  child: const Text("Disable",
                    style: TextStyle(color: AppColors.white)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red[900]),
                  onPressed: () {
                    widget.onRemove(widget.detectedPlant.key);
                    AppSnackBar.success(context, "Successfully removed ${widget.plant.name}.");
                    Navigator.pop(context, null);
                  },
                  child: const Text("Remove", style: TextStyle(color: AppColors.white)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
                  onPressed: () {
                    updatePlant();
                    AppSnackBar.success(context, "Successfully update the ${widget.plant.name}.");
                    Navigator.pop(context);
                  },
                  child: const Text("Save & Close", style: TextStyle(color: AppColors.white)),
                ),
              ],
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
}
