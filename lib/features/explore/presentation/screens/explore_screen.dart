import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tourpal/core/constants/app_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/logger.dart';
import '../../../../models/tour_plan.dart';
import '../../../../features/tours/domain/enums/tour_status.dart';
import '../../../../features/tours/presentation/screens/tour_preview_page.dart';
import '../../../tours/domain/entities/tour.dart';
import '../../../tours/domain/enums/tour_category.dart';
import '../../../tours/domain/enums/tour_difficulty.dart';
import '../../domain/enums/sort_criteria.dart';
import '../bloc/explore_bloc.dart';
import '../bloc/explore_event.dart';
import '../bloc/explore_state.dart';
import '../widgets/enhanced_tour_card.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_chips_widget.dart';
import '../widgets/sort_bottom_sheet.dart';
import '../widgets/quick_filters_row.dart';
import '../../../tour_creation/presentation/screens/create_tour_screen.dart';
import '../../../favorites/presentation/bloc/favorites_bloc.dart';
import '../../../favorites/presentation/bloc/favorites_event.dart';
import '../../../favorites/presentation/bloc/favorites_state.dart';
import '../../../notifications/presentation/bloc/notifications_bloc.dart';
import '../../../notifications/presentation/bloc/notifications_event.dart';
import '../../../notifications/presentation/bloc/notifications_state.dart';
import '../../../../models/notification.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> 
    with AutomaticKeepAliveClientMixin {
  
  late final ScrollController _scrollController;
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  
  bool _isScrolledUp = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    
    _setupScrollListener();
    _loadInitialData();
    
    AppLogger.info('ExploreScreen initialized');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      final isScrolledUp = _scrollController.offset > 100;
      if (isScrolledUp != _isScrolledUp) {
        setState(() => _isScrolledUp = isScrolledUp);
      }
    });
  }

  void _loadInitialData() {
    context.read<ExploreBloc>().add(const LoadToursEvent());
    context.read<FavoritesBloc>().add(const LoadFavoritesEvent());
    context.read<NotificationsBloc>().add(const LoadNotificationsEvent());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocListener<ExploreBloc, ExploreState>(
        listener: (context, state) {
          if (state is ExploreLoaded && state.searchQuery == null && _searchController.text.isNotEmpty) {
            _searchController.clear();
          }
        },
        child: BlocBuilder<ExploreBloc, ExploreState>(
          builder: (context, state) {
            return CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(context, state),
                _buildSearchSection(context, state),
                if (state is ExploreLoaded) ...[
                  _buildTabContent(context, state),
                ] else if (state is ExploreLoading) ...[
                  SliverFillRemaining(
                    child: _buildLoadingWidget(),
                  ),
                ] else if (state is ExploreError) ...[
                  SliverFillRemaining(
                    child: _buildErrorWidget(state.message),
                  ),
                ],
              ],
            );
          },
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Discovering amazing tours...'),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(message),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadInitialData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, ExploreState state) {
    return SliverAppBar(
      expandedHeight: _isScrolledUp ? 80 : 120,
      floating: true,
      pinned: true,
      snap: false,
      elevation: 0,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        title: AnimatedOpacity(
          opacity: _isScrolledUp ? 1.0 : 0.8,
          duration: const Duration(milliseconds: 200),
          child: const Text(
            'Explore Tours',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primary.withValues(alpha: .9),
              ],
            ),
          ),
        ),
      ),
      actions: [
        BlocBuilder<NotificationsBloc, NotificationsState>(
          builder: (context, notificationState) {
            int unreadCount = 0;
            if (notificationState is NotificationsLoaded) {
              unreadCount = notificationState.unreadCount;
            }
            
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                  onPressed: () => _showNotifications(context),
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white, size: 22),
          onPressed: () => _focusSearchBar(),
        ),
        IconButton(
          icon: const Icon(Icons.tune, color: Colors.white, size: 22),
          onPressed: () => _showFiltersBottomSheet(context, state),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchSection(BuildContext context, ExploreState state) {
    return SliverToBoxAdapter(
      child: Container(
        color: AppColors.primary,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(
            children: [
              // Search bar
              SearchBarWidget(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: _onSearchChanged,
                onClear: _onSearchCleared,
                isLoading: state is ExploreSearching,
              ),
              const SizedBox(height: 16),
              if (state is ExploreLoaded) ...[
                QuickFiltersRow(
                  selectedCategory: state.selectedCategory,
                  selectedDifficulty: state.selectedDifficulty,
                  onCategorySelected: _onCategorySelected,
                  onDifficultySelected: _onDifficultySelected,
                ),
                if (state.hasFilters || state.hasSearchQuery) ...[
                  const SizedBox(height: 12),
                  FilterChipsWidget(
                    searchQuery: state.searchQuery ?? '',
                    selectedCategory: state.selectedCategory,
                    selectedDifficulty: state.selectedDifficulty,
                    minPrice: state.minPrice,
                    maxPrice: state.maxPrice,
                    resultsCount: state.displayTours.length,
                    onClearAll: _onClearAllFilters,
                    onClearCategory: () => _onCategorySelected(null),
                    onClearDifficulty: () => _onDifficultySelected(null),
                    onClearPrice: () => _onPriceRangeChanged(null, null),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, ExploreLoaded state) {
    if (state.displayTours.isEmpty) {
      return SliverFillRemaining(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppColors.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverFillRemaining(
                child: _buildEmptyState(state),
              ),
            ],
          ),
        ),
      );
    }
    
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final tour = state.displayTours[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: BlocBuilder<FavoritesBloc, FavoritesState>(
                builder: (context, favoritesState) {
                  bool isFavorite = false;
                  if (favoritesState is FavoritesLoaded) {
                    isFavorite = favoritesState.isFavorite(tour.id);
                  }
                  
                  return EnhancedTourCard(
                    tour: tour,
                    onTap: () => _onTourTapped(tour),
                    onFavorite: () => _onFavoriteTapped(tour),
                    isFavorite: isFavorite,
                    showDistance: false,
                    layout: TourCardLayout.horizontal,
                  );
                },
              ),
            );
          },
          childCount: state.displayTours.length,
        ),
      ),
    );
  }

  Widget _buildEmptyState(ExploreLoaded state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No tours found',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.hasFilters
                  ? 'Try adjusting your filters or search terms'
                  : 'No tours available at the moment',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (state.hasFilters) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _onClearAllFilters,
                child: const Text('Clear All Filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return AnimatedOpacity(
      opacity: !_isScrolledUp ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: FloatingActionButton.extended(
        onPressed: _onCreateTourTapped,
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Create Tour',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Event handlers
  void _focusSearchBar() {
    _searchFocusNode.requestFocus();
  }

  void _onSearchChanged(String query) {
    context.read<ExploreBloc>().add(SearchToursEvent(query: query));
  }

  void _onSearchCleared() {
    _searchController.clear();
    context.read<ExploreBloc>().add(const ClearSearchEvent());
  }

  void _onCategorySelected(TourCategory? category) {
    context.read<ExploreBloc>().add(FilterByCategoryEvent(category: category));
  }

  void _onDifficultySelected(TourDifficulty? difficulty) {
    context.read<ExploreBloc>().add(FilterByDifficultyEvent(difficulty: difficulty));
  }

  void _onPriceRangeChanged(double? minPrice, double? maxPrice) {
    context.read<ExploreBloc>().add(FilterByPriceEvent(
      minPrice: minPrice,
      maxPrice: maxPrice,
    ));
  }

  void _onClearAllFilters() {
    _searchController.clear();
    context.read<ExploreBloc>().add(const ClearFiltersEvent());
  }

  void _onTourTapped(Tour tour) {
    AppLogger.info('Tapping tour: ${tour.title}');
    
    final tourPlan = TourPlan(
      id: tour.id,
      guideId: tour.guideId,
      title: tour.title,
      description: tour.description,
      duration: tour.duration.inHours,
      difficulty: tour.difficulty.name,
      tags: tour.highlights,
      isPublic: tour.isActive,
      status: TourStatus.published,
      averageRating: tour.rating ?? 0.0,
      totalReviews: tour.reviewCount ?? 0,
      bookingCount: tour.bookingCount ?? 0,
      favoriteCount: 0,
      price: tour.price,
      imageUrl: tour.images.isNotEmpty ? tour.images.first : null,
      createdAt: tour.createdAt,
      updatedAt: tour.updatedAt,
    );
    
    // Navigate to tour preview screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TourPreviewPage(tour: tourPlan),
      ),
    );
  }

  void _onFavoriteTapped(Tour tour) {
    AppLogger.info('Toggling favorite for tour: ${tour.title}');
    context.read<FavoritesBloc>().add(ToggleFavoriteEvent(tourId: tour.id));
    
    context.read<NotificationsBloc>().add(CreateNotificationEvent(
      title: 'Favorite Updated',
      message: 'Tour "${tour.title}" has been added to your favorites!',
      type: NotificationType.favorite,
      actionData: tour.id,
    ));
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<NotificationsBloc, NotificationsState>(
                builder: (context, state) {
                  if (state is NotificationsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is NotificationsLoaded) {
                    if (state.notifications.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No notifications yet'),
                          ],
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      itemCount: state.notifications.length,
                      itemBuilder: (context, index) {
                        final notification = state.notifications[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: notification.isRead 
                                ? Colors.grey.shade300 
                                : AppColors.primary,
                            child: Text(
                              notification.type.emoji,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          title: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: notification.isRead 
                                  ? FontWeight.normal 
                                  : FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(notification.message),
                          trailing: notification.isRead 
                              ? null 
                              : Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                          onTap: () {
                            if (!notification.isRead) {
                              context.read<NotificationsBloc>().add(
                                MarkNotificationReadEvent(
                                  notificationId: notification.id,
                                ),
                              );
                            }
                          },
                        );
                      },
                    );
                  } else if (state is NotificationsError) {
                    return Center(
                      child: Text('Error: ${state.message}'),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onCreateTourTapped() {
    AppLogger.info('Create Tour button tapped');
    // Navigate to create tour screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateTourScreen(),
      ),
    );
  }

  void _showFiltersBottomSheet(BuildContext context, ExploreState state) {
    if (state is ExploreLoaded) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => SortBottomSheet(
          currentSortOption: state.sortCriteria ?? SortCriteria.newest,
          onSortChanged: (criteria) {
            context.read<ExploreBloc>().add(SortToursEvent(criteria: criteria));
            Navigator.pop(context);
          },
        ),
      );
    }
  }

  Future<void> _onRefresh() async {
    context.read<ExploreBloc>().add(const LoadToursEvent());
    context.read<FavoritesBloc>().add(const LoadFavoritesEvent());
    context.read<NotificationsBloc>().add(const LoadNotificationsEvent());
  }
}