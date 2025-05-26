import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/enums/tour_category.dart';
import '../../domain/enums/tour_difficulty.dart';
import '../../domain/entities/tour.dart';
import '../../data/models/tour_request.dart';
import '../bloc/tour_bloc.dart';
import '../bloc/tour_event.dart';
import '../bloc/tour_state.dart';
import '../widgets/tour_form_field.dart';
import '../widgets/tour_category_selector.dart';
import '../widgets/tour_difficulty_selector.dart';
import '../widgets/tour_itinerary_builder.dart';
import '../widgets/tour_tags_builder.dart';
import '../widgets/tour_image_selector.dart';

/// Tour Creation Screen - Where tour magic begins! 🎨✨
class TourCreationScreen extends StatefulWidget {
  static const String routeName = '/create-tour';

  const TourCreationScreen({super.key});

  @override
  State<TourCreationScreen> createState() => _TourCreationScreenState();
}

class _TourCreationScreenState extends State<TourCreationScreen>
    with TickerProviderStateMixin {
  
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _summaryController = TextEditingController();
  final _costController = TextEditingController();
  final _durationController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  final _equipmentController = TextEditingController();
  final _safetyNotesController = TextEditingController();

  // Form state
  TourCategory _selectedCategory = TourCategory.cultural;
  TourDifficulty _selectedDifficulty = TourDifficulty.easy;
  bool _isPublic = true;
  List<String> _tags = [];
  List<String> _itineraryItems = [];
  String? _selectedImagePath;
  
  // UI state
  late TabController _tabController;
  int _currentStep = 0;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _setupFormValidation();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _summaryController.dispose();
    _costController.dispose();
    _durationController.dispose();
    _locationController.dispose();
    _maxParticipantsController.dispose();
    _equipmentController.dispose();
    _safetyNotesController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _setupFormValidation() {
    final controllers = [
      _titleController,
      _descriptionController,
      _summaryController,
      _costController,
      _durationController,
      _locationController,
    ];

    for (final controller in controllers) {
      controller.addListener(_validateForm);
    }
  }

  void _validateForm() {
    final isValid = _titleController.text.trim().isNotEmpty &&
        _descriptionController.text.trim().isNotEmpty &&
        _summaryController.text.trim().isNotEmpty &&
        _costController.text.trim().isNotEmpty &&
        _durationController.text.trim().isNotEmpty &&
        _locationController.text.trim().isNotEmpty;

    if (isValid != _isFormValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  /// Create a properly populated TourCreateRequest from form data
  TourCreateRequest _createTourRequest() {
    // Create location from form data
    final location = TourLocation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      latitude: 0.0, // TODO: Get from location picker
      longitude: 0.0, // TODO: Get from location picker
      address: _locationController.text.trim(),
      name: _locationController.text.trim(),
    );

    // Create itinerary items from string list
    final itineraryItems = _itineraryItems.asMap().entries.map((entry) {
      return TourItineraryItem(
        id: 'item_${entry.key}',
        title: entry.value,
        description: entry.value,
        duration: const Duration(hours: 1),
        order: entry.key,
      );
    }).toList();

    // Get images (convert from string path to File if available)
    final images = _selectedImagePath != null 
        ? [File(_selectedImagePath!)] 
        : <File>[];

    return TourCreateRequest(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      difficulty: _selectedDifficulty,
      images: images,
      location: location,
      estimatedDuration: double.tryParse(_durationController.text.trim()),
      estimatedCost: double.tryParse(_costController.text.trim()),
      currency: 'EUR',
      highlights: _summaryController.text.trim().isNotEmpty 
          ? [_summaryController.text.trim()] 
          : [],
      includes: _equipmentController.text.trim().isNotEmpty 
          ? _equipmentController.text.trim().split(',').map((e) => e.trim()).toList() 
          : [],
      excludes: [],
      requirements: _safetyNotesController.text.trim().isNotEmpty 
          ? _safetyNotesController.text.trim().split(',').map((e) => e.trim()).toList() 
          : [],
      itinerary: itineraryItems,
      maxGroupSize: int.tryParse(_maxParticipantsController.text.trim()) ?? 10,
      isPublic: _isPublic,
      tags: _tags,
    );
  }

  void _saveAsDraft() {
    if (!_formKey.currentState!.validate()) return;

    final request = _createTourRequest();
    context.read<TourBloc>().add(SaveAsDraftTourEvent(request: request));
  }

  void _publishTour() {
    if (!_formKey.currentState!.validate()) return;

    final request = _createTourRequest();
    context.read<TourBloc>().add(PublishTourEvent(request: request));
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
      });
      _tabController.animateTo(_currentStep);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _tabController.animateTo(_currentStep);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TourBloc, TourState>(
      listener: (context, state) {
        if (state is TourCreateSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 Tour "${state.tour.title}" created successfully!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          Navigator.of(context).pop();
        } else if (state is TourDraftSaved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📝 Draft "${state.tour.title}" saved successfully!'),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 3),
            ),
          );
          Navigator.of(context).pop();
        } else if (state is TourPublished) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🚀 Tour "${state.tour.title}" published successfully!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          Navigator.of(context).pop();
        } else if (state is TourValidationError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${state.errors.join(', ')}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        } else if (state is TourError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${state.message}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('🎨 Create Tour'),
            elevation: 0,
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            bottom: TabBar(
              controller: _tabController,
              onTap: (index) {
                setState(() {
                  _currentStep = index;
                });
              },
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(icon: Icon(Icons.info), text: 'Basic Info'),
                Tab(icon: Icon(Icons.category), text: 'Details'),
                Tab(icon: Icon(Icons.map), text: 'Itinerary'),
                Tab(icon: Icon(Icons.settings), text: 'Settings'),
              ],
            ),
          ),
          body: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              if (authState is! AuthAuthenticated) {
                return const Center(
                  child: Text(
                    '🔒 Please log in to create tours',
                    style: TextStyle(fontSize: 18),
                  ),
                );
              }

              return Form(
                key: _formKey,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBasicInfoStep(),
                    _buildDetailsStep(),
                    _buildItineraryStep(),
                    _buildSettingsStep(),
                  ],
                ),
              );
            },
          ),
          bottomNavigationBar: _buildBottomNavigationBar(state),
        );
      },
    );
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          
          // Title Field
          TourFormField(
            controller: _titleController,
            label: 'Tour Title',
            hint: 'Enter an exciting tour title...',
            icon: Icons.title,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Tour title is required';
              }
              if (value.trim().length < 3) {
                return 'Title must be at least 3 characters';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 20),
          
          // Summary Field
          TourFormField(
            controller: _summaryController,
            label: 'Quick Summary',
            hint: 'Brief description in one sentence...',
            icon: Icons.short_text,
            maxLines: 2,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Summary is required';
              }
              if (value.trim().length < 10) {
                return 'Summary must be at least 10 characters';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 20),
          
          // Description Field
          TourFormField(
            controller: _descriptionController,
            label: 'Full Description',
            hint: 'Describe your tour in detail...',
            icon: Icons.description,
            maxLines: 5,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Description is required';
              }
              if (value.trim().length < 20) {
                return 'Description must be at least 20 characters';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 20),
          
          // Category Selection
          TourCategorySelector(
            selectedCategory: _selectedCategory,
            onCategoryChanged: (category) {
              setState(() {
                _selectedCategory = category;
              });
            },
          ),
          
          const SizedBox(height: 20),
          
          // Difficulty Selection
          TourDifficultySelector(
            selectedDifficulty: _selectedDifficulty,
            onDifficultyChanged: (difficulty) {
              setState(() {
                _selectedDifficulty = difficulty;
              });
            },
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 16),
          
          // Location Field
          TourFormField(
            controller: _locationController,
            label: 'Location',
            hint: 'Where does this tour take place?',
            icon: Icons.location_on,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Location is required';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 20),
          
          Row(
            children: [
              // Cost Field
              Expanded(
                child: TourFormField(
                  controller: _costController,
                  label: 'Cost (€)',
                  hint: '0.00',
                  icon: Icons.euro,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Cost is required';
                    }
                    if (double.tryParse(value.trim()) == null) {
                      return 'Enter valid cost';
                    }
                    return null;
                  },
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Duration Field
              Expanded(
                child: TourFormField(
                  controller: _durationController,
                  label: 'Duration (hours)',
                  hint: '1',
                  icon: Icons.access_time,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Duration is required';
                    }
                    if (int.tryParse(value.trim()) == null) {
                      return 'Enter valid hours';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Max Participants
          TourFormField(
            controller: _maxParticipantsController,
            label: 'Max Participants (Optional)',
            hint: 'Leave empty for unlimited',
            icon: Icons.group,
            keyboardType: TextInputType.number,
          ),
          
          const SizedBox(height: 20),
          
          // Equipment Field
          TourFormField(
            controller: _equipmentController,
            label: 'Required Equipment (Optional)',
            hint: 'What should participants bring?',
            icon: Icons.backpack,
            maxLines: 3,
          ),
          
          const SizedBox(height: 20),
          
          // Safety Notes Field
          TourFormField(
            controller: _safetyNotesController,
            label: 'Safety Notes (Optional)',
            hint: 'Important safety information...',
            icon: Icons.security,
            maxLines: 3,
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildItineraryStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          
          Text(
            '🗺️ Tour Itinerary',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Add stops and activities for your tour',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Itinerary Items List
          TourItineraryBuilder(
            items: _itineraryItems,
            onItemsChanged: (items) {
              setState(() {
                _itineraryItems = items;
              });
            },
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSettingsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          
          Text(
            '⚙️ Tour Settings',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Visibility Setting
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Visibility',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  SwitchListTile(
                    title: Text(_isPublic ? '🌍 Public Tour' : '🔒 Private Tour'),
                    subtitle: Text(
                      _isPublic 
                          ? 'Everyone can discover and join this tour'
                          : 'Only you and invited people can see this tour',
                    ),
                    value: _isPublic,
                    onChanged: (value) {
                      setState(() {
                        _isPublic = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Tags Section
          TourTagsBuilder(
            tags: _tags,
            onTagsChanged: (tags) {
              setState(() {
                _tags = tags;
              });
            },
          ),
          
          const SizedBox(height: 20),
          
          // Image Selection
          TourImageSelector(
            selectedImagePath: _selectedImagePath,
            onImageSelected: (imagePath) {
              setState(() {
                _selectedImagePath = imagePath;
              });
            },
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(TourState state) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Previous Button
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: state is TourLoading ? null : _previousStep,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Previous'),
              ),
            ),
          
          if (_currentStep > 0) const SizedBox(width: 16),
          
          // Next/Continue Button
          if (_currentStep < 3)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: state is TourLoading ? null : _nextStep,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          
          // Save as Draft Button
          if (_currentStep == 3)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: state is TourLoading ? null : _saveAsDraft,
                icon: state is TourLoading 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  state is TourLoading 
                      ? 'Saving...' 
                      : 'Save as Draft',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          
          if (_currentStep == 3) const SizedBox(width: 16),
          
          // Publish Button
          if (_currentStep == 3)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: state is TourLoading 
                    ? null 
                    : _publishTour,
                icon: state is TourLoading 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.publish),
                label: Text(
                  state is TourLoading 
                      ? 'Publishing...' 
                      : 'Publish Tour',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }
}