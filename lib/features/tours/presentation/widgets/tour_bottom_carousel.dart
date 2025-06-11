import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/tour_plan.dart';
import '../../../../models/place.dart';

class TourBottomCarousel extends StatefulWidget {
  final TourPlan tourPlan;
  final int currentPlaceIndex;
  final List<String> visitedPlaceIds;
  final bool isExpanded;
  final bool isGuide;
  final VoidCallback onToggleExpanded;
  final Function(int) onPlaceSelected;
  final Function(String) onMarkVisited;
  final Function(String) onOpenJournal;

  const TourBottomCarousel({
    super.key,
    required this.tourPlan,
    required this.currentPlaceIndex,
    required this.visitedPlaceIds,
    required this.isExpanded,
    required this.isGuide,
    required this.onToggleExpanded,
    required this.onPlaceSelected,
    required this.onMarkVisited,
    required this.onOpenJournal,
  });

  @override
  State<TourBottomCarousel> createState() => _TourBottomCarouselState();
}

class _TourBottomCarouselState extends State<TourBottomCarousel>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.currentPlaceIndex);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TourBottomCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
    
    if (widget.currentPlaceIndex != oldWidget.currentPlaceIndex) {
      _pageController.animateToPage(
        widget.currentPlaceIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.7;
    const minHeight = 120.0;

    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        final currentHeight = minHeight + (maxHeight - minHeight) * _expandAnimation.value;
        
        return Container(
          height: currentHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag handle and header
              GestureDetector(
                onTap: widget.onToggleExpanded,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    children: [
                      // Drag handle
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Progress indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Stop ${widget.currentPlaceIndex + 1} of ${widget.tourPlan.places.length}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Content area
              Expanded(
                child: widget.isExpanded
                    ? _buildExpandedView()
                    : _buildCollapsedView(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCollapsedView() {
    if (widget.currentPlaceIndex >= widget.tourPlan.places.length) {
      return _buildTourCompletedCard();
    }
    
    final currentPlace = widget.tourPlan.places[widget.currentPlaceIndex];
    final isVisited = widget.visitedPlaceIds.contains(currentPlace.id);
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Place image/icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.backgroundLight,
              image: currentPlace.photoUrl != null
                  ? DecorationImage(
                      image: NetworkImage(currentPlace.photoUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: currentPlace.photoUrl == null
                ? Icon(Icons.place, color: AppColors.primary, size: 30)
                : null,
          ),
          
          const SizedBox(width: 12),
          
          // Place info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        currentPlace.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isVisited)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check, size: 12, color: Colors.green.shade700),
                            const SizedBox(width: 2),
                            Text(
                              'Visited',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  currentPlace.description ?? 'Explore this location',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // Action button
          if (widget.isGuide && !isVisited)
            IconButton(
              onPressed: () => widget.onMarkVisited(currentPlace.id),
              icon: const Icon(Icons.check_circle),
              color: Colors.green,
            )
          else if (!widget.isGuide)
            IconButton(
              onPressed: () => widget.onOpenJournal(currentPlace.id),
              icon: const Icon(Icons.edit),
              color: AppColors.primary,
            ),
        ],
      ),
    );
  }

  Widget _buildExpandedView() {
    return Column(
      children: [
        // Page indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tour Progress',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${widget.visitedPlaceIds.length}/${widget.tourPlan.places.length} completed',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Places list
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              widget.onPlaceSelected(index);
            },
            itemCount: widget.tourPlan.places.length + 1, // +1 for completion card
            itemBuilder: (context, index) {
              if (index >= widget.tourPlan.places.length) {
                return _buildTourCompletedCard();
              }
              
              return _buildPlaceCard(widget.tourPlan.places[index], index);
            },
          ),
        ),
        
        // Navigation dots
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.tourPlan.places.length + 1,
              (index) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == widget.currentPlaceIndex
                      ? AppColors.primary
                      : Colors.grey.shade300,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceCard(Place place, int index) {
    final isVisited = widget.visitedPlaceIds.contains(place.id);
    final isCurrent = index == widget.currentPlaceIndex;
    final isPast = index < widget.currentPlaceIndex;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrent 
            ? AppColors.primary.withOpacity(0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent 
              ? AppColors.primary
              : Colors.grey.shade200,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(isVisited, isCurrent, isPast).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getStatusIcon(isVisited, isCurrent, isPast),
                      size: 12,
                      color: _getStatusColor(isVisited, isCurrent, isPast),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getStatusText(isVisited, isCurrent, isPast),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(isVisited, isCurrent, isPast),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Stop ${index + 1}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Place image
          if (place.photoUrl != null)
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: NetworkImage(place.photoUrl!),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.backgroundLight,
              ),
              child: Icon(
                Icons.place,
                size: 48,
                color: AppColors.primary.withOpacity(0.5),
              ),
            ),
          
          const SizedBox(height: 12),
          
          // Place name and description
          Text(
            place.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            place.description ?? 'Explore this amazing location',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => widget.onPlaceSelected(index),
                  icon: const Icon(Icons.map, size: 16),
                  label: const Text('View on Map'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (widget.isGuide && isCurrent && !isVisited)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => widget.onMarkVisited(place.id),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Mark Visited'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                )
              else if (!widget.isGuide && (isCurrent || isVisited))
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => widget.onOpenJournal(place.id),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Add to Journal'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTourCompletedCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            size: 64,
            color: Colors.green.shade600,
          ),
          const SizedBox(height: 16),
          Text(
            'Tour Completed!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Congratulations! You\'ve completed all stops on this tour.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.green.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (widget.isGuide)
            ElevatedButton.icon(
              onPressed: () {
                // This will be handled by the parent screen
              },
              icon: const Icon(Icons.flag, size: 16),
              label: const Text('End Tour Session'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: () => widget.onOpenJournal('tour_summary'),
              icon: const Icon(Icons.book, size: 16),
              label: const Text('Complete Journal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(bool isVisited, bool isCurrent, bool isPast) {
    if (isVisited) return Colors.green;
    if (isCurrent) return AppColors.primary;
    if (isPast) return Colors.orange;
    return Colors.grey;
  }

  IconData _getStatusIcon(bool isVisited, bool isCurrent, bool isPast) {
    if (isVisited) return Icons.check_circle;
    if (isCurrent) return Icons.location_on;
    if (isPast) return Icons.schedule;
    return Icons.circle_outlined;
  }

  String _getStatusText(bool isVisited, bool isCurrent, bool isPast) {
    if (isVisited) return 'VISITED';
    if (isCurrent) return 'CURRENT';
    if (isPast) return 'PASSED';
    return 'UPCOMING';
  }
}