import 'package:android/utils/colors.dart';
import 'package:flutter/material.dart';

class PlantDetailScreen extends StatefulWidget {
  const PlantDetailScreen({super.key});

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  final Map<String, dynamic> plant = {
    'image': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSJKRPXQYgZjJmuQTgXVQNLoZRxRWe7aW09wg&s',
    'name': 'Tomato Plant',
    'description': 'A healthy tomato plant known for its vibrant fruits and moderate care requirements.',
    'diseases': [
      {
        'name': 'Late Blight',
        'description': 'A fungal disease causing dark spots on leaves and fruits.',
        'image': 'https://placehold.co/600x400.png',
        'sprays': ['Copper Fungicide', 'Neem Oil'],
        'severity': 'High'
      },
      {
        'name': 'Powdery Mildew',
        'description': 'A white, powdery fungus that covers leaves, reducing photosynthesis.',
        'image': 'https://placehold.co/600x400.png',
        'sprays': ['Sulfur Spray', 'Neem Oil'],
        'severity': 'Moderate'
      },
      {
        'name': 'Bacterial Spot',
        'description': 'Small, water-soaked lesions on leaves that grow into dark, necrotic spots.',
        'image': 'https://placehold.co/600x400.png',
        'sprays': ['Copper Fungicide'],
        'severity': 'Low'
      }
    ]
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.gray800 : AppColors.gray200,
      appBar: AppBar(
        title: Text(plant['name']),
        backgroundColor: AppColors.themedColor(context, AppColors.white, AppColors.gray900),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(plant['image']),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant['name'],
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    plant['description'],
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 12),
                  Column(
                    children: plant['diseases'].map<Widget>((disease) {
                      return _buildDiseaseCard(disease);
                    }).toList(),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {},
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.white),
                            SizedBox(width: 6),
                            Text("Delete Record"),
                          ],
                        ),
                      ),
                      SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[800] 
                              : Colors.grey[300],
                          foregroundColor: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black, 
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Row(
                          children: [
                            Icon(Icons.close, size: 18, color: Colors.white),
                            SizedBox(width: 6),
                            Text("Close"),
                          ],
                        ),
                      ),
                    ],
                  )

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiseaseCard(Map<String, dynamic> disease) {
    return Card(
      color: Theme.of(context).brightness == Brightness.dark ? AppColors.gray700 : Colors.grey[200],
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              disease['name'],
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),

            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  image: NetworkImage(disease['image']),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 8),

            Text(
              disease['description'],
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            SizedBox(height: 8),

            Wrap(
              spacing: 8,
              children: disease['sprays'].map<Widget>((spray) {
                return Chip(
                  label: Text(spray),
                  avatar: Icon(Icons.water_drop, color: Colors.blue, size: 18),
                  backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.gray800 : Colors.blue[50],
                );
              }).toList(),
            ),
            SizedBox(height: 12),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildBindButton("None", isSelected: true),
                  SizedBox(width: 8),
                  for (int i = 1; i <= 4; i++) ...[
                    _buildBindButton("Bind to Empty $i"),
                    SizedBox(width: 8),
                  ]
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBindButton(String text, {bool isSelected = false}) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red : Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
