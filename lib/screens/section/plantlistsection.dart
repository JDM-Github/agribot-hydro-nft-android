import 'package:android/screens/plantdetail.dart';
import 'package:android/utils/colors.dart';
import 'package:flutter/material.dart';

class PlantListSection extends StatelessWidget {
  final List<Map<String, dynamic>> filteredPlants;

  const PlantListSection({super.key, required this.filteredPlants});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            itemCount: filteredPlants.length,
            itemBuilder: (context, index) {
              var plant = filteredPlants[index];
              return Card(
                color: AppColors.themedColor(context, AppColors.white, AppColors.gray800),
                margin: EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(plant['imageUrl']),
                  ),
                  title: Text("${plant['name']}"),
                  subtitle: Text(
                    plant['description'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("Confidence: ${plant['confidence']}%"),
                          Text(
                            plant['timestamp'],
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlantDetailScreen(),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 20, right: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.themedColor(context, AppColors.gray100, AppColors.gray800),
                        foregroundColor: AppColors.themedColor(context, Colors.black, Colors.white),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text("SETUP SPRAY"),
                    ),
                  ),
                  SizedBox(width: 100),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.themedColor(context, AppColors.gray100, AppColors.gray800),
                        foregroundColor: AppColors.themedColor(context, Colors.black, Colors.white),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text("SELECT MODEL"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
