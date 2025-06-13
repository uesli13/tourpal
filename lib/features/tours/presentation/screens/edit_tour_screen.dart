import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/tour_duration_calculator.dart';
import '../../../../models/tour_plan.dart';
import '../../../../models/place.dart';
import '../bloc/tour_creation_bloc.dart';
import '../bloc/tour_creation_event.dart';
import '../bloc/tour_creation_state.dart';
import '../widgets/tour_info_step.dart';
import '../widgets/tour_places_step.dart';
import 'tour_preview_screen.dart';

class EditTourScreen extends StatefulWidget {
  final TourPlan tourPlan;
  
  const EditTourScreen({
    super.key,
    required this.tourPlan,
  });

  @override
  State<EditTourScreen> createState() => _EditTourScreenState();
}

class _EditTourScreenState extends State<EditTourScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  int _currentStep = 0;
  final int _totalSteps = 2;

  // Tour data - pre-populated from existing tour
  late String _tourTitle;
  late String _tourDescription;
  File? _tourCoverImage;
  late List<Map<String, dynamic>> _places;
  late double? _price;
  late String? _difficulty;
  late List<String> _tags;

  // Track if data has been modified
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    
    // Pre-populate with existing tour data
    _initializeFromExistingTour();
  }

  void _initializeFromExistingTour() {
    _tourTitle = widget.tourPlan.title;
    _tourDescription = widget.tourPlan.description ?? '';
    _price = widget.tourPlan.price.toDouble();
    _difficulty = widget.tourPlan.difficulty;
    _tags = List<String>.from(widget.tourPlan.tags ?? []);
    
    // Convert places to the format expected by the UI
    // Important: Properly handle photoUrl restoration for UI compatibility
    _places = widget.tourPlan.places.map((place) => {
      'id': place.id,
      'name': place.name,
      'location': place.location,
      'address': place.address,
      'description': place.description,
      'stayingDuration': place.stayingDuration,
      // For UI compatibility: use photoUrl as image if it exists
      if (place.photoUrl != null && place.photoUrl!.isNotEmpty) 
        'image': place.photoUrl,
      'photoUrl': place.photoUrl, // Keep original for backend compatibility
    }).toList();

    // Debug log to verify initialization
    debugPrint('EditTour: Initialized with ${_places.length} places');
    debugPrint('EditTour: Cover image URL: ${widget.tourPlan.coverImageUrl}');
    debugPrint('EditTour: Tags: $_tags');
    
    // Verify place images restoration
    for (int i = 0; i < _places.length; i++) {
      final place = _places[i];
      debugPrint('EditTour: Place ${i + 1} (${place['name']}) - image: ${place['image']}, photoUrl: ${place['photoUrl']}');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        final shouldExit = await _showExitDialog();
        if (shouldExit) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: BlocListener<TourCreationBloc, TourCreationState>(
          listener: (context, state) {
            if (state is TourCreationSuccess) {
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
              Navigator.of(context).pop(state.tourId);
            } else if (state is TourDraftSavedState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Tour saved as draft'),
                  backgroundColor: Colors.orange,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
              Navigator.of(context).pop(state.tourId);
            } else if (state is TourCreationError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }
          },
          child: Column(
            children: [
              _buildAppBar(),
              _buildProgressIndicator(),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      TourInfoStep(
                        title: _tourTitle,
                        description: _tourDescription,
                        coverImage: _tourCoverImage,
                        imageUrl: widget.tourPlan.coverImageUrl,
                        price: _price,
                        difficulty: _difficulty,
                        tags: _tags,
                        onDataChanged: _onTourInfoChanged,
                        onNext: _goToStep2,
                        canProceed: _canProceedToStep2(),
                      ),
                      TourPlacesStep(
                        tourTitle: _tourTitle,
                        tourDescription: _tourDescription,
                        tourImagePath: _tourCoverImage?.path,
                        places: _places,
                        onPlacesChanged: _onPlacesChanged,
                        onPublish: _updateTour,
                        onBack: _goToPreviousStep,
                        onSaveDraft: _saveDraft,
                        canPublish: _canPublish(),
                        isPublishing: context.watch<TourCreationBloc>().state is TourPublishingState,
                        isSavingDraft: context.watch<TourCreationBloc>().state is TourSavingDraftState,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () async {
              final shouldExit = await _showExitDialog();
              if (shouldExit) {
                Navigator.of(context).pop();
              }
            },
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: .2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Edit Tour',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _getStepTitle(),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: .9),
                  ),
                ),
              ],
            ),
          ),
          if (_hasUnsavedChanges)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Modified',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 8),
          if (_currentStep > 0)
            IconButton(
              onPressed: _goToPreviousStep,
              icon: const Icon(Icons.skip_previous, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: .2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          IconButton(
            onPressed: _previewTour,
            icon: const Icon(Icons.preview, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: .2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: List.generate(_totalSteps, (index) {
              final isActive = index <= _currentStep;
              final isCompleted = index < _currentStep;
              
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: index < _totalSteps - 1 ? 8 : 0,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 6,
                          decoration: BoxDecoration(
                            color: isActive ? AppColors.primary : Colors.grey[300],
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: isActive ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: .3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ] : null,
                          ),
                        ),
                      ),
                      if (index < _totalSteps - 1) ...[
                        const SizedBox(width: 8),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isCompleted ? AppColors.primary : Colors.grey[300],
                            shape: BoxShape.circle,
                            boxShadow: isCompleted ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: .3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ] : null,
                          ),
                          child: Icon(
                            isCompleted ? Icons.check : Icons.circle,
                            size: 12,
                            color: isCompleted ? Colors.white : Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tour Info',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: _currentStep == 0 ? FontWeight.bold : FontWeight.normal,
                    color: _currentStep == 0 ? AppColors.primary : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  'Edit Places',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: _currentStep == 1 ? FontWeight.bold : FontWeight.normal,
                    color: _currentStep == 1 ? AppColors.primary : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Update tour information and cover photo';
      case 1:
        return 'Edit places and itinerary';
      default:
        return '';
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentStep = index;
    });
    _animationController.reset();
    _animationController.forward();
  }

  void _onTourInfoChanged({
    String? title,
    String? description,
    File? coverImage,
    double? price,
    String? difficulty,
    List<String>? tags,
  }) {
    setState(() {
      if (title != null) _tourTitle = title;
      if (description != null) _tourDescription = description;
      if (coverImage != null) _tourCoverImage = coverImage;
      if (price != null) _price = price;
      if (difficulty != null) _difficulty = difficulty;
      if (tags != null) _tags = tags;
      _hasUnsavedChanges = true;
    });

    // Validate data
    context.read<TourCreationBloc>().add(ValidateTourDataEvent(
      title: _tourTitle,
      description: _tourDescription,
      coverImage: _tourCoverImage,
      places: _places,
    ));
  }

  void _onPlacesChanged(List<Map<String, dynamic>> places) {
    setState(() {
      _places = places;
      _hasUnsavedChanges = true;
    });

    // Validate data
    context.read<TourCreationBloc>().add(ValidateTourDataEvent(
      title: _tourTitle,
      description: _tourDescription,
      coverImage: _tourCoverImage,
      places: _places,
    ));
  }

  bool _canProceedToStep2() {
    return _tourTitle.trim().isNotEmpty &&
        _tourDescription.trim().isNotEmpty;
  }

  bool _canPublish() {
    return _canProceedToStep2() && _places.length >= 2;
  }

  void _goToStep2() {
    if (_canProceedToStep2()) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _updateTour() {
    if (_canPublish()) {
      // Use UpdateTourEvent instead of CreateTourEvent
      context.read<TourCreationBloc>().add(UpdateTourEvent(
        tourId: widget.tourPlan.id,
        title: _tourTitle,
        description: _tourDescription,
        coverImage: _tourCoverImage,
        places: _places,
        price: _price,
        difficulty: _difficulty,
        tags: _tags,
        status: widget.tourPlan.status, // Preserve existing status unless explicitly changed
      ));
    }
  }

  void _saveDraft() {
    if (_tourTitle.trim().isNotEmpty) {
      context.read<TourCreationBloc>().add(UpdateTourEvent(
        tourId: widget.tourPlan.id,
        title: _tourTitle,
        description: _tourDescription,
        coverImage: _tourCoverImage,
        places: _places,
        price: _price,
        difficulty: _difficulty,
        tags: _tags,
        status: TourStatus.draft, // Explicitly save as draft
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a tour title to save changes'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _previewTour() async {
    // Convert places data to Place objects
    final previewPlaces = _places.map((placeData) => Place(
      id: placeData['id']?.toString() ?? 'place-${DateTime.now().millisecondsSinceEpoch}',
      name: placeData['name']?.toString() ?? 'Unnamed Place',
      location: placeData['location'] as GeoPoint? ?? const GeoPoint(40.6333, -8.6594),
      address: placeData['address']?.toString(),
      description: placeData['description']?.toString(),
      photoUrl: placeData['photoUrl']?.toString(),
      stayingDuration: placeData['stayingDuration'] as int? ?? 30,
    )).toList();

    // Calculate proper duration including walking time + staying time
    final calculatedDuration = previewPlaces.isNotEmpty 
        ? await TourDurationCalculator.calculateTotalDuration(previewPlaces)
        : widget.tourPlan.duration.toDouble(); // Fallback to original duration

    // Create updated TourPlan for preview with calculated duration
    final previewTourPlan = widget.tourPlan.copyWith(
      title: _tourTitle,
      description: _tourDescription,
      duration: calculatedDuration, // Now includes walking time + staying time
      price: _price,
      difficulty: _difficulty,
      tags: _tags,
      places: previewPlaces,
      updatedAt: Timestamp.now(),
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TourPreviewScreen(
          tourPlan: previewTourPlan,
          places: previewPlaces,
        ),
      ),
    );
  }

  Future<bool> _showExitDialog() async {
    if (!_hasUnsavedChanges) {
      return true;
    }

    return (await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Unsaved Changes'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('You have unsaved changes to this tour. What would you like to do?'),
            const SizedBox(height: 16),
            Text('• Tour: ${_tourTitle}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            if (_places.isNotEmpty) ...[
              Text('• ${_places.length} place(s)', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continue Editing'),
          ),
          if (_tourTitle.trim().isNotEmpty) ...[
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(true);
                _saveDraft();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.orange,
              ),
              child: const Text('Save Changes & Exit'),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Exit Without Saving'),
          ),
        ],
      ),
    )) ?? false;
  }
}