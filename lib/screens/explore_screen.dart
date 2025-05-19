import 'package:flutter/material.dart';
import 'package:tourpal/screens/tourplan_details_screen.dart';
import 'package:tourpal/services/rating_repository.dart';
import 'package:tourpal/services/tourplan_repository.dart';
import 'package:tourpal/utils/constants.dart';
import '../widgets/tourplan_card_widget.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _tourPlanRepo = TourPlanRepository();
  final _ratingRepo = TourplanRatingRepository();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late Future<List<Widget>> _tourPlanCards;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _tourPlanCards = _loadTourPlans();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }


  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _tourPlanCards = _loadTourPlans();
    });
  }

  Future<List<Widget>> _loadTourPlans() async {
    final tourPlans = await _tourPlanRepo.fetchAllTourPlans();

    // Filter by search query (city)
    final filtered = tourPlans.where((plan) {
      final city = plan.city?.toLowerCase() ?? '';
      return city.contains(_searchQuery);
    }).toList();

    return Future.wait(filtered.map((plan) async {
      final count = await _tourPlanRepo.getDestinationCount(plan.id!);
      final rating = await _ratingRepo.getAverageRating(plan.id!);

      return TourPlanCard(
        title: plan.title ?? '',
        city: plan.city ?? '',
        imageUrl: plan.image ?? '',
        destinationCount: count,
        averageRating: rating,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TourPlanDetailsScreen(tourPlan: plan),
              ),
            );
          },
      );
    }).toList());
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      title: const Text("Explore"),
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.asset(
          'assets/images/tourpal_logo.png',
          fit: BoxFit.contain,
        ),
      ),
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search by city',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Widget>>(
            future: _tourPlanCards,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error loading tourplans: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No tourplans available.'));
              }

              return ListView(children: snapshot.data!);
            },
          ),
        ),
      ],
    ),
  );
}
}
