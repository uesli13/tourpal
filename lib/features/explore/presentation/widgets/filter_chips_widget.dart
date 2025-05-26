import 'package:flutter/material.dart';
import 'package:tourpal/core/constants/app_colors.dart';
import 'package:tourpal/core/constants/app_text_styles.dart';
import '../../../tours/domain/enums/tour_category.dart';
import '../../../tours/domain/enums/tour_difficulty.dart';

/// Filter chips widget showing active filters
/// Follows TOURPAL UI component guidelines
class FilterChipsWidget extends StatelessWidget {
  final String searchQuery;
  final TourCategory? selectedCategory;
  final TourDifficulty? selectedDifficulty;
  final double? minPrice;
  final double? maxPrice;
  final int resultsCount;
  final VoidCallback onClearAll;
  final VoidCallback onClearCategory;
  final VoidCallback onClearDifficulty;
  final VoidCallback onClearPrice;

  const FilterChipsWidget({
    super.key,
    required this.searchQuery,
    required this.selectedCategory,
    required this.selectedDifficulty,
    required this.minPrice,
    required this.maxPrice,
    required this.resultsCount,
    required this.onClearAll,
    required this.onClearCategory,
    required this.onClearDifficulty,
    required this.onClearPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$resultsCount tours found',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextButton(
              onPressed: onClearAll,
              child: Text(
                'Clear all',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (searchQuery.isNotEmpty) _buildSearchChip(),
            if (selectedCategory != null) _buildCategoryChip(),
            if (selectedDifficulty != null) _buildDifficultyChip(),
            if (minPrice != null || maxPrice != null) _buildPriceChip(),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchChip() {
    return _FilterChip(
      label: 'Search: "$searchQuery"',
      icon: Icons.search,
      onRemove: () {}, // Handled by search bar clear
    );
  }

  Widget _buildCategoryChip() {
    return _FilterChip(
      label: selectedCategory!.displayName,
      icon: Icons.category,
      onRemove: onClearCategory,
    );
  }

  Widget _buildDifficultyChip() {
    return _FilterChip(
      label: selectedDifficulty!.displayName,
      icon: Icons.trending_up,
      onRemove: onClearDifficulty,
    );
  }

  Widget _buildPriceChip() {
    String label = 'Price: ';
    if (minPrice != null && maxPrice != null) {
      label += '\$${minPrice!.toInt()} - \$${maxPrice!.toInt()}';
    } else if (minPrice != null) {
      label += 'From \$${minPrice!.toInt()}';
    } else if (maxPrice != null) {
      label += 'Up to \$${maxPrice!.toInt()}';
    }

    return _FilterChip(
      label: label,
      icon: Icons.attach_money,
      onRemove: onClearPrice,
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onRemove;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Icon(
              icon,
              size: 16,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: onRemove,
            icon: Icon(
              Icons.close,
              size: 16,
              color: AppColors.primary,
            ),
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}