import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/place.dart';
import '../../../../models/tour_session.dart';
import '../../../../models/user.dart' as UserModel;

class BottomCarouselWidget extends StatefulWidget {
  final List<Place> places;
  final int currentPlaceIndex;
  final List<bool> visitedPlaces;
  final TourSession? tourSession;
  final bool isGuide;
  final Function(int)? onPlaceTapped;
  final Duration? estimatedTravelTime;
  final double? estimatedDistance;
  final UserModel.User? guideProfile;
  final UserModel.User? travelerProfile;
  final bool isExpanded;
  final VoidCallback? onExpansionChanged;
  final Function(int)? onJournalEntry;

  const BottomCarouselWidget({
    super.key,
    required this.places,
    required this.currentPlaceIndex,
    required this.visitedPlaces,
    this.tourSession,
    this.isGuide = false,
    this.onPlaceTapped,
    this.estimatedTravelTime,
    this.estimatedDistance,
    this.guideProfile,
    this.travelerProfile,
    this.isExpanded = false,
    this.onExpansionChanged,
    this.onJournalEntry,
  });

  @override
  State<BottomCarouselWidget> createState() => _BottomCarouselWidgetState();
}

class _BottomCarouselWidgetState extends State<BottomCarouselWidget> with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: widget.currentPlaceIndex.clamp(0, widget.places.length - 1),
      viewportFraction: 0.85,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _slideController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(BottomCarouselWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Auto-scroll to current place when it changes
    if (oldWidget.currentPlaceIndex != widget.currentPlaceIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            widget.currentPlaceIndex.clamp(0, widget.places.length - 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  PlaceStatus _getPlaceStatus(int index) {
    if (index < widget.visitedPlaces.length && widget.visitedPlaces[index]) {
      return PlaceStatus.visited;
    } else if (index == widget.currentPlaceIndex) {
      return PlaceStatus.current;
    } else if (index > widget.currentPlaceIndex) {
      return PlaceStatus.upcoming;
    } else {
      return PlaceStatus.pending;
    }
  }

  Color _getStatusColor(PlaceStatus status) {
    switch (status) {
      case PlaceStatus.visited:
        return Colors.green;
      case PlaceStatus.current:
        return AppColors.primary;
      case PlaceStatus.upcoming:
        return Colors.orange;
      case PlaceStatus.pending:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(PlaceStatus status) {
    switch (status) {
      case PlaceStatus.visited:
        return Icons.check_circle;
      case PlaceStatus.current:
        return Icons.location_on;
      case PlaceStatus.upcoming:
        return Icons.schedule;
      case PlaceStatus.pending:
        return Icons.radio_button_unchecked;
    }
  }

  String _getStatusText(PlaceStatus status) {
    switch (status) {
      case PlaceStatus.visited:
        return 'Visited';
      case PlaceStatus.current:
        return 'Current Destination';
      case PlaceStatus.upcoming:
        return 'Upcoming';
      case PlaceStatus.pending:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.4; // Max 40% of screen height
    final compactHeight = screenHeight * 0.25; // Compact 25% of screen height
    
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        height: widget.isExpanded ? maxHeight : compactHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle bar and header
            _buildHeader(),
            
            // Travel info (if available and expanded)
            if (widget.isExpanded && (widget.estimatedTravelTime != null || widget.estimatedDistance != null))
              _buildTravelInfo(),
            
            // Places carousel
            Expanded(
              child: _buildPlacesCarousel(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Compact header
          Row(
            children: [
              // Progress indicator (smaller)
              _buildCompactProgressIndicator(),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stop ${widget.currentPlaceIndex + 1} of ${widget.places.length}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (widget.currentPlaceIndex < widget.places.length)
                      Text(
                        widget.places[widget.currentPlaceIndex].name,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              
              // Travel time (compact)
              if (!widget.isExpanded && widget.estimatedTravelTime != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.estimatedTravelTime!.inMinutes}m',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(width: 8),
              
              // Expand/collapse button
              IconButton(
                onPressed: widget.onExpansionChanged,
                icon: Icon(
                  widget.isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.textSecondary,
                ),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactProgressIndicator() {
    final visitedCount = widget.visitedPlaces.where((v) => v).length;
    final totalCount = widget.places.length;
    final progress = totalCount > 0 ? visitedCount / totalCount : 0.0;
    
    return Container(
      width: 40,
      height: 40,
      child: Stack(
        children: [
          // Progress circle
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 3,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              progress == 1.0 ? Colors.green : AppColors.primary,
            ),
          ),
          
          // Center text
          Center(
            child: Text(
              '$visitedCount',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTravelInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.directions_walk, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          
          if (widget.estimatedDistance != null) ...[
            Text(
              '${widget.estimatedDistance!.toStringAsFixed(1)} km',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 16),
          ],
          
          if (widget.estimatedTravelTime != null) ...[
            Icon(Icons.access_time, color: AppColors.primary, size: 16),
            const SizedBox(width: 4),
            Text(
              '${widget.estimatedTravelTime!.inMinutes} min',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
          
          const Spacer(),
          
          Text(
            'to next destination',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlacesCarousel() {
    if (!widget.isExpanded) {
      // Show only current place in compact mode
      return _buildCurrentPlaceCard();
    }
    
    return PageView.builder(
      controller: _pageController,
      itemCount: widget.places.length,
      onPageChanged: (index) {
        if (widget.onPlaceTapped != null) {
          widget.onPlaceTapped!(index);
        }
      },
      itemBuilder: (context, index) {
        return _buildPlaceCard(widget.places[index], index);
      },
    );
  }

  Widget _buildCurrentPlaceCard() {
    if (widget.currentPlaceIndex >= widget.places.length) {
      return const Center(child: Text('Tour completed!'));
    }
    
    final place = widget.places[widget.currentPlaceIndex];
    final status = _getPlaceStatus(widget.currentPlaceIndex);
    final isVisited = status == PlaceStatus.visited;
    
    return GestureDetector(
      onTap: () {
        if (isVisited && !widget.isGuide && widget.onJournalEntry != null) {
          // Open journal entry for visited places (travelers only)
          widget.onJournalEntry!(widget.currentPlaceIndex);
        } else if (widget.onPlaceTapped != null) {
          // Regular place tap behavior
          widget.onPlaceTapped!(widget.currentPlaceIndex);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _getStatusColor(status).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _getStatusColor(status).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            // Place image or icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                image: place.photoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(place.photoUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: place.photoUrl == null
                  ? Icon(Icons.place, color: Colors.grey[400], size: 30)
                  : null,
            ),
            
            const SizedBox(width: 16),
            
            // Place info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getStatusIcon(status),
                        size: 16,
                        color: _getStatusColor(status),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          place.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    isVisited && !widget.isGuide ? 'Tap to add journal' : _getStatusText(status),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  if (place.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      place.description!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            
            // Journal icon for visited places (travelers only)
            if (isVisited && !widget.isGuide)
              Icon(
                Icons.edit_note,
                size: 20,
                color: Colors.green,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceCard(Place place, int index) {
    final status = _getPlaceStatus(index);
    final isCurrent = index == widget.currentPlaceIndex;
    final isVisited = status == PlaceStatus.visited;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: GestureDetector(
        onTap: () {
          if (isVisited && !widget.isGuide && widget.onJournalEntry != null) {
            // Open journal entry for visited places (travelers only)
            widget.onJournalEntry!(index);
          } else if (widget.onPlaceTapped != null) {
            // Regular place tap behavior
            widget.onPlaceTapped!(index);
          }
        },
        child: Card(
          elevation: isCurrent ? 8 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isCurrent ? _getStatusColor(status) : Colors.transparent,
              width: 2,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status and place name
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(status),
                            size: 14,
                            color: _getStatusColor(status),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(status),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Show journal icon for visited places (travelers only)
                    if (isVisited && !widget.isGuide) ...[
                      Icon(
                        Icons.edit_note,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                    ],
                    
                    Text(
                      isVisited && !widget.isGuide ? 'Add Journal' : _getStatusText(status),
                      style: TextStyle(
                        fontSize: 10,
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Place image
                if (place.photoUrl != null)
                  Container(
                    height: 80,
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
                    height: 80,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.place, color: Colors.grey[400], size: 40),
                  ),
                
                const SizedBox(height: 12),
                
                // Place name and description
                Text(
                  place.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                if (place.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    place.description!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                
                const SizedBox(height: 8),
                
                // Duration info and journal hint
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${place.stayingDuration} min stay',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    
                    if (isVisited && !widget.isGuide) ...[
                      const Spacer(),
                      Text(
                        'Tap to add journal',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum PlaceStatus {
  visited,
  current,
  upcoming,
  pending,
}