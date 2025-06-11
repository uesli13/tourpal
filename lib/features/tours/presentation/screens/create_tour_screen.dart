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

class CreateTourScreen extends StatefulWidget {
  const CreateTourScreen({super.key});

  @override
  State<CreateTourScreen> createState() => _CreateTourScreenState();
}

class _CreateTourScreenState extends State<CreateTourScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  int _currentStep = 0;
  final int _totalSteps = 2;

  // Tour data
  String _tourTitle = '';
  String _tourDescription = '';
  File? _tourCoverImage;
  List<Map<String, dynamic>> _places = [];
  double? _price;
  String? _difficulty;
  List<String> _tags = [];

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
      canPop: false, // Prevent default back behavior
      onPopInvoked: (didPop) async {
        if (didPop) return;
        
        // Show draft save dialog when back button is pressed
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
                  content: Text(state.message),
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
                  content: Text(state.message),
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
                        onPublish: _publishTour,
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
                  'Create New Tour',
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
                  'Add Places',
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
        return 'Basic information and cover photo';
      case 1:
        return 'Add amazing places to visit';
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
        _tourDescription.trim().isNotEmpty &&
        _tourCoverImage != null;
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

  void _publishTour() {
    if (_canPublish()) {
      context.read<TourCreationBloc>().add(CreateTourEvent(
        title: _tourTitle,
        description: _tourDescription,
        coverImage: _tourCoverImage,
        places: _places,
        price: _price,
        difficulty: _difficulty,
        tags: _tags,
      ));
    }
  }

  void _saveDraft() {
    // Save tour as draft - can be saved with minimal data
    if (_tourTitle.trim().isNotEmpty) {
      context.read<TourCreationBloc>().add(SaveDraftEvent(
        title: _tourTitle,
        description: _tourDescription,
        coverImage: _tourCoverImage,
        places: _places,
        price: _price,
        difficulty: _difficulty,
        tags: _tags,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a tour title to save as draft'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _previewTour() async {
    // Check if we have enough data for a meaningful preview
    if (_tourTitle.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a tour title first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Convert places data to Place objects first
    final previewPlaces = _places.isEmpty 
        ? _createSamplePlaces() 
        : _places.map((placeData) => Place(
            id: placeData['id']?.toString() ?? 'place-${DateTime.now().millisecondsSinceEpoch}',
            name: placeData['name']?.toString() ?? 'Unnamed Place',
            location: placeData['location'] as GeoPoint? ?? const GeoPoint(40.6333, -8.6594), // Coimbra fallback
            address: placeData['address']?.toString(),
            description: placeData['description']?.toString(),
            photoUrl: placeData['photoUrl']?.toString(),
            stayingDuration: placeData['stayingDuration'] as int? ?? 30,
          )).toList();

    // Calculate proper duration including walking time + staying time
    final calculatedDuration = previewPlaces.isNotEmpty 
        ? await TourDurationCalculator.calculateTotalDuration(previewPlaces)
        : 2.0; // Default for empty tours

    // Create a temporary TourPlan for preview
    final previewTourPlan = TourPlan(
      id: 'preview-tour-${DateTime.now().millisecondsSinceEpoch}',
      guideId: 'current-guide-id',
      title: _tourTitle.isNotEmpty ? _tourTitle : 'Untitled Tour',
      description: _tourDescription.isNotEmpty ? _tourDescription : 'Tour description coming soon...',
      duration: calculatedDuration, // Now includes walking time + staying time
      difficulty: _difficulty ?? 'easy',
      price: _price ?? 25.0,
      tags: _tags.isNotEmpty ? _tags : ['walking', 'sightseeing'],
      category: 'general', // Default category for preview
      location: _places.isNotEmpty && _places.first['address'] != null 
          ? _places.first['address'].toString() 
          : 'Coimbra, Portugal', // Default location
      createdAt: Timestamp.now(),
      status: TourStatus.draft,
      places: previewPlaces,
      coverImageUrl: null,
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

  List<Place> _createSamplePlaces() {
    // Create sample places around Coimbra for demonstration when no places are added yet
    return [
      Place(
        id: 'sample-1',
        name: 'Sample Location 1',
        location: const GeoPoint(40.6331, -8.6594),
        address: 'Coimbra, Portugal',
        description: 'This is where your first place will appear. Add places in step 2!',
        stayingDuration: 30,
      ),
      Place(
        id: 'sample-2',
        name: 'Sample Location 2',
        location: const GeoPoint(40.6357, -8.6563),
        address: 'Coimbra, Portugal',
        description: 'This is where your second place will appear. Add places in step 2!',
        stayingDuration: 30,
      ),
    ];
  }

  Future<bool> _showExitDialog() async {
    // Check if there's any data worth saving
    final hasData = _tourTitle.trim().isNotEmpty || 
                   _tourDescription.trim().isNotEmpty || 
                   _tourCoverImage != null || 
                   _places.isNotEmpty;

    if (!hasData) {
      // No data to save, just exit
      return true;
    }

    // Show a dialog to confirm exit and offer to save draft
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
            const Text('You have unsaved changes. What would you like to do?'),
            const SizedBox(height: 16),
            if (_tourTitle.trim().isNotEmpty) ...[
              Text('• Tour: ${_tourTitle}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
            if (_places.isNotEmpty) ...[
              Text('• ${_places.length} place(s) added', style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
              child: const Text('Save Draft & Exit'),
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