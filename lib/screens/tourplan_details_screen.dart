import 'package:flutter/material.dart';
import 'package:tourpal/models/destination.dart';
import 'package:tourpal/models/tourplan.dart';
import 'package:tourpal/services/tourplan_repository.dart';
import 'package:tourpal/widgets/destination_card.dart';
import '../utils/constants.dart';

class TourPlanDetailsScreen extends StatefulWidget {
  final TourPlan tourPlan;

  const TourPlanDetailsScreen({Key? key, required this.tourPlan}) : super(key: key);

  @override
  State<TourPlanDetailsScreen> createState() => _TourPlanDetailsScreenState();
}

class _TourPlanDetailsScreenState extends State<TourPlanDetailsScreen> {
  final _tourPlanRepo = TourPlanRepository();
  late Future<List<Destination>> _destinationsFuture;

  @override
  void initState() {
    super.initState();
    _destinationsFuture = _tourPlanRepo.fetchDestinations(widget.tourPlan.id!);
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.tourPlan;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text("Tour Details"),
        foregroundColor: Colors.white,

      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with title & city overlay
            Stack(
              alignment: Alignment.bottomLeft,
              children: [
                Image.network(
                  plan.image ?? '',
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Text(
                    '${plan.title ?? 'Untitled'} - ${plan.city ?? ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Destination count
            FutureBuilder<int>(
              future: _tourPlanRepo.getDestinationCount(plan.id!),
              builder: (context, snap) {
                // While loading
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: LinearProgressIndicator(),
                  );
                }
                // On error or no data, default to 0
                final count = snap.data ?? 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.place, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        '$count Destinations',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Description
            if (plan.description != null && plan.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Description",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(plan.description!),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

            // Destinations list
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text(
                "Destinations",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<Destination>>(
              future: _destinationsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ));
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error loading destinations: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No destinations found.'),
                  ));
                }

                final destinations = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: destinations.length,
                  itemBuilder: (context, index) {
                    return DestinationCard(dest: destinations[index]);
                  },
                );
              },
            ),

            const SizedBox(height: 24),

            // View on map button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: () {
                  // TODO: Implement this function
                },
                icon: const Icon(Icons.map),
                label: const Text("View on Map"),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
