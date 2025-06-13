import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/logger.dart';
import '../../../../models/tour_journal.dart';
import '../../../../models/journal_entry.dart';
import '../../../../models/place.dart';
import '../../services/tour_journal_service.dart';

class TourJournalWidget extends StatefulWidget {
  final TourJournal? tourJournal;
  final List<Place> tourPlaces;
  final List<bool> visitedPlaces;
  final int currentPlaceIndex;
  final Function(TourJournal) onJournalUpdated;
  final VoidCallback? onClose;

  const TourJournalWidget({
    super.key,
    this.tourJournal,
    required this.tourPlaces,
    required this.visitedPlaces,
    required this.currentPlaceIndex,
    required this.onJournalUpdated,
    this.onClose,
  });

  @override
  State<TourJournalWidget> createState() => _TourJournalWidgetState();
}

class _TourJournalWidgetState extends State<TourJournalWidget> with TickerProviderStateMixin {
  late final TourJournalService _journalService;
  late TabController _tabController;
  final TextEditingController _noteController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  
  int _selectedPlaceIndex = 0;
  double _currentRating = 0.0;
  List<File> _selectedImages = [];
  bool _isLoading = false;
  
  // Animation controllers
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _journalService = TourJournalService();
    
    // Initialize with current place or first visited place
    _selectedPlaceIndex = _findBestInitialPlace();
    
    _tabController = TabController(
      length: 3, // Overview, Current Place, All Places
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _slideController.forward();
    _loadPlaceData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _slideController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  int _findBestInitialPlace() {
    // Start with current place if it's visited, otherwise find last visited place
    if (widget.currentPlaceIndex < widget.visitedPlaces.length && 
        widget.visitedPlaces[widget.currentPlaceIndex]) {
      return widget.currentPlaceIndex;
    }
    
    // Find the last visited place
    for (int i = widget.visitedPlaces.length - 1; i >= 0; i--) {
      if (widget.visitedPlaces[i]) {
        return i;
      }
    }
    
    return 0; // Fallback to first place
  }

  void _loadPlaceData() {
    if (_selectedPlaceIndex < widget.tourPlaces.length) {
      final place = widget.tourPlaces[_selectedPlaceIndex];
      final entry = widget.tourJournal?.entries
          .where((e) => e.placeId == place.id)
          .firstOrNull;
      
      if (entry != null) {
        _noteController.text = entry.content;
        // Use metadata for rating if available
        _currentRating = (entry.metadata['rating'] as num?)?.toDouble() ?? 0.0;
        // Load images if available
        _selectedImages.clear();
        // Note: This would require implementing image loading from URLs
      } else {
        _noteController.clear();
        _currentRating = 0.0;
        _selectedImages.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildCurrentPlaceTab(),
                  _buildAllPlacesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
            child: Icon(
              Icons.book,
              color: AppColors.primary,
              size: 24,
            ),
                    ),
          
                    const SizedBox(width: 12),
          
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tour Journal',
                            style: TextStyle(
                    fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                            Text(
                  'Capture your tour memories',
                              style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
          
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(Icons.close),
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
                        decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
                        ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Current Place'),
          Tab(text: 'All Places'),
                    ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final visitedCount = widget.visitedPlaces.where((v) => v).length;
    final totalEntries = widget.tourJournal?.entries.length ?? 0;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistics cards
                  Row(
                    children: [
                      Expanded(
                child: _buildStatCard(
                  'Places Visited',
                  '$visitedCount/${widget.tourPlaces.length}',
                  Icons.place,
                  AppColors.primary,
                        ),
                      ),
              const SizedBox(width: 12),
                      Expanded(
                child: _buildStatCard(
                  'Journal Entries',
                  '$totalEntries',
                  Icons.edit_note,
                  Colors.green,
                        ),
                      ),
                    ],
                  ),
          
          const SizedBox(height: 24),
          
          // Recent entries
          const Text(
            'Recent Entries',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          
          const SizedBox(height: 16),
          
          if (widget.tourJournal?.entries.isEmpty ?? true)
            _buildEmptyState()
          else
            ..._buildRecentEntries(),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
                        ),
                      ),
                  Text(
            title,
                    style: TextStyle(
                      fontSize: 12,
              color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
        ],
      ),
    );
  }

  List<Widget> _buildRecentEntries() {
    final recentEntries = widget.tourJournal?.entries
        .where((entry) => entry.content.isNotEmpty)
        .take(3)
        .toList() ?? [];
    
    if (recentEntries.isEmpty) {
      return [_buildEmptyState()];
    }
    
    return recentEntries.map((entry) {
      final place = widget.tourPlaces.firstWhere(
        (p) => p.id == entry.placeId,
        orElse: () => Place(
          id: entry.placeId,
          name: 'Unknown Place',
          location: const GeoPoint(0, 0),
        ),
      );
      
      final rating = (entry.metadata['rating'] as num?)?.toDouble() ?? 0.0;
      
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    place.name,
              style: const TextStyle(
                      fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
                  ),
                ),
                _buildRatingStars(rating, size: 16),
              ],
            ),
            
            if (entry.content.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                entry.content,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
            ),
            ],
            
            const SizedBox(height: 8),
            
            Text(
              'Added ${_formatDateTime(entry.timestamp)}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              ),
          ],
            ),
      );
    }).toList();
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
                children: [
          Icon(
            Icons.book_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No journal entries yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Visit places and add your thoughts to create memories!',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
                      ),
            textAlign: TextAlign.center,
                  ),
                ],
              ),
    );
  }

  Widget _buildCurrentPlaceTab() {
    if (_selectedPlaceIndex >= widget.tourPlaces.length) {
      return const Center(child: Text('No place selected'));
    }
    
    final place = widget.tourPlaces[_selectedPlaceIndex];
    final isVisited = _selectedPlaceIndex < widget.visitedPlaces.length && 
                     widget.visitedPlaces[_selectedPlaceIndex];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Place info
          _buildPlaceHeader(place, isVisited),
          
          const SizedBox(height: 24),
          
          if (isVisited) ...[
            // Rating section
            _buildRatingSection(),
            
            const SizedBox(height: 24),
            
            // Notes section
            _buildNotesSection(),
            
            const SizedBox(height: 24),
            
            // Photos section
            _buildPhotosSection(),
            
            const SizedBox(height: 32),
            
            // Save button
            _buildSaveButton(),
          ] else ...[
            _buildNotVisitedMessage(),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaceHeader(Place place, bool isVisited) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isVisited ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isVisited ? Colors.green.withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.3),
          ),
      ),
      child: Row(
            children: [
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
          
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                  place.name,
                  style: const TextStyle(
                    fontSize: 18,
                        fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                      ),
                    ),
                
                const SizedBox(height: 4),
                
                Row(
                  children: [
                    Icon(
                      isVisited ? Icons.check_circle : Icons.schedule,
                      size: 16,
                      color: isVisited ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isVisited ? 'Visited' : 'Not visited yet',
                      style: TextStyle(
                        fontSize: 14,
                        color: isVisited ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w500,
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

  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How was this place?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            _buildRatingStars(_currentRating, onRatingChanged: (rating) {
              setState(() {
                _currentRating = rating;
              });
            }),
            
            const SizedBox(width: 12),
            
            Text(
              _getRatingText(_currentRating),
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingStars(double rating, {Function(double)? onRatingChanged, double size = 24}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: onRatingChanged != null ? () => onRatingChanged(index + 1.0) : null,
          child: Icon(
            index < rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: size,
          ),
        );
      }),
    );
  }

  String _getRatingText(double rating) {
    if (rating == 0) return 'Not rated';
    if (rating <= 1) return 'Poor';
    if (rating <= 2) return 'Fair';
    if (rating <= 3) return 'Good';
    if (rating <= 4) return 'Very Good';
    return 'Excellent';
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your thoughts and memories',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
                ),
          ),
        
          const SizedBox(height: 12),
          
        TextField(
          controller: _noteController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'What did you think about this place? Any special memories?',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Photos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          
            const Spacer(),
            
            TextButton.icon(
              onPressed: _addPhoto,
              icon: const Icon(Icons.add_a_photo, size: 20),
              label: const Text('Add Photo'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
        
            const SizedBox(height: 12),
        
        if (_selectedImages.isEmpty)
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_camera, color: Colors.grey[400], size: 32),
                const SizedBox(height: 8),
                Text(
                  'No photos added yet',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          )
        else
            SizedBox(
            height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                  return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: Stack(
                    children: [
                      ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImages[index],
                          width: 100,
                          height: 100,
                        fit: BoxFit.cover,
                      ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removePhoto(index),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                    ),
                  );
                },
              ),
            ),
          ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveJournalEntry,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Save Entry',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildNotVisitedMessage() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.location_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Place not visited yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Visit this place during your tour to add journal entries.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAllPlacesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.tourPlaces.length,
      itemBuilder: (context, index) {
        final place = widget.tourPlaces[index];
        final isVisited = widget.visitedPlaces.contains(place.id);
        final entry = widget.tourJournal?.entries
            .where((e) => e.placeId == place.id)
            .firstOrNull;
        
        final rating = entry != null 
            ? (entry.metadata['rating'] as num?)?.toDouble() ?? 0.0
            : 0.0;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isVisited ? Colors.green : Colors.grey[300],
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: isVisited ? Colors.white : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              place.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (entry != null) ...[
                  const SizedBox(height: 4),
                  _buildRatingStars(rating, size: 16),
                  if (entry.content.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      entry.content,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ] else if (isVisited) ...[
                  const SizedBox(height: 4),
                  Text(
                    'No journal entry yet',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ] else ...[
                  const SizedBox(height: 4),
                  Text(
                    'Not visited',
                    style: TextStyle(color: Colors.orange),
                  ),
                ],
              ],
            ),
            trailing: isVisited
                ? IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedPlaceIndex = index;
                        _tabController.animateTo(1); // Switch to Current Place tab
                      });
                      _loadPlaceData();
                    },
                    icon: Icon(
                      entry != null ? Icons.edit : Icons.add,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }

  Future<void> _addPhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      }
    } catch (e) {
      AppLogger.logInfo('Error picking image: $e');
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _saveJournalEntry() async {
    if (_selectedPlaceIndex >= widget.tourPlaces.length) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final place = widget.tourPlaces[_selectedPlaceIndex];
      
      // Create or update journal entry with rating in metadata
      final entry = JournalEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        placeId: place.id,
        type: 'note',
        content: _noteController.text.trim(),
        timestamp: DateTime.now(),
        imageUrls: [], // TODO: Upload images and get URLs
        metadata: {
          'rating': _currentRating,
        },
      );
      
      // Update journal
      if (widget.tourJournal != null) {
        await _journalService.addJournalEntry(
          journalId: widget.tourJournal!.id,
          placeId: place.id,
          type: 'note',
          content: _noteController.text.trim(),
          imageUrls: [],
        );
        
        // Create updated journal with new entry
        final updatedEntries = List<JournalEntry>.from(widget.tourJournal!.entries);
        final existingIndex = updatedEntries.indexWhere((e) => e.placeId == place.id);
        
        if (existingIndex >= 0) {
          updatedEntries[existingIndex] = entry;
        } else {
          updatedEntries.add(entry);
        }
        
        final updatedJournal = widget.tourJournal!.copyWith(
          entries: updatedEntries,
          updatedAt: DateTime.now(),
        );
        
        widget.onJournalUpdated(updatedJournal);
      }
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('Journal entry saved for ${place.name}'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving journal entry: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
