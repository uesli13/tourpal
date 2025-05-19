import 'package:flutter/material.dart';
import 'package:tourpal/models/tourplan_rating.dart';
import 'package:tourpal/services/rating_repository.dart';
import 'package:tourpal/widgets/tourplan_rating_card.dart';

class TourplanRatingsScreen extends StatelessWidget {
  final String tourPlanId;
  const TourplanRatingsScreen({super.key, required this.tourPlanId});

  @override
  Widget build(BuildContext context) {
    final repo = TourplanRatingRepository();
    return Scaffold(
      appBar: AppBar(title: const Text('Ratings')),
      body: FutureBuilder<List<TourplanRating>>(
        future: repo.fetchRatingsForTourplan(tourPlanId),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final ratings = snap.data!;
          if (ratings.isEmpty) {
            return const Center(child: Text('No ratings yet.'));
          }
          return ListView.builder(
            itemCount: ratings.length,
            itemBuilder: (_, i) => TourplanRatingCard(rating: ratings[i]),
          );
        },
      ),
    );
  }
}
