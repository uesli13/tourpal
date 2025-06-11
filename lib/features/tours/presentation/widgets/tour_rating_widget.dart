import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class TourRatingWidget extends StatelessWidget {
  final int rating;

  TourRatingWidget({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          Icons.star,
          color: index < rating ? AppColors.mutedOrange : AppColors.grey,
        );
      }),
    );
  }
}

class TourCard extends StatelessWidget {
  final String title;
  final String description;
  final int rating;

  TourCard({
    required this.title,
    required this.description,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(description),
          Row(
            children: [
              TourRatingWidget(rating: rating),
              SizedBox(width: 8),
              Text(
                '$rating/5',
                style: TextStyle(color: AppColors.mutedGreen),
              ),
            ],
          ),
        ],
      ),
    );
  }
}