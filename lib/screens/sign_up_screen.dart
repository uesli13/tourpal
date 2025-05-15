import 'package:flutter/material.dart';
import 'package:tourpal/utils/constants.dart';
import 'package:tourpal/widgets/custom_text_field.dart';
import 'package:tourpal/widgets/logo_widget.dart';

class SignUpScreen extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
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
                        const CustomTextField(labelText: 'Name'),
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
                        const CustomTextField(labelText: 'Corfirm Password', obscureText: true),
                        const SizedBox(height: 24),
                        // Sign Up Button
                        ElevatedButton(
                          onPressed: () async {
                            // Remove: try {
                            // Remove:   final user = await _authService.signUpWithEmail(
                            // Remove:     _emailController.text,
                            // Remove:     _passwordController.text,
                            // Remove:   );
                            // Remove:   if (user != null) {
                            // Remove:     print('User signed up: ${user.email}');
                            // Remove:     // Navigate to Home Screen or display a success message
                            // Remove:   }
                            // Remove: } catch (e) {
                            // Remove:   ScaffoldMessenger.of(context).showSnackBar(
                            // Remove:     SnackBar(content: Text('Error: $e')),
                            // Remove:   );
                            // Remove: }
                          },
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