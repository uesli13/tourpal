import 'package:flutter/material.dart';
import '../../../../core/utils/logger.dart';


/// Navigation helper for Tour features with BLoC integration
class TourNavigation {
  
  /// Show tour creation success and navigate back
  static void showTourCreationSuccess(BuildContext context, String tourTitle) {
    AppLogger.info('Showing tour creation success for: $tourTitle');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tour "$tourTitle" created successfully!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
    
    Navigator.pop(context);
  }

  /// Show tour update success
  static void showTourUpdateSuccess(BuildContext context, String tourTitle) {
    AppLogger.info('Showing tour update success for: $tourTitle');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tour "$tourTitle" updated successfully!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Show tour deletion success
  static void showTourDeletionSuccess(BuildContext context) {
    AppLogger.info('Showing tour deletion success');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tour deleted successfully!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Show error message
  static void showError(BuildContext context, String message) {
    AppLogger.error('Showing error message: $message');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $message'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}