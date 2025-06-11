import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/guide.dart';
import '../bloc/role_bloc.dart';
import '../bloc/role_event.dart';
import '../bloc/role_state.dart';

class BecomeGuideScreen extends StatefulWidget {
  const BecomeGuideScreen({super.key});

  @override
  State<BecomeGuideScreen> createState() => _BecomeGuideScreenState();
}

class _BecomeGuideScreenState extends State<BecomeGuideScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  
  List<String> _selectedLanguages = [];
  final List<String> _availableLanguages = [
    'English', 'Spanish', 'French', 'German', 'Italian', 'Portuguese',
    'Chinese', 'Japanese', 'Korean', 'Arabic', 'Russian', 'Dutch'
  ];
  
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Become a Guide',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: BlocConsumer<RoleBloc, RoleState>(
        listener: (context, state) {
          if (state is RoleError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is DualRoleState) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Congratulations! You are now a verified guide!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop();
          }
        },
        builder: (context, state) {
          final isLoading = state is RoleLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.tour,
                          size: 60,
                          color: Colors.white,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Share Your City',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Become a local guide and help travelers discover amazing experiences',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Bio Section
                  const Text(
                    'Tell us about yourself',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Share your local knowledge and what makes you passionate about your city',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bioController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'I\'m passionate about sharing the hidden gems of my city...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please tell us about yourself';
                      }
                      if (value.trim().length < 50) {
                        return 'Please provide at least 50 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Languages Section
                  const Text(
                    'Languages you speak',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select all languages you can comfortably conduct tours in',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Selected Languages
                  if (_selectedLanguages.isNotEmpty) ...[
                    const Text(
                      'Selected Languages:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedLanguages.map((language) {
                        return Chip(
                          label: Text(language),
                          onDeleted: () {
                            setState(() {
                              _selectedLanguages.remove(language);
                            });
                          },
                          backgroundColor: AppColors.primary.withValues(alpha: .1),
                          deleteIconColor: AppColors.primary,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Available Languages
                  const Text(
                    'Available Languages:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableLanguages
                        .where((lang) => !_selectedLanguages.contains(lang))
                        .map((language) {
                      return ActionChip(
                        label: Text(language),
                        onPressed: () {
                          setState(() {
                            _selectedLanguages.add(language);
                          });
                        },
                        backgroundColor: Colors.grey[200],
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Validation
                  if (_selectedLanguages.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Please select at least one language',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 32),

                  // Terms and Conditions
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _agreeToTerms,
                        onChanged: (value) {
                          setState(() {
                            _agreeToTerms = value ?? false;
                          });
                        },
                        activeColor: AppColors.primary,
                      ),
                      const Expanded(
                        child: Text(
                          'I agree to the Terms of Service and commit to providing safe, respectful, and high-quality tour experiences',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: (_agreeToTerms && 
                                  _selectedLanguages.isNotEmpty && 
                                  !isLoading) ? _submitApplication : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Become a Guide',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              'What happens next?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          '• Your guide profile will be created immediately\n'
                          '• You can start creating tours right away\n'
                          '• Share your local expertise with travelers\n'
                          '• Earn money doing what you love',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _submitApplication() {
    if (_formKey.currentState!.validate() && _selectedLanguages.isNotEmpty && _agreeToTerms) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in to become a guide'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final guide = Guide(
        userId: user.uid,
        bio: _bioController.text.trim(),
        languages: _selectedLanguages,
        isAvailable: true,
      );

      context.read<RoleBloc>().add(CreateGuideProfile(guide));
    }
  }
}