import 'package:flutter/material.dart';
import 'package:tourpal/screens/home_screen.dart';
import 'package:tourpal/utils/constants.dart';
import 'package:tourpal/screens/sign_up_screen.dart';
import 'package:tourpal/widgets/google_sign_in_button.dart';
import 'package:tourpal/widgets/logo_widget.dart';
import 'package:tourpal/widgets/custom_text_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tourpal/services/auth_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService        = AuthService();
  bool _isLoading           = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }


    Future<void> _handleSignIn() async {
    final email    = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email & password')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _authService.signInWithEmail(email, password);
      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign‑in failed: ${e.message}')),
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
                        
                        // Email
                        CustomTextField(
                          labelText: 'Email',
                          controller: _emailController,
                        ),
                        const SizedBox(height: 16),

                        // Password
                        CustomTextField(
                          labelText: 'Password',
                          obscureText: true,
                          controller: _passwordController,
                        ),
                        const SizedBox(height: 24),

                        // Sign In Button
                        if (_isLoading) 
                          const Center(child: CircularProgressIndicator())
                        else
                        ElevatedButton(
                          onPressed: _handleSignIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 24),
                          ),
                          child: const Text('Sign In'),
                        ),
                        const SizedBox(height: 16),

                        // Google Sign In Button
                        const GoogleSignInButton(),
                        const SizedBox(height: 16),

                        // Sign Up Button
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => SignUpScreen()),
                            );
                          },
                          child: const Text('Don’t have an account? Sign Up'),
                        ),
                        const Spacer(),
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