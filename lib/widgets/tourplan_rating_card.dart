import 'package:flutter/material.dart';
import '../models/tourplan_rating.dart';
import '../utils/constants.dart';

class TourplanRatingCard extends StatelessWidget {
  final TourplanRating rating;

  const TourplanRatingCard({super.key, required this.rating});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: const Icon(Icons.person, color: AppColors.primary),
        title: Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 18),
            const SizedBox(width: 4),
            Text('${rating.ratingScore} / 5',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        subtitle: Text(rating.reviewText),
      ),
    );
  }
}
