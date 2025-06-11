import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/tour_plan.dart';
import '../../../tours/domain/repositories/tour_repository.dart';
import '../../../tours/presentation/screens/create_tour_screen.dart';
import '../../../tours/presentation/screens/edit_tour_screen.dart';
import '../../../tours/presentation/screens/tour_preview_screen.dart';

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class MyToursScreen extends StatefulWidget {
  const MyToursScreen({super.key});

  @override
  State<MyToursScreen> createState() => _MyToursScreenState();
}

class _MyToursScreenState extends State<MyToursScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<TourPlan> _allTours = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTours();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTours() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        if (!mounted) return;
        setState(() {
          _error = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      final tourRepository = context.read<TourRepository>();
      final tours = await tourRepository.getToursByGuideId(currentUser.uid);
      
      if (!mounted) return;
      setState(() {
        _allTours = tours;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load tours: $e';
        _isLoading = false;
      });
    }
  }

  List<TourPlan> get _activeTours => _allTours
      .where((tour) => tour.status == TourStatus.published)
      .toList();

  List<TourPlan> get _draftTours => _allTours
      .where((tour) => tour.status == TourStatus.draft)
      .toList();

  List<TourPlan> get _pastTours => []; // For now, return empty list since TourStatus only has draft and published

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'My Tours',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.secondary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.secondary,
          indicatorWeight: 3,
          tabs: [
            Tab(text: 'Active (${_activeTours.length})'),
            Tab(text: 'Drafts (${_draftTours.length})'),
            Tab(text: 'Past (${_pastTours.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: AppColors.gray400),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadTours,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                        ),
                        child: const Text('Retry', style: TextStyle(color: AppColors.textOnSecondary)),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTourList(_activeTours),
                    _buildTourList(_draftTours),
                    _buildTourList(_pastTours),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateTour(context),
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.textOnSecondary,
        icon: const Icon(Icons.add),
        label: const Text('Create Tour'),
      ),
    );
  }

  Widget _buildTourList(List<TourPlan> tours) {
    if (tours.isEmpty) {
      return _buildEmptyState(
        icon: Icons.tour,
        title: 'No Tours Found',
        subtitle: 'Start by creating your first tour!',
        buttonText: 'Create New Tour',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tours.length,
      itemBuilder: (context, index) {
        final tour = tours[index];
        return _buildTourCard(
          title: tour.title,
          description: tour.description ?? 'No description available',
          price: tour.price.toDouble(),
          duration: '${tour.duration} hours',
          bookings: 0, // TourPlan doesn't have bookings property, so use 0 for now
          status: tour.status.name.capitalize(),
          statusColor: tour.status == TourStatus.published ? AppColors.secondary : AppColors.secondaryLight,
          imageUrl: tour.coverImageUrl,
          onEdit: () => _navigateToEditTour(tour),
          onView: () => _navigateToTourPreview(tour),
        );
      },
    );
  }

  Widget _buildTourCard({
    required String title,
    required String description,
    required double price,
    required String duration,
    required int bookings,
    required String status,
    required Color statusColor,
    String? imageUrl,
    required VoidCallback onEdit,
    required VoidCallback onView,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tour Image
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Stack(
                      children: [
                        // Cover Image
                        Image.network(
                          imageUrl,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 150,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppColors.secondaryLight.withValues(alpha: .7), AppColors.secondaryLight.withValues(alpha: .9)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 150,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppColors.secondaryLight.withValues(alpha: .7), AppColors.secondaryLight.withValues(alpha: .9)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.tour,
                                  size: 48,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                        ),
                        // Gradient overlay for better text readability
                        Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.secondaryLight.withValues(alpha: .7), AppColors.secondaryLight.withValues(alpha: .9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.tour,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
          ),
          
          // Tour Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                    Text(
                      '\$${price.toInt()}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                    Text(
                      duration,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const Spacer(),
                    Icon(Icons.group, size: 16, color: Colors.grey[600]),
                    Text(
                      '$bookings bookings',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onView,
                        icon: const Icon(Icons.visibility),
                        label: const Text('View'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondaryLight),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _navigateToCreateTour(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondaryLight),
            child: Text(buttonText, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _navigateToCreateTour(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateTourScreen(),
      ),
    ).then((tourId) {
      if (tourId != null) {
        // Tour was created successfully, refresh the tours list
        _loadTours();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tour created successfully! 🎉'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    });
  }

  void _navigateToTourPreview(TourPlan tour) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TourPreviewScreen(
          tourPlan: tour,
          places: tour.places,
        ),
      ),
    ).then((result) {
      if (result == 'edit') {
        // User clicked Edit from preview, navigate to edit screen
        _navigateToEditTour(tour);
      } else if (result == 'published') {
        // Tour was published successfully, refresh the tours list
        _loadTours();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tour published successfully! 🎉\nIt\'s now visible to travelers.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });
  }

  void _navigateToEditTour(TourPlan tour) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTourScreen(
          tourPlan: tour,
        ),
      ),
    ).then((tourId) {
      if (tourId != null) {
        // Tour was updated successfully, refresh the tours list
        _loadTours();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tour updated successfully! 🎉'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    });
  }
}