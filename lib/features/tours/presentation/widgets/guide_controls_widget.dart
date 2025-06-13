import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/place.dart';
import '../../../../models/tour_session.dart';

class GuideControlsWidget extends StatefulWidget {
  final int currentPlaceIndex;
  final List<Place> tourPlaces;
  final List<bool> visitedPlaces;
  final TourSession? tourSession;
  final Function(int) onPlaceChanged;
  final Function(int, bool) onPlaceVisitedChanged;
  final VoidCallback onTourCompleted;

  const GuideControlsWidget({
    super.key,
    required this.currentPlaceIndex,
    required this.tourPlaces,
    required this.visitedPlaces,
    this.tourSession,
    required this.onPlaceChanged,
    required this.onPlaceVisitedChanged,
    required this.onTourCompleted,
  });

  @override
  State<GuideControlsWidget> createState() => _GuideControlsWidgetState();
}

class _GuideControlsWidgetState extends State<GuideControlsWidget> with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.35,
          minHeight: 200,
        ),
      decoration: BoxDecoration(
        color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 25,
              offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(child: _buildCurrentPlaceControls()),
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final visitedCount = widget.visitedPlaces.where((v) => v).length;
    final totalCount = widget.tourPlaces.length;
    final progress = totalCount > 0 ? visitedCount / totalCount : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.guide.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.guide,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
              size: 20,
                  ),
          ),
          
                const SizedBox(width: 12),
          
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Guide Controls',
                        style: TextStyle(
                    fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                  '$visitedCount of $totalCount places completed',
                        style: TextStyle(
                          fontSize: 12,
                    color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
          
          // Progress circle
                Container(
            width: 40,
            height: 40,
            child: Stack(
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 3,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress == 1.0 ? Colors.green : AppColors.guide,
                      ),
                ),
                Center(
                  child: Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPlaceControls() {
    // Check if tour is completed - either by currentPlaceIndex or all places visited
    final allPlacesVisited = widget.visitedPlaces.every((visited) => visited);
    final tourCompleted = widget.currentPlaceIndex >= widget.tourPlaces.length || allPlacesVisited;
    
    if (tourCompleted) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Row(
                children: [
            const Icon(Icons.flag, color: Colors.green, size: 28),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Tour completed! All places visited.',
                        style: TextStyle(
                  fontSize: 18,
                          fontWeight: FontWeight.bold,
                  color: Colors.green,
                        ),
                      ),
            ),
            ElevatedButton(
              onPressed: widget.onTourCompleted,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                  ),
              child: const Text(
                'End Tour',
                    style: TextStyle(
                  fontSize: 16,
                      fontWeight: FontWeight.bold,
                ),
                    ),
                  ),
                ],
              ),
      );
    }
    
    final currentPlace = widget.tourPlaces[widget.currentPlaceIndex];
    final isCurrentPlaceVisited = widget.currentPlaceIndex < widget.visitedPlaces.length 
        ? widget.visitedPlaces[widget.currentPlaceIndex] 
        : false;
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current place info
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                  border: Border.all(color: AppColors.guide.withValues(alpha: 0.3)),
                  image: currentPlace.photoUrl != null
                      ? DecorationImage(
                          image: NetworkImage(currentPlace.photoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                          ),
                child: currentPlace.photoUrl == null
                    ? Icon(Icons.place, color: Colors.grey[400], size: 30)
                    : null,
                        ),
              
              const SizedBox(width: 16),
              
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentPlace.name,
                                style: const TextStyle(
                        fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                              ),
                    const SizedBox(height: 4),
                              Text(
                      'Stop ${widget.currentPlaceIndex + 1} of ${widget.tourPlaces.length}',
                                style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
              
              // Status indicator
                        Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                  color: isCurrentPlaceVisited ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCurrentPlaceVisited ? Colors.green : Colors.orange,
                    width: 2,
                          ),
                        ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                        children: [
                    Icon(
                      isCurrentPlaceVisited ? Icons.check_circle : Icons.location_on,
                      size: 18,
                      color: isCurrentPlaceVisited ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 6),
                          Text(
                      isCurrentPlaceVisited ? 'Visited' : 'Current',
                            style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isCurrentPlaceVisited ? Colors.green : Colors.orange,
                            ),
                    ),
                  ],
                ),
              ),
            ],
            ),
          
          const SizedBox(height: 20),
          
          // Action buttons
                  Row(
                    children: [
              // Mark as visited button
              if (!isCurrentPlaceVisited)
                      Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => widget.onPlaceVisitedChanged(widget.currentPlaceIndex, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                    icon: const Icon(Icons.check, size: 20),
                    label: const Text(
                      'Mark as Visited',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                )
              else
                      Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green, width: 2),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Place Visited',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                            ),
                      ],
                          ),
                        ),
                      ),
              
              // Next place button (if current is visited and not last)
              if (isCurrentPlaceVisited && widget.currentPlaceIndex < widget.tourPlaces.length - 1) ...[
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => widget.onPlaceChanged(widget.currentPlaceIndex + 1),
                          style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.guide,
                            foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  icon: const Icon(Icons.arrow_forward, size: 20),
                  label: const Text(
                    'Next',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                          ),
                        ),
              ],
            ],
                      ),
                    ],
                  ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                    ),
                    child: Row(
                      children: [
          // Tour status
                        Expanded(
            child: Row(
              children: [
                Icon(
                  widget.tourSession?.travelerOnline == true ? Icons.person : Icons.person_off,
                  size: 16,
                  color: widget.tourSession?.travelerOnline == true ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  'Traveler ${widget.tourSession?.travelerOnline == true ? 'Online' : 'Offline'}',
                            style: TextStyle(
                              fontSize: 12,
                    color: widget.tourSession?.travelerOnline == true ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
          
          // Previous place button (if not first place)
          if (widget.currentPlaceIndex > 0) ...[
            IconButton(
              onPressed: () => widget.onPlaceChanged(widget.currentPlaceIndex - 1),
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.grey[600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
            ),
          ),
              icon: const Icon(Icons.arrow_back, size: 18),
              tooltip: 'Previous place',
            ),
            const SizedBox(width: 8),
          ],
          
          // Next place button (if not last place)
          if (widget.currentPlaceIndex < widget.tourPlaces.length - 1) ...[
            IconButton(
              onPressed: () => widget.onPlaceChanged(widget.currentPlaceIndex + 1),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.guide.withValues(alpha: 0.2),
                foregroundColor: AppColors.guide,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.arrow_forward, size: 18),
              tooltip: 'Next place',
            ),
          ],
        ],
      ),
    );
  }
}