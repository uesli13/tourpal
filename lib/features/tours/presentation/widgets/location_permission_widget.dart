import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class LocationPermissionWidget extends StatelessWidget {
  final bool hasPermission;
  final VoidCallback onRequestPermission;

  const LocationPermissionWidget({
    super.key,
    required this.hasPermission,
    required this.onRequestPermission,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasPermission ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasPermission ? Colors.green : Colors.orange,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasPermission ? Icons.location_on : Icons.location_off,
                color: hasPermission ? Colors.green : Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasPermission ? 'Location Access Granted' : 'Location Access Required',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: hasPermission ? Colors.green : Colors.orange[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasPermission 
                        ? 'Your location will be shared with the tour group'
                        : 'Enable location sharing to participate in the tour',
                      style: TextStyle(
                        fontSize: 14,
                        color: hasPermission ? Colors.green[700] : Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!hasPermission) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onRequestPermission,
                icon: const Icon(Icons.location_on),
                label: const Text('Grant Location Access'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}