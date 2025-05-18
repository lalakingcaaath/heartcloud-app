import 'package:flutter/material.dart';
import 'package:heartcloud/utils/colors.dart';

class PlacementGuide extends StatelessWidget {
  const PlacementGuide({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.only(left: 40, right: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 70),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Icon(
                      Icons.arrow_back,
                      size: 35,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Text(
                    "Placement Guide",
                    style: TextStyle(
                      color: darkBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 25,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Front Placement Card
              PlacementCard(
                label: 'Front',
                imagePath: 'images/FRONT.png',
                description: 'Place the stethoscope on the front chest.',
              ),

              const SizedBox(height: 20),

              // Back Placement Card
              PlacementCard(
                label: 'Back',
                imagePath: 'images/BACK.png',
                description: 'Place the stethoscope on the back chest.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlacementCard extends StatelessWidget {
  final String label;
  final String imagePath;
  final String description;

  const PlacementCard({
    required this.label,
    required this.imagePath,
    required this.description,
    super.key,
  });

  void _showZoomedImage(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (context) {
        return GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: InteractiveViewer(
              child: Hero(
                tag: imagePath,
                child: Container(
                  color: Colors.white, // Background color for zoomed image
                  padding: const EdgeInsets.all(10),
                  child: Image.asset(imagePath),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showZoomedImage(context, imagePath),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: darkBlue,
                ),
              ),
              const SizedBox(height: 10),
              Hero(
                tag: imagePath,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(
                    imagePath,
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                description,
                style: TextStyle(
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}