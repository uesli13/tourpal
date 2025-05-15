import 'package:flutter/material.dart';
import 'package:tourpal/screens/home_screen.dart';
import 'package:tourpal/utils/constants.dart';
import 'package:tourpal/screens/sign_up_screen.dart';
import 'package:tourpal/widgets/logo_widget.dart';
import 'package:tourpal/widgets/custom_text_field.dart';


class SignInScreen extends StatelessWidget {
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
                        const CustomTextField(labelText: 'Email'),
                        const SizedBox(height: 16),
                        const CustomTextField(labelText: 'Password', obscureText: true),
                        const SizedBox(height: 24),
                        // Sign In Button
                        ElevatedButton(
                          onPressed: () {
                            // Handle sign-in logic
                            print('Sign In button pressed');
                            //go to home screen
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => HomeScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 24),
                          ),
                          child: const Text('Sign In'),
                        ),
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