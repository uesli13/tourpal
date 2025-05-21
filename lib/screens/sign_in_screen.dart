import 'package:flutter/material.dart';
import 'package:tourpal/screens/home_screen.dart';
import 'package:tourpal/utils/constants.dart';
import 'package:tourpal/screens/sign_up_screen.dart';
import 'package:tourpal/widgets/google_sign_in_button.dart';
import 'package:tourpal/widgets/logo_widget.dart';
import 'package:tourpal/widgets/custom_text_field.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/auth/auth_state.dart';



class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSignInPressed() {
    final email    = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email & password')),
      );
      return;
    }
    context.read<AuthBloc>().add(SignInRequested(email, password));
  }

  void _onGoogleSignInPressed() {
    context.read<AuthBloc>().add(GoogleSignInRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }
          if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Sign‑in failed: ${state.error}')),
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
                            labelText: 'Email',
                            controller: _emailController,
                          ),
                          const SizedBox(height: 16),

                          CustomTextField(
                            labelText: 'Password',
                            obscureText: true,
                            controller: _passwordController,
                          ),
                          const SizedBox(height: 24),

                          BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) {
                              if (state is AuthLoading) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              return ElevatedButton(
                                onPressed: _onSignInPressed,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 24),
                                ),
                                child: const Text('Sign In'),
                              );
                            },
                          ),

                          const SizedBox(height: 16),

                          GoogleSignInButton(onPressed: _onGoogleSignInPressed),

                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => SignUpScreen()),
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
      ),
    );
  }
}