import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tourpal/screens/home_screen.dart';
import 'package:tourpal/services/auth_service.dart';
import 'package:tourpal/utils/constants.dart';
import 'package:tourpal/widgets/custom_text_field.dart';
import 'package:tourpal/widgets/logo_widget.dart';


class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService        = AuthService();
  final _nameController = TextEditingController();
  bool _isLoading           = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    final name    = _nameController.text.trim();
    final email    = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // final user = await _authService.signUpWithEmail(email, password);

      final userCred = await _authService.signUpWithEmail(
        email,
        password,
        name,
      );

      // if (user != null) {
      //   Navigator.pushReplacement(
      //     context,
      //     MaterialPageRoute(builder: (_) => const HomeScreen()),
      //   );
      // }
      if (userCred?.user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }

    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppColors.primary,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo
                        const LogoWidget(),
                        const SizedBox(height: 24),
                        // Name TextField
                        CustomTextField(
                          labelText: 'Name',
                          controller: _nameController,
                        ),
                        const SizedBox(height: 16),
                        // Email TextField
                        CustomTextField(
                          labelText: 'Email',
                          controller: _emailController,
                        ),
                        const SizedBox(height: 16),
                        // Password TextField
                        CustomTextField(
                          labelText: 'Password',
                          obscureText: true,
                          controller: _passwordController,
                        ),
                        const SizedBox(height: 16),
                        // Confirm Password TextField
                        CustomTextField(
                          labelText: 'Confirm Password',
                          obscureText: true,
                          controller: _confirmPasswordController,
                        ),
                        const SizedBox(height: 24),
                        // Sign Up Button
                        if (_isLoading) 
                          const Center(child: CircularProgressIndicator())
                        else
                        ElevatedButton(
                          onPressed: _handleSignUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                          ),
                          child: const Text('Sign Up'),
                        ),
                        const SizedBox(height: 16),
                        // Already Have an Account? Sign In Button
                        TextButton(
                          onPressed: () {
                            // Navigate back to the Sign-In Screen
                            Navigator.pop(context);
                          },
                          child: const Text('Already have an account? Sign In'),
                        ),
                        const Spacer(), // Pushes content to the top
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

}