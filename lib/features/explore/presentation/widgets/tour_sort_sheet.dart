import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/logger.dart';

/// Sort criteria for tours
enum SortCriteria {
  priceLoweToHigh,
  priceHighToLow,
  durationShortToLong,
  durationLongToShort,
  ratingHighToLow,
  newest;

  String get displayName {
    switch (this) {
      case SortCriteria.priceLoweToHigh:
        return 'Price: Low to High';
      case SortCriteria.priceHighToLow:
        return 'Price: High to Low';
      case SortCriteria.durationShortToLong:
        return 'Duration: Short to Long';
      case SortCriteria.durationLongToShort:
        return 'Duration: Long to Short';
      case SortCriteria.ratingHighToLow:
        return 'Highest Rated';
      case SortCriteria.newest:
        return 'Newest First';
    }
  }

  IconData get icon {
    switch (this) {
      case SortCriteria.priceLoweToHigh:
      case SortCriteria.priceHighToLow:
        return Icons.attach_money;
      case SortCriteria.durationShortToLong:
      case SortCriteria.durationLongToShort:
        return Icons.access_time;
      case SortCriteria.ratingHighToLow:
        return Icons.star;
      case SortCriteria.newest:
        return Icons.new_releases;
    }
  }
}

/// Tour sort bottom sheet for selecting sort criteria
/// Follows TourPal BLoC architecture principles
class TourSortSheet extends StatelessWidget {
  final SortCriteria? selectedCriteria;
  final Function(SortCriteria) onSortSelected;

  const TourSortSheet({
    super.key,
    required this.selectedCriteria,
    required this.onSortSelected,
  });

  @override
  Widget build(BuildContext context) {
    AppLogger.debug('Building TourSortSheet');
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          _buildSortOptions(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: .1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.gray300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Sort Tours',
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortOptions() {
    return Column(
      children: SortCriteria.values.map((criteria) {
        return _buildSortOption(criteria);
      }).toList(),
    );
  }

  Widget _buildSortOption(SortCriteria criteria) {
    final isSelected = selectedCriteria == criteria;
    
    return GestureDetector(
      onTap: () {
        AppLogger.info('Sort criteria selected: ${criteria.displayName}');
        onSortSelected(criteria);
        // Close the sheet
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: .1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: AppColors.primary, width: 1.5) : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.gray100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                criteria.icon,
                size: 20,
                color: isSelected ? Colors.white : AppColors.gray600,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                criteria.displayName,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}