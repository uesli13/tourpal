import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../screens/add_place_screen.dart';

class TourPlacesStep extends StatefulWidget {
  final String tourTitle;
  final String tourDescription;
  final String? tourImagePath;
  final List<Map<String, dynamic>> places;
  final Function(List<Map<String, dynamic>>) onPlacesChanged;
  final VoidCallback onPublish;
  final VoidCallback? onBack; 
  final VoidCallback? onSaveDraft;
  final bool canPublish;
  final bool isPublishing;
  final bool isSavingDraft;

  const TourPlacesStep({
    super.key,
    required this.tourTitle,
    required this.tourDescription,
    this.tourImagePath,
    required this.places,
    required this.onPlacesChanged,
    required this.onPublish,
    this.onBack,
    this.onSaveDraft,
    required this.canPublish,
    this.isPublishing = false,
    this.isSavingDraft = false,
  });

  @override
  State<TourPlacesStep> createState() => _TourPlacesStepState();
}

class _TourPlacesStepState extends State<TourPlacesStep>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundLight,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ADD PLACE BUTTON
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _addPlace,
                          icon: const Icon(Icons.add_location_alt, size: 20),
                          label: const Text(
                            'Add Place',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textOnPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // PLACES LIST OR EMPTY STATE
                      if (widget.places.isEmpty)
                        _buildEmptyState()
                      else
                        _buildPlacesList(),
                      
                      const SizedBox(height: 100), // Space for floating button
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Bottom action buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Back button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: (widget.isPublishing || widget.isSavingDraft) ? null : widget.onBack,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Save Draft button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: (widget.isPublishing || widget.isSavingDraft) ? null : widget.onSaveDraft,
                    icon: widget.isSavingDraft 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2)
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(widget.isSavingDraft ? 'Saving...' : 'Save Draft'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      foregroundColor: widget.isSavingDraft ? AppColors.gray400 : AppColors.actionSave,
                      side: BorderSide(color: widget.isSavingDraft ? AppColors.gray400 : AppColors.actionSave),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Publish button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (widget.canPublish && !widget.isPublishing && !widget.isSavingDraft) ? widget.onPublish : null,
                    icon: widget.isPublishing 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.textOnPrimary),
                            )
                          )
                        : const Icon(Icons.publish),
                    label: Text(widget.isPublishing ? 'Publishing...' : 'Publish Tour'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.canPublish && !widget.isPublishing && !widget.isSavingDraft 
                          ? AppColors.actionPublish 
                          : AppColors.gray400,
                      foregroundColor: AppColors.textOnPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.surfaceOverlay(),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER ROW
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primarySubtle(),
                  AppColors.secondarySubtle(),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryMedium()),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.tourTitle.isNotEmpty ? widget.tourTitle : 'Your Tour',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        'Add amazing places to your tour',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primarySubtle(),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryMedium()),
                  ),
                  child: Text(
                    '${widget.places.length}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primarySubtle(),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryLight,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Add at least 2 places to create your tour. You can reorder them by dragging.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
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

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.surfaceOverlay(),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primarySubtle(),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primaryMedium()),
            ),
            child: const Icon(
              Icons.add_location_alt,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No places added yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add at least 2 places to create your tour',
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

  Widget _buildPlacesList() {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.places.length,
      onReorder: _reorderPlaces,
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (BuildContext context, Widget? child) {
            final double animValue = Curves.easeInOut.transform(animation.value);
            final double elevation = lerpDouble(0, 8, animValue)!;
            final double scale = lerpDouble(1, 1.02, animValue)!;
            return Transform.scale(
              scale: scale,
              child: Material(
                elevation: elevation,
                borderRadius: BorderRadius.circular(16),
                shadowColor: AppColors.primaryMedium(),
                child: child!,
              ),
            );
          },
          child: child,
        );
      },
      itemBuilder: (context, index) {
        final place = widget.places[index];
        return _buildPlaceCard(place, index);
      },
    );
  }

  Widget _buildPlaceCard(Map<String, dynamic> place, int index) {
    // Get single photo (support both old and new field names)
    String? photo;
    if (place['image'] != null) {
      photo = place['image'];
    } else if (place['photoUrl'] != null) {
      photo = place['photoUrl'];
    }

    return Container(
      key: ValueKey(place['id']),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.surfaceElevated(),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER ROW WITH DRAG HANDLE
            Row(
              children: [
                // DRAG HANDLE
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.drag_handle,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                
                // ORDER NUMBER
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryMedium(),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // PLACE INFO
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showPlaceDetails(place),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place['name'] ?? 'Unnamed Place',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          place['address'] ?? 'No address available',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (place['stayingDuration'] != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.secondarySubtle(),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '⏱️ ${place['stayingDuration']} minutes',
                                  style: const TextStyle(
                                    color: AppColors.secondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                // DELETE BUTTON
                IconButton(
                  onPressed: () => _removePlace(index),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 24,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.errorOverlay(),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            
            // PHOTO PREVIEW - Single photo
            if (photo != null) ...[
              const SizedBox(height: 16),
              _buildPhotoPreview(photo),
            ],
            
            // ACTION BUTTONS
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.camera_alt,
                    label: photo == null ? 'Add Photo' : 'Change Photo',
                    color: Colors.green,
                    onPressed: () => _attachPhoto(index),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.edit,
                    label: 'Edit Details',
                    color: Colors.blue,
                    onPressed: () => _editPlace(index),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPreview(String photo) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildImageWidget(photo),
      ),
    );
  }

  Widget _buildImageWidget(String imagePath) {
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: AppColors.gray200,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
                color: AppColors.secondary,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          color: AppColors.gray200,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, color: AppColors.textSecondary, size: 32),
              SizedBox(height: 8),
              Text(
                'Image not available',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    } else {
      return Image.file(
        File(imagePath),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[200],
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, color: Colors.grey, size: 32),
              SizedBox(height: 8),
              Text(
                'Image not found',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _reorderPlaces(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = widget.places.removeAt(oldIndex);
    widget.places.insert(newIndex, item);
    widget.onPlacesChanged(widget.places);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📍 Place moved to position ${newIndex + 1}'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _addPlace() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddPlaceScreen(),
      ),
    );
    
    if (result != null) {
      widget.places.add(result);
      widget.onPlacesChanged(widget.places);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Added "${result['name']}" to your tour!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _editPlace(int index) async {
    final place = widget.places[index];
    final result = await _showEditPlaceDialog(place);
    
    if (result != null) {
      widget.places[index] = {...widget.places[index], ...result};
      widget.onPlacesChanged(widget.places);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✏️ Place updated!'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _removePlace(int index) {
    final placeName = widget.places[index]['name'];
    widget.places.removeAt(index);
    widget.onPlacesChanged(widget.places);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🗑️ Removed "$placeName"'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _attachPhoto(int placeIndex) async {
    final ImagePicker picker = ImagePicker();
    
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        // Update place with single image
        widget.places[placeIndex]['image'] = image.path;
        // Remove old photoUrl field if it exists
        widget.places[placeIndex].remove('photoUrl');
        
        widget.onPlacesChanged(widget.places);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📸 Added photo to "${widget.places[placeIndex]['name']}"'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showPlaceDetails(Map<String, dynamic> place) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // HEADER
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        place['name'] ?? 'Unnamed Place',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              
              // CONTENT
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // PHOTO
                      if (place['image'] != null || place['photoUrl'] != null) ...[
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: place['image'] != null
                                ? Image.file(
                                    File(place['image']),
                                    fit: BoxFit.cover,
                                  )
                                : place['photoUrl'] != null
                                    ? Image.network(
                                        place['photoUrl'],
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => 
                                            const Icon(Icons.broken_image),
                                      )
                                    : const Icon(Icons.image),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      
                      // DESCRIPTION
                      if (place['description'] != null && place['description'].toString().isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primarySubtle(),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primaryLightOverlay()),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.description, color: AppColors.primary, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Description',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                place['description'].toString(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // TIME TO SPEND
                      if (place['stayingDuration'] != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.secondarySubtle(),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.secondaryLightOverlay()),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time, color: AppColors.secondary, size: 20),
                              const SizedBox(width: 12),
                              Text(
                                'Time to spend: ${place['stayingDuration']} minutes',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // ADDRESS
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.place, color: AppColors.primary, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Address',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    place['address'] ?? 'No address available',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // ACTION BUTTONS
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _editPlace(widget.places.indexOf(place));
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        label: const Text('Close'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      )
    );
  }

  Future<Map<String, dynamic>?> _showEditPlaceDialog(Map<String, dynamic> place) async {
    final nameController = TextEditingController(text: place['name'] ?? '');
    final descriptionController = TextEditingController(text: place['description'] ?? '');
    final durationController = TextEditingController(
      text: place['stayingDuration']?.toString() ?? '30'
    );

    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // HEADER
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.edit_location, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Edit Place Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // FORM
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: 'Place Name *',
                            hintText: 'Enter place name',
                            prefixIcon: const Icon(Icons.place),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          textCapitalization: TextCapitalization.words,
                          maxLength: 50,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        TextField(
                          controller: descriptionController,
                          decoration: InputDecoration(
                            labelText: 'Description (Optional)',
                            hintText: 'Describe this place...',
                            prefixIcon: const Icon(Icons.description),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          maxLines: 3,
                          maxLength: 200,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        TextField(
                          controller: durationController,
                          decoration: InputDecoration(
                            labelText: 'Time to Spend (minutes)',
                            hintText: '30',
                            prefixIcon: const Icon(Icons.access_time),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            suffixText: 'min',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // BUTTONS
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                          side: BorderSide(color: Colors.grey[400]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final name = nameController.text.trim();
                          final description = descriptionController.text.trim();
                          final duration = int.tryParse(durationController.text.trim()) ?? 30;
                          
                          if (name.isNotEmpty) {
                            Navigator.of(context).pop({
                              'name': name,
                              'description': description,
                              'stayingDuration': duration,
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      ),
    );
  }
}