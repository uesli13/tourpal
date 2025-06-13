import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/logger.dart';
import '../../../../models/tour_plan.dart';
import '../../../../models/user.dart';
import '../../../../models/place.dart';
import '../../../tours/presentation/bloc/tour_bloc.dart';
import '../../../tours/presentation/bloc/tour_event.dart';
import '../../../tours/presentation/bloc/tour_state.dart';
import '../../../tours/presentation/screens/tour_preview_screen.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../bookings/presentation/widgets/booking_dialog_widget.dart';
import '../widgets/guide_details_dialog.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedDifficulty;
  RangeValues _priceRange = const RangeValues(0, 500);
  RangeValues _durationRange = const RangeValues(1, 24);
  List<String> _selectedTags = [];
  bool _showFilters = false;
  
  // Available filter options
  final List<String> _difficulties = ['Easy', 'Moderate', 'Hard', 'Expert'];
  final List<String> _availableTags = ['Adventure', 'Culture', 'Food', 'History', 'Nature', 'Art', 'Photography', 'Walking', 'Family-friendly'];
  
  // Guide profiles cache
  final Map<String, User> _guideProfiles = {};

  @override
  void initState() {
    super.initState();
    // Load all published tours when the screen initializes
    context.read<TourBloc>().add(const LoadAllPublishedToursEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<User?> _fetchGuideProfile(String guideId) async {
    if (_guideProfiles.containsKey(guideId)) {
      return _guideProfiles[guideId];
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(guideId)
          .get();
      
      if (userDoc.exists) {
        final guide = User.fromMap(userDoc.data()!, userDoc.id);
        _guideProfiles[guideId] = guide;
        return guide;
      }
    } catch (e) {
      AppLogger.logInfo('Error fetching guide profile: $e');
    }
    return null;
  }

  List<TourPlan> _applyFilters(List<TourPlan> tours) {
    return tours.where((tour) {
      // Search query filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final titleMatch = tour.title.toLowerCase().contains(query);
        final descriptionMatch = tour.description?.toLowerCase().contains(query) ?? false;
        final placesMatch = tour.places.any((place) => 
          place.name.toLowerCase().contains(query) || 
          (place.address?.toLowerCase().contains(query) ?? false)
        );
        
        if (!titleMatch && !descriptionMatch && !placesMatch) return false;
      }
      
      // Price filter
      if (tour.price < _priceRange.start || tour.price > _priceRange.end) return false;
      
      // Duration filter
      if (tour.duration < _durationRange.start || tour.duration > _durationRange.end) return false;
      
      // Tags filter
      if (_selectedTags.isNotEmpty) {
        final tourTags = tour.tags ?? [];
        if (!_selectedTags.any((tag) => tourTags.contains(tag))) return false;
      }
      
      // Difficulty filter
      if (_selectedDifficulty != null && tour.difficulty != _selectedDifficulty) return false;
      
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Explore Tours',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.tourist,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
              color: Colors.white,
            ),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textOnPrimary),
            onPressed: () {
              context.read<TourBloc>().add(const LoadAllPublishedToursEvent());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),
          
          // Filters Section
          if (_showFilters) _buildFiltersSection(),
          
          // Results
          Expanded(
            child: BlocBuilder<TourBloc, TourState>(
              builder: (context, state) {
                if (state is TourLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.tourist),
                  );
                }
                
                if (state is TourError) {
                  return _buildErrorState(state.message);
                }
                
                if (state is TourLoaded) {
                  final filteredTours = _applyFilters(state.filteredTours);
                  return _buildToursList(filteredTours);
                }
                
                return _buildEmptyState();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search tours, places, or addresses...',
          prefixIcon: const Icon(Icons.search, color: AppColors.tourist),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.tourist, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      height: 300, // Fixed height to prevent overflow
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        border: Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Price and Duration in a row
            Row(
              children: [
                // Price Range
                Expanded(
                  child: _buildCompactFilterGroup(
                    'Price',
                    '\$${_priceRange.start.toInt()}-\$${_priceRange.end.toInt()}',
                    RangeSlider(
                      values: _priceRange,
                      min: 0,
                      max: 500,
                      divisions: 25,
                      activeColor: AppColors.tourist,
                      onChanged: (values) => setState(() => _priceRange = values),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Duration Range
                Expanded(
                  child: _buildCompactFilterGroup(
                    'Duration',
                    '${_durationRange.start.toInt()}-${_durationRange.end.toInt()}h',
                    RangeSlider(
                      values: _durationRange,
                      min: 1,
                      max: 24,
                      divisions: 12,
                      activeColor: AppColors.tourist,
                      onChanged: (values) => setState(() => _durationRange = values),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Difficulty Filter
            _buildCompactFilterGroup(
              'Difficulty',
              '',
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildSmallChip(
                      label: 'Any',
                      isSelected: _selectedDifficulty == null,
                      onTap: () => setState(() => _selectedDifficulty = null),
                    ),
                    ..._difficulties.map((difficulty) => _buildSmallChip(
                      label: difficulty,
                      isSelected: _selectedDifficulty == difficulty,
                      onTap: () => setState(() => _selectedDifficulty = difficulty),
                    )),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Tags Filter - Fixed without problematic Container + SingleChildScrollView + Wrap
            _buildCompactFilterGroup(
              'Tags',
              '',
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // First row of tags
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _availableTags.take(5).map((tag) => Padding(
                        padding: const EdgeInsets.only(right: 6, bottom: 4),
                        child: _buildSmallChip(
                          label: tag,
                          isSelected: _selectedTags.contains(tag),
                          onTap: () {
                            setState(() {
                              if (_selectedTags.contains(tag)) {
                                _selectedTags.remove(tag);
                              } else {
                                _selectedTags.add(tag);
                              }
                            });
                          },
                        ),
                      )).toList(),
                    ),
                  ),
                  // Second row of tags if there are more than 5
                  if (_availableTags.length > 5)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _availableTags.skip(5).map((tag) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _buildSmallChip(
                            label: tag,
                            isSelected: _selectedTags.contains(tag),
                            onTap: () {
                              setState(() {
                                if (_selectedTags.contains(tag)) {
                                  _selectedTags.remove(tag);
                                } else {
                                  _selectedTags.add(tag);
                                }
                              });
                            },
                          ),
                        )).toList(),
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Clear Filters Button - Compact
            Center(
              child: TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('Clear Filters'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactFilterGroup(String title, String subtitle, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        content,
      ],
    );
  }

  Widget _buildSmallChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6, bottom: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.tourist : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.tourist : AppColors.border,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.textOnPrimary : AppColors.tourist,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _priceRange = const RangeValues(0, 500);
      _durationRange = const RangeValues(1, 24);
      _selectedTags.clear();
      _selectedDifficulty = null;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  Widget _buildToursList(List<TourPlan> tours) {
    if (tours.isEmpty) {
      return _buildNoResultsState();
    }

    return Column(
      children: [
        // Results count
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: AppColors.surfaceVariant,
          child: Text(
            '${tours.length} tour${tours.length == 1 ? '' : 's'} found',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        
        // Results list
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              context.read<TourBloc>().add(const LoadAllPublishedToursEvent());
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tours.length,
              itemBuilder: (context, index) {
                final tour = tours[index];
                return _buildEnhancedTourCard(tour);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedTourCard(TourPlan tour) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToTourDetails(tour),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tour image with overlay badges
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: tour.coverImageUrl != null && tour.coverImageUrl!.isNotEmpty
                        ? Image.network(
                            tour.coverImageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) => _buildDefaultImage(),
                          )
                        : _buildDefaultImage(),
                  ),
                  
                  // Top badges: Category and Difficulty
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Category badge
                        if (tour.category.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              tour.category,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        
                        // Difficulty badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(tour.difficulty),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getDifficultyIcon(tour.difficulty),
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                tour.difficulty,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Bottom badge: Number of places (removed random location pin)
                  if (tour.places.isNotEmpty)
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.shadowDark,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.place,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${tour.places.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(12), // Reduced padding for compactness
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and price row (more compact)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tour.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16, // Slightly smaller
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1, // Single line for compactness
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '\$${tour.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16, // Consistent size
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 6), // Reduced spacing
                  
                  // Compact info row: Location, Duration, Rating
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          tour.location,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${tour.duration}h',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildCompactRating(tour),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Tags section (more compact)
                  if (tour.tags != null && tour.tags!.isNotEmpty)
                    _buildCompactTagsSection(tour.tags!),
                  
                  // Tour highlights (more compact)
                  if (tour.places.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _buildCompactPlacesList(tour.places),
                  ],
                  
                  const SizedBox(height: 8),
                  
                  // Description (more compact)
                  if (tour.description != null && tour.description!.isNotEmpty)
                    Text(
                      tour.description!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        height: 1.3,
                      ),
                      maxLines: 1, // Single line for compactness
                      overflow: TextOverflow.ellipsis,
                    ),
                  
                  const SizedBox(height: 10),
                  
                  // Integrated Guide Section (more compact)
                  _buildCompactGuideSection(tour),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      case 'expert':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getDifficultyIcon(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Icons.terrain;
      case 'moderate':
        return Icons.hiking;
      case 'hard':
        return Icons.landscape;
      case 'expert':
        return Icons.filter_hdr;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildCompactRating(TourPlan tour) {
    if (tour.reviewCount == 0 || (tour.averageRating ?? 0) == 0) {
      return Text(
        'No reviews',
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey[600],
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('⭐', style: TextStyle(fontSize: 11)),
        const SizedBox(width: 2),
        Text(
          '${(tour.averageRating ?? 0).toStringAsFixed(1)} (${tour.reviewCount})',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactTagsSection(List<String> tags) {
    // Show max 2 tags for compactness
    final displayTags = tags.take(2).toList();
    final hasMoreTags = tags.length > 2;
    
    return Wrap(
      spacing: 4,
      runSpacing: 3,
      children: [
        ...displayTags.map((tag) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.guide),
          ),
          child: Text(
            tag,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.guide,
              fontWeight: FontWeight.w600,
            ),
          ),
        )),
        if (hasMoreTags)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.gray300),
            ),
            child: Text(
              '+${tags.length - 2}',
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.gray600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCompactGuideSection(TourPlan tour) {
    return Container(
      padding: const EdgeInsets.all(8), // Reduced padding
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: FutureBuilder<User?>(
        future: _fetchGuideProfile(tour.guideId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildCompactLoadingGuideSection();
          }
          
          if (!snapshot.hasData || snapshot.hasError) {
            return const SizedBox.shrink(); // Blank if no guide data
          }
          
          final guide = snapshot.data!;
          return _buildCompactGuideInfo(guide, tour);
        },
      ),
    );
  }

  Widget _buildCompactGuideInfo(User guide, TourPlan tour) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => _showGuideDetails(guide, tour),
          child: CircleAvatar(
            radius: 16, // Smaller avatar
            backgroundImage: guide.hasProfileImage
                ? NetworkImage(guide.profileImageUrl!)
                : null,
            backgroundColor: AppColors.backgroundLight,
            child: !guide.hasProfileImage
                ? const Icon(Icons.person, size: 16, color: AppColors.tourist)
                : null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () => _showGuideDetails(guide, tour),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  guide.displayName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: guide.isAvailable ? Colors.green : Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      guide.isAvailable ? 'Available' : 'Busy',
                      style: TextStyle(
                        fontSize: 10,
                        color: guide.isAvailable ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Single Book Now button to avoid confusion
        ElevatedButton.icon(
          onPressed: () => _showBookingDialog(guide, tour),
          icon: const Icon(Icons.book_online, size: 14),
          label: const Text('Book', style: TextStyle(fontSize: 11)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.tourist,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: const Size(60, 28),
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactLoadingGuideSection() {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.backgroundLight,
          child: const Icon(Icons.person, size: 16, color: AppColors.tourist),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 12,
                width: 80,
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 3),
              Container(
                height: 10,
                width: 60,
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showBookingDialog(User guide, TourPlan tour) {
    final authState = context.read<AuthBloc>().state;
    
    if (authState is! AuthAuthenticated) {
      _showSignInRequiredDialog();
      return;
    }

    showDialog(
      context: context,
      builder: (context) => BookingDialogWidget(
        tour: tour,
        guide: guide,
      ),
    );
  }

  void _showSignInRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.login, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Sign In Required'),
          ],
        ),
        content: const Text(
          'You need to sign in to your account before booking tours. '
          'Please sign in and try again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to auth screen - you may need to adjust this based on your navigation structure
              Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.tourist),
            child: const Text('Sign In', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showGuideDetails(User guide, TourPlan tour) {
    showDialog(
      context: context,
      builder: (context) => GuideDetailsDialog(
        guide: guide,
        tourPlan: tour,
      ),
    );
  }

  Widget _buildDefaultImage() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryDark,
            AppColors.primary
          ],
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
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off,
            size: 80,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          const Text(
            'No tours found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search criteria\nor clearing some filters',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _clearFilters,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All Filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 80,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          const Text(
            'Oops! Something went wrong',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.read<TourBloc>().add(const LoadAllPublishedToursEvent());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.explore,
            size: 80,
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Tours Available',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'No published tours found.\nCheck back later for new adventures!'
                : 'No tours match your search.\nTry different keywords.',
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                });
                _searchController.clear();
              },
              child: const Text('Clear Search'),
            ),
          ],
        ],
      ),
    );
  }

  void _navigateToTourDetails(TourPlan tour) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TourPreviewScreen(
          tourPlan: tour,
          places: tour.places,
          isExploreMode: true,
        ),
      ),
    );
  }

  Widget _buildCompactPlacesList(List<Place> places) {
    // Show max 3 places for compactness
    final displayPlaces = places.take(3).toList();
    final hasMorePlaces = places.length > 3;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...displayPlaces.map((place) => Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Row(
            children: [
              const Icon(
                Icons.location_on,
                size: 12,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  place.name,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        )),
        if (hasMorePlaces)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '+${places.length - 3} more places',
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.gray600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}