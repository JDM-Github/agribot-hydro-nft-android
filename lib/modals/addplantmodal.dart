import 'package:android/utils/struct.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  late final Animation<double> _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 1),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

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

    final bgColor = AppColors.themedColor(context, AppColors.gray200, AppColors.gray800);
    final textColor = AppColors.themedColor(context, AppColors.textLight, AppColors.textDark);

    return FadeTransition(
      opacity: _opacity,
      child: Stack(
        children: [
          GestureDetector(
            onTap: widget.onClose,
            child: Container(color: Colors.black.withAlpha(150), width: double.infinity, height: double.infinity),
          ),
          SlideTransition(
            position: _slide,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Material(
                color: bgColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                elevation: 16,
                child: Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.75,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Add Plant',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                          IconButton(
                            icon: Icon(Icons.close, color: textColor),
                            onPressed: widget.onClose,
                            splashRadius: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Expanded(
                        child: Scrollbar(
                          thumbVisibility: true,
                          child: ListView.builder(
                            itemCount: widget.allPlants.length,
                            itemBuilder: (context, index) {
                              final plant = widget.allPlants[index];
                              final alreadyDetected = widget.detectedPlants.any((p) => p.key == plant.name);

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                color: AppColors.themedColor(context, AppColors.gray50, AppColors.gray700),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: SizedBox(
                                          height: 50,
                                          width: 50,
                                          child: CachedNetworkImage(
                                            imageUrl: plant.image,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                                            errorWidget: (context, url, error) => Icon(Icons.error),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          plant.name,
                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor),
                                        ),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: alreadyDetected ? Colors.red : AppColors.green500,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        onPressed: () {
                                          alreadyDetected ? removePlant(plant.name) : addPlant(plant.name);
                                        },
                                        child: Text(
                                          alreadyDetected ? 'Remove' : 'Add',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Cancel button
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: widget.onClose,
                          style: TextButton.styleFrom(
                            backgroundColor: AppColors.red500,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Cancel', style: TextStyle(fontSize: 14)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
