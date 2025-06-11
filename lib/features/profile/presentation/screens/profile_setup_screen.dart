import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/logger.dart';
import '../../../../models/user.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class ProfileSetupScreen extends StatefulWidget {
  final VoidCallback? onComplete;
  const ProfileSetupScreen({super.key, this.onComplete});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  
  DateTime? _selectedBirthdate;
  File? _profileImage;
  int _currentStep = 0;
  bool _isLoading = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
    
    _initializeUserData();
  }

  void _initializeUserData() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final user = authState.user;
      _nameController.text = user.name;
      if (user.bio != null) {
        _bioController.text = user.bio!;
      }
      // Initialize birthdate if imported from Google profile
      if (user.birthdate != null) {
        _selectedBirthdate = user.birthdate!.toDate();
        AppLogger.info('Birthdate imported from Google profile during signup');
      }
      // Note: Profile image URL will be handled by the profile display logic
      if (user.profileImageUrl != null) {
        AppLogger.info('Profile photo imported from Google account');
      }
    } else if (authState is AuthSignUpSuccess) {
      final user = authState.user;
      _nameController.text = user.name;
      if (user.bio != null) {
        _bioController.text = user.bio!;
      }
      // Initialize imported data for new signups
      if (user.birthdate != null) {
        _selectedBirthdate = user.birthdate!.toDate();
      }
    } else if (authState is AuthProfileSetupRequired) {
      final user = authState.partialUser;
      _nameController.text = user.name;
      if (user.bio != null) {
        _bioController.text = user.bio!;
      }
      // Initialize imported Google profile data
      if (user.birthdate != null) {
        _selectedBirthdate = user.birthdate!.toDate();
        AppLogger.info('Pre-filled birthdate from Google profile import');
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      if (_currentStep == 1 && !_validateCurrentStep()) {
        return;
      }
      
      _animationController.reset();
      setState(() => _currentStep++);
      _animationController.forward();
    } else {
      _completeSetup();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _animationController.reset();
      setState(() => _currentStep--);
      _animationController.forward();
    }
  }

  bool _validateCurrentStep() {
    if (_currentStep == 1) {
      if (_nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter your name'),
            backgroundColor: Colors.orange,
          ),
        );
        return false;
      }
      if (_selectedBirthdate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select your birthdate'),
            backgroundColor: Colors.orange,
          ),
        );
        return false;
      }
      final age = DateTime.now().year - _selectedBirthdate!.year;
      if (age < 18) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be at least 18 years old'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }
    return true;
  }

  void _completeSetup() async {
    if (!_validateCurrentStep() && _currentStep == 1) {
      return;
    }
    
    setState(() => _isLoading = true);
    
    // Check if we should preserve the imported profile image
    final authState = context.read<AuthBloc>().state;
    String? existingProfileImageUrl;
    
    if (authState is AuthAuthenticated) {
      existingProfileImageUrl = authState.user.profileImageUrl;
    } else if (authState is AuthProfileSetupRequired) {
      existingProfileImageUrl = authState.partialUser.profileImageUrl;
    }
    
    context.read<ProfileBloc>().add(
      UpdateProfileEvent(
        name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
        bio: _bioController.text.trim().isEmpty ? "New to TourPal, excited to explore!" : _bioController.text.trim(),
        birthdate: _selectedBirthdate,
        profileImage: _profileImage,
        // Preserve imported profile photo URL if no new image was selected
        profileImagePath: _profileImage == null && existingProfileImageUrl != null 
            ? existingProfileImageUrl 
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.select((AuthBloc bloc) => bloc.state);
    final user = authState is AuthAuthenticated ? authState.user : null;

    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) {
        setState(() => _isLoading = false);
        
        if (state is ProfileUpdateSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile setup completed successfully! 🎉'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Trigger auth state refresh to update profile completion status
          context.read<AuthBloc>().add(const CheckAuthStatusEvent());
          
          if (widget.onComplete != null) widget.onComplete!();
          // Don't pop immediately, let AuthWrapper handle the navigation
        } else if (state is ProfileError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Complete Your Profile',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: AppColors.textPrimary,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            if (_currentStep > 0)
              TextButton(
                onPressed: () {
                  if (widget.onComplete != null) widget.onComplete!();
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Skip',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            _buildProgressIndicator(),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildStepContent(),
                    ),
                  ),
                ),
              ),
            ),
            _buildBottomNavigation(context, user),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildPhotoStep();
      case 1:
        return _buildPersonalInfoStep();
      case 2:
        return _buildBioStep();
      default:
        return _buildPhotoStep();
    }
  }

  Widget _buildPhotoStep() {
    // Check if user has an imported Google profile photo
    final authState = context.select((AuthBloc bloc) => bloc.state);
    String? importedPhotoUrl;
    bool hasImportedPhoto = false;
    
    if (authState is AuthAuthenticated) {
      importedPhotoUrl = authState.user.profileImageUrl;
      hasImportedPhoto = importedPhotoUrl != null;
    } else if (authState is AuthProfileSetupRequired) {
      importedPhotoUrl = authState.partialUser.profileImageUrl;
      hasImportedPhoto = importedPhotoUrl != null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        const Text(
          'Welcome to TourPal! 🎉',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'Let\'s set up your profile to get started',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        
        // Profile Photo Display with Import Indicator
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.1),
              border: Border.all(
                color: hasImportedPhoto 
                    ? AppColors.success  // Green border for imported photos
                    : AppColors.primary.withValues(alpha: 0.3),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Profile Image Display
                if (_profileImage != null)
                  ClipOval(
                    child: Image.file(
                      _profileImage!,
                      fit: BoxFit.cover,
                      width: 150,
                      height: 150,
                    ),
                  )
                else if (hasImportedPhoto && importedPhotoUrl != null)
                  ClipOval(
                    child: Image.network(
                      importedPhotoUrl,
                      fit: BoxFit.cover,
                      width: 150,
                      height: 150,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 2,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.camera_alt,
                          size: 50,
                          color: AppColors.primary,
                        );
                      },
                    ),
                  )
                else
                  const Icon(
                    Icons.camera_alt,
                    size: 50,
                    color: AppColors.primary,
                  ),
                
                // Import Success Indicator
                if (hasImportedPhoto && _profileImage == null)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Import Status Message
        if (hasImportedPhoto && _profileImage == null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_download,
                  color: AppColors.success,
                  size: 16,
                ),
                const SizedBox(width: 6),
                const Text(
                  'Photo imported from Google',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        
        const SizedBox(height: 24),
        
        // Action Button
        ElevatedButton.icon(
          onPressed: _pickImage,
          icon: Icon(_profileImage != null || hasImportedPhoto ? Icons.photo_camera : Icons.add_a_photo),
          label: Text(
            _profileImage != null 
                ? 'Change Photo' 
                : hasImportedPhoto 
                    ? 'Use Different Photo'
                    : 'Add Profile Photo'
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Skip Button with Import Awareness
        TextButton(
          onPressed: _nextStep,
          child: Text(
            hasImportedPhoto && _profileImage == null
                ? 'Continue with imported photo'
                : 'Skip for now',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          _buildProgressStep(0, 'Profile Photo', Icons.person),
          _buildProgressLine(0),
          _buildProgressStep(1, 'Personal Info', Icons.edit),
          _buildProgressLine(1),
          _buildProgressStep(2, 'Bio', Icons.description),
        ],
      ),
    );
  }

  Widget _buildProgressStep(int stepIndex, String title, IconData icon) {
    final isCompleted = stepIndex < _currentStep;
    final isActive = stepIndex == _currentStep;
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? AppColors.primary
                  : isActive
                      ? AppColors.primary.withValues(alpha: .2)
                      : Colors.grey[200],
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              isCompleted ? Icons.check : icon,
              color: isCompleted
                  ? Colors.white
                  : isActive
                      ? AppColors.primary
                      : AppColors.gray500,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isCompleted || isActive ? AppColors.primary : Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressLine(int stepIndex) {
    final isCompleted = stepIndex < _currentStep;
    return Container(
      height: 2,
      width: 30,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isCompleted ? AppColors.primary : Colors.grey[300],
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  Widget _buildPersonalInfoStep() {
    // Check if user has imported birthdate from Google
    final authState = context.select((AuthBloc bloc) => bloc.state);
    bool hasImportedBirthdate = false;
    
    if (authState is AuthAuthenticated) {
      hasImportedBirthdate = authState.user.birthdate != null;
    } else if (authState is AuthProfileSetupRequired) {
      hasImportedBirthdate = authState.partialUser.birthdate != null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'What\'s your name?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'This will be displayed on your profile',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 32),
        
        // Name Field
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Full Name *',
            hintText: 'Enter your full name',
            prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
          textCapitalization: TextCapitalization.words,
        ),
        
        const SizedBox(height: 24),
        
        // Birthdate Section Header
        Row(
          children: [
            const Text(
              'Birthdate',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (hasImportedBirthdate && _selectedBirthdate != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_download,
                      color: AppColors.success,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'From Google',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Birthdate Picker
        GestureDetector(
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedBirthdate ?? DateTime(now.year - 25),
              firstDate: DateTime(1900),
              lastDate: now,
              helpText: 'Select your birthdate',
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: Theme.of(context).colorScheme.copyWith(
                      primary: AppColors.primary,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() => _selectedBirthdate = picked);
              
              // Log if user changed imported birthdate
              if (hasImportedBirthdate) {
                AppLogger.info('User modified imported Google birthdate');
              }
            }
          },
          child: AbsorbPointer(
            child: TextFormField(
              controller: TextEditingController(
                text: _selectedBirthdate != null
                    ? '${_selectedBirthdate!.day.toString().padLeft(2, '0')}/${_selectedBirthdate!.month.toString().padLeft(2, '0')}/${_selectedBirthdate!.year}'
                    : '',
              ),
              decoration: InputDecoration(
                labelText: 'Birthdate *',
                hintText: hasImportedBirthdate ? 'Imported from Google account' : 'Select your birthdate',
                prefixIcon: const Icon(Icons.calendar_today, color: AppColors.primary),
                suffixIcon: hasImportedBirthdate && _selectedBirthdate != null
                    ? Icon(Icons.check_circle, color: AppColors.success, size: 20)
                    : Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: hasImportedBirthdate 
                      ? BorderSide(color: AppColors.success.withValues(alpha: 0.5))
                      : const BorderSide(),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: hasImportedBirthdate 
                      ? BorderSide(color: AppColors.success.withValues(alpha: 0.3))
                      : BorderSide(color: Colors.grey[300]!),
                ),
                filled: true,
                fillColor: hasImportedBirthdate 
                    ? AppColors.success.withValues(alpha: 0.05)
                    : Colors.grey[50],
              ),
              validator: (value) {
                if (_selectedBirthdate == null) {
                  return 'Birthdate is required';
                }
                final age = DateTime.now().year - _selectedBirthdate!.year;
                if (age < 18) {
                  return 'You must be at least 18 years old';
                }
                return null;
              },
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Age Display (if birthdate is selected)
        if (_selectedBirthdate != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.cake, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Age: ${DateTime.now().year - _selectedBirthdate!.year} years old',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        const SizedBox(height: 40),
        
        // Information Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info, color: Colors.blue[600], size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Privacy & Security',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Your personal information is securely stored and only used for age verification and profile customization. You can change this later in your profile settings.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
              if (hasImportedBirthdate) ...[
                const SizedBox(height: 8),
                const Text(
                  '✓ Information automatically imported from your Google account for convenience.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBioStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'Tell us about yourself',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Share what makes you unique as a traveler',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 32),
        TextFormField(
          controller: _bioController,
          maxLines: 5,
          maxLength: 200,
          decoration: InputDecoration(
            labelText: 'Bio (Optional)',
            hintText: 'Travel enthusiast, adventure seeker, culture explorer...\n\nTell others about your travel interests, favorite destinations, or what kind of experiences you\'re looking for!',
            prefixIcon: const Icon(Icons.description_outlined, color: AppColors.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            alignLabelWithHint: true,
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.green[600], size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'A good bio helps other travelers connect with you and find common interests!',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: TextButton(
            onPressed: _completeSetup,
            child: const Text(
              'Skip for now',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation(BuildContext context, User? user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : _previousStep,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: _currentStep > 0 ? 1 : 1,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _getNextButtonText(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _getNextButtonText() {
    switch (_currentStep) {
      case 0:
        return 'Continue';
      case 1:
        return 'Next';
      case 2:
        return 'Complete Setup';
      default:
        return 'Continue';
    }
  }
}