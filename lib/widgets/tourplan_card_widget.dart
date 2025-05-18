import 'package:flutter/material.dart';

class TourPlanCard extends StatelessWidget {
  final String title;
  final String city;
  final String imageUrl;
  final int destinationCount;
  final double averageRating;
  final VoidCallback? onTap;           

  const TourPlanCard({
    required this.title,
    required this.city,
    required this.imageUrl,
    required this.destinationCount,
    required this.averageRating,
    this.onTap,                        
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // image...
            imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.network(imageUrl, height: 180, width: double.infinity, fit: BoxFit.cover),
                  )
                : Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                  ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(city, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text('Places: $destinationCount'),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(averageRating.toStringAsFixed(1)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
