import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Popular destinations grid widget
/// Follows TOURPAL UI component guidelines
class PopularDestinationsGrid extends StatelessWidget {
  final List<String> destinations;
  final Function(String) onDestinationTap;

  const PopularDestinationsGrid({
    super.key,
    required this.destinations,
    required this.onDestinationTap,
  });

  @override
  Widget build(BuildContext context) {
    if (destinations.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Popular Destinations',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: destinations.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final destination = destinations[index];
              return _buildDestinationCard(destination);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDestinationCard(String destination) {
    return GestureDetector(
      onTap: () => onDestinationTap(destination),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              _buildDestinationImage(destination),
              _buildGradientOverlay(),
              _buildDestinationContent(destination),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDestinationImage(String destination) {
    // Mock destination images - in real app would come from API
    final destinationImages = {
      'Paris': 'https://images.unsplash.com/photo-1502602898536-47ad22581b52',
      'Tokyo': 'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf',
      'New York': 'https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9',
      'London': 'https://images.unsplash.com/photo-1513635269975-59663e0ac1ad',
      'Rome': 'https://images.unsplash.com/photo-1552832230-c0197dd311b5',
      'Barcelona': 'https://images.unsplash.com/photo-1539037116277-4db20889f2d4',
    };

    final imageUrl = destinationImages[destination];
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.gray200,
      child: imageUrl != null
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(destination),
            )
          : _buildImagePlaceholder(destination),
    );
  }

  Widget _buildImagePlaceholder(String destination) {
    // Mock destination emojis
    final destinationEmojis = {
      'Paris': '🗼',
      'Tokyo': '🏯',
      'New York': '🗽',
      'London': '🌉',
      'Rome': '🏛️',
      'Barcelona': '🏖️',
    };

    return Container(
      color: AppColors.primary.withOpacity(0.1),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              destinationEmojis[destination] ?? '🌍',
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 4),
            Icon(
              Icons.location_on,
              size: 24,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.6),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationContent(String destination) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              destination,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              _getDestinationDescription(destination),
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white70,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _getDestinationDescription(String destination) {
    // Mock destination descriptions
    final descriptions = {
      'Paris': 'City of Light',
      'Tokyo': 'Modern & Traditional',
      'New York': 'The Big Apple',
      'London': 'Historic & Royal',
      'Rome': 'Eternal City',
      'Barcelona': 'Art & Architecture',
    };

    return descriptions[destination] ?? 'Amazing destination';
  }

  Widget _buildEmptyState() {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_city,
              size: 32,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              'No popular destinations available',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}