import 'package:flutter/material.dart';
import 'package:tourpal/utils/constants.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Home'),
      ),
      body: const Center(
        child: Text('Welcome to TourPal!'),
      ),
    );
  }
}