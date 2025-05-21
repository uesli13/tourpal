import 'package:flutter/material.dart';
import 'package:tourpal/screens/home_screen.dart';
import 'package:tourpal/utils/constants.dart';
import 'package:tourpal/widgets/custom_text_field.dart';
import 'package:tourpal/widgets/logo_widget.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/auth/auth_state.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
  }

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }


  void _onSignUpPressed() {
    final name            = _nameController.text.trim();
    final email           = _emailController.text.trim();
    final password        = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
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

    context.read<AuthBloc>().add(SignUpRequested(name, email, password));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            // Εφόσον ολοκληρώθηκε επιτυχώς η εγγραφή/σύνδεση
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }
          if (state is AuthFailure) {
            // Εμφάνιση λάθους
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Sign‑up failed: ${state.error}')),
            );
          }
        },
        child: Container(
          color: AppColors.primary,
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const LogoWidget(),
                          const SizedBox(height: 24),

                          CustomTextField(
                            labelText: 'Name',
                            controller: _nameController,
                          ),
                          const SizedBox(height: 16),

                          CustomTextField(
                            labelText: 'Email',
                            controller: _emailController,
                          ),
                          const SizedBox(height: 16),

                          CustomTextField(
                            labelText: 'Password',
                            obscureText: true,
                            controller: _passwordController,
                          ),
                          const SizedBox(height: 16),

                          CustomTextField(
                            labelText: 'Confirm Password',
                            obscureText: true,
                            controller: _confirmPasswordController,
                          ),
                          const SizedBox(height: 24),

                          // BlocBuilder για το loading spinner
                          BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) {
                              if (state is AuthLoading) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              return ElevatedButton(
                                onPressed: _onSignUpPressed,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 24),
                                ),
                                child: const Text('Sign Up'),
                              );
                            },
                          ),

                          const SizedBox(height: 16),

                          TextButton(
                            onPressed: () {
                              // Πηγαίνουμε πίσω στο SignIn
                              Navigator.pop(context);
                            },
                            child: const Text('Already have an account? Sign In'),
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
      ),
    );
  }
}