import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../models/guide.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/role_bloc.dart';
import '../bloc/role_event.dart';
import '../bloc/role_state.dart';

class GuideProfileScreen extends StatefulWidget {
  const GuideProfileScreen({super.key});

  @override
  State<GuideProfileScreen> createState() => _GuideProfileScreenState();
}

class _GuideProfileScreenState extends State<GuideProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  
  List<String> _selectedLanguages = [];
  final List<String> _availableLanguages = [
    'English', 'Spanish', 'French', 'German', 'Italian', 'Portuguese',
    'Chinese', 'Japanese', 'Korean', 'Arabic', 'Russian', 'Dutch'
  ];
  
  bool _isAvailable = true;
  bool _isEditing = false;

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  String? _getCurrentUserId() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      return authState.user.id;
    }
    return null;
  }

  void _updateAvailability(bool value) {
    final userId = _getCurrentUserId();
    if (userId != null) {
      setState(() {
        _isAvailable = value;
      });
      context.read<RoleBloc>().add(
        UpdateGuideAvailability(userId, value),
      );
    }
  }

  void _updateGuideProfile() {
    if (_formKey.currentState?.validate() ?? false) {
      final userId = _getCurrentUserId();
      if (userId == null) return;

      final updatedGuide = Guide(
        userId: userId,
        bio: _bioController.text.trim(),
        languages: _selectedLanguages,
        isAvailable: _isAvailable,
      );

      context.read<RoleBloc>().add(UpdateGuideProfile(updatedGuide));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guide Profile'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              icon: const Icon(Icons.edit),
            ),
          if (_isEditing) ...[
            IconButton(
              onPressed: () {
                setState(() {
                  _isEditing = false;
                });
              },
              icon: const Icon(Icons.close),
            ),
            IconButton(
              onPressed: _updateGuideProfile,
              icon: const Icon(Icons.save),
            ),
          ],
        ],
      ),
      body: BlocListener<RoleBloc, RoleState>(
        listener: (context, state) {
          if (state is DualRoleState) {
            // Profile updated successfully
            if (_isEditing) {
              setState(() {
                _isEditing = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile updated successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else if (state is RoleError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<RoleBloc, RoleState>(
          builder: (context, state) {
            if (state is DualRoleState && state.guide != null) {
              final guide = state.guide!;
              
              // Initialize form fields with current guide data
              if (!_isEditing && _bioController.text.isEmpty) {
                _bioController.text = guide.bio ?? '';
                _selectedLanguages = List.from(guide.languages);
                _isAvailable = guide.isAvailable;
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Guide Status Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.verified,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 32,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Verified Guide',
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'You can create tours and accept bookings',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Availability Toggle
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainer.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _isAvailable ? Icons.check_circle : Icons.pause_circle,
                                      color: _isAvailable ? Colors.green : Colors.orange,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _isAvailable 
                                            ? 'Available for bookings' 
                                            : 'Currently unavailable',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Switch(
                                      value: _isAvailable,
                                      onChanged: _updateAvailability,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Bio Section
                      Text(
                        'About You',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _bioController,
                        enabled: _isEditing,
                        decoration: InputDecoration(
                          labelText: 'Bio',
                          hintText: 'Tell travelers about yourself and your local expertise...',
                          border: _isEditing ? const OutlineInputBorder() : InputBorder.none,
                          prefixIcon: const Icon(Icons.person),
                          filled: !_isEditing,
                          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .1),
                        ),
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a bio';
                          }
                          if (value.trim().length < 50) {
                            return 'Bio must be at least 50 characters long';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Languages Section
                      Text(
                        'Languages You Speak',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Selected Languages
                      if (_selectedLanguages.isNotEmpty) ...[
                        Text(
                          'Selected Languages',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline.withValues(alpha: .2),
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .1),
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _selectedLanguages.map((language) {
                              return Card(
                                elevation: 2,
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: .1),
                                child: InkWell(
                                  onTap: _isEditing ? () {
                                    setState(() {
                                      _selectedLanguages.remove(language);
                                    });
                                  } : null,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.language,
                                          size: 16,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          language,
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.primary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (_isEditing) ...[
                                          const SizedBox(width: 8),
                                          Icon(
                                            Icons.close,
                                            size: 16,
                                            color: Theme.of(context).colorScheme.error,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Available Languages to Add
                      if (_isEditing && _availableLanguages.where((lang) => !_selectedLanguages.contains(lang)).isNotEmpty) ...[
                        Text(
                          'Add Languages',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline.withValues(alpha: .2),
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: Theme.of(context).colorScheme.secondary.withValues(alpha: .05),
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _availableLanguages
                                .where((lang) => !_selectedLanguages.contains(lang))
                                .map((language) {
                              return Card(
                                elevation: 1,
                                color: Colors.white,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedLanguages.add(language);
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.add_circle_outline,
                                          size: 16,
                                          color: Theme.of(context).colorScheme.secondary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          language,
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.onSurface,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 32),
                      
                      // Information Card - Guide Profile is Permanent
                      Card(
                        color: Colors.blue.withValues(alpha: .1),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Guide Profile Information',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Your guide profile is permanent and cannot be deleted. You can always switch between traveler and guide modes in your profile settings without losing your guide data.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        ),
      ),
    );
  }
}