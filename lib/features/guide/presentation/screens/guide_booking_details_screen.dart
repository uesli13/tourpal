import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class BookingDetailsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Booking Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ... other widgets

            Container(
              color: AppColors.mutedGreen, // Changed to muted color
              child: ListTile(
                title: Text('Booking Confirmed'),
                trailing: Icon(Icons.check_circle, color: AppColors.mutedGreen),
              ),
            ),

            // ... other widgets

            Container(
              color: AppColors.mutedRed, // Changed to muted color
              child: ListTile(
                title: Text('Payment Failed'),
                trailing: Icon(Icons.error, color: AppColors.mutedRed),
              ),
            ),

            // ... other widgets

            Container(
              color: AppColors.mutedOrange, // Changed to muted color
              child: ListTile(
                title: Text('Pending Approval'),
                trailing: Icon(Icons.pending, color: AppColors.mutedOrange),
              ),
            ),

            // ... other widgets
          ],
        ),
      ),
    );
  }
}