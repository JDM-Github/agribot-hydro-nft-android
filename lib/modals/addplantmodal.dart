import 'package:android/utils/struct.dart';
import 'package:flutter/material.dart';
import '../utils/colors.dart';

class AddPlantModal extends StatefulWidget {
  final bool show;
  final VoidCallback onClose;
  final List<Plant> allPlants;
  final Map<String, Plant> allPlantsTransformed;
  final List<DetectedPlant> detectedPlants;
  final Function(List<DetectedPlant>) onUpdate;

  const AddPlantModal({
    super.key,
    required this.show,
    required this.onClose,
    required this.allPlants,
    required this.allPlantsTransformed,
    required this.detectedPlants,
    required this.onUpdate,
  });

  @override
  State<AddPlantModal> createState() => _AddPlantModalState();
}

class _AddPlantModalState extends State<AddPlantModal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
  late final Animation<double> _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  late final Animation<double> _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);

  @override
  void initState() {
    super.initState();
    if (widget.show) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AddPlantModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.show ? _controller.forward(from: 0) : _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void addPlant(String key) {
    final plant = widget.allPlantsTransformed[key];
    if (plant == null) return;

    final newEntry = DetectedPlant(
      key: key,
      image: plant.image,
      timestamp: DateTime.now().toIso8601String(),
      disease: {
        for (var disease in plant.diseases) disease.name: List.filled(4, false),
      },
      diseaseTimeSpray: {
        for (var disease in plant.diseases) disease.name: ['03:00', '22:00'],
      },
    );

    final updated = [...widget.detectedPlants, newEntry];
    widget.onUpdate(updated);
  }

  void removePlant(String key) {
    final updated = widget.detectedPlants.where((p) => p.key != key).toList();
    widget.onUpdate(updated);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show && _controller.status == AnimationStatus.dismissed) {
      return const SizedBox.shrink();
    }

    final bgColor = AppColors.themedColor(context, AppColors.white, AppColors.gray900);
    final borderColor = AppColors.themedColor(context, AppColors.gray300, AppColors.gray700);
    final textColor = AppColors.themedColor(context, AppColors.textLight, AppColors.textDark);

    return FadeTransition(
      opacity: _opacity,
      child: Stack(
        children: [
          GestureDetector(
            onTap: widget.onClose,
            child: Container(
              color: Colors.black.withAlpha(200),
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          Center(
            child: ScaleTransition(
              scale: _scale,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Add Plant',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: textColor),
                          onPressed: widget.onClose,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Scrollable plant list
                    Expanded(
                      child: ListView.builder(
                        itemCount: widget.allPlants.length,
                        itemBuilder: (context, index) {
                          final plant = widget.allPlants[index];
                          final alreadyDetected = widget.detectedPlants.any((p) => p.key == plant.name);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(color: borderColor),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    plant.image,
                                    height: 60,
                                    width: 60,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    plant.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: textColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: alreadyDetected ? Colors.red : AppColors.green500,
                                  ),
                                  onPressed: () {
                                    alreadyDetected ? removePlant(plant.name) : addPlant(plant.name);
                                  },
                                  child: Text(
                                    alreadyDetected ? 'Remove' : 'Add',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 10),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: widget.onClose,
                        child: const Text('Close'),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
