import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../tours/domain/enums/tour_category.dart';
import '../../../tours/domain/enums/tour_difficulty.dart';

/// Quick filters row widget for category and difficulty selection
/// Follows TOURPAL UI component guidelines
class QuickFiltersRow extends StatelessWidget {
  final TourCategory? selectedCategory;
  final TourDifficulty? selectedDifficulty;
  final Function(TourCategory?) onCategorySelected;
  final Function(TourDifficulty?) onDifficultySelected;

  const QuickFiltersRow({
    super.key,
    required this.selectedCategory,
    required this.selectedDifficulty,
    required this.onCategorySelected,
    required this.onDifficultySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categories',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: TourCategory.values.length + 1,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildFilterChip(
                  label: 'All',
                  emoji: '🌟',
                  isSelected: selectedCategory == null,
                  onTap: () => onCategorySelected(null),
                );
              }
              
              final category = TourCategory.values[index - 1];
              return _buildFilterChip(
                label: category.displayName,
                emoji: category.emoji,
                isSelected: selectedCategory == category,
                onTap: () => onCategorySelected(category),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Difficulty',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: TourDifficulty.values.length + 1,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildFilterChip(
                  label: 'All',
                  emoji: '⚡',
                  isSelected: selectedDifficulty == null,
                  onTap: () => onDifficultySelected(null),
                );
              }
              
              final difficulty = TourDifficulty.values[index - 1];
              return _buildFilterChip(
                label: difficulty.displayName,
                emoji: _getDifficultyEmoji(difficulty),
                isSelected: selectedDifficulty == difficulty,
                onTap: () => onDifficultySelected(difficulty),
                color: difficulty.color,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String emoji,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? (color ?? AppColors.primary)
              : AppColors.gray100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? (color ?? AppColors.primary)
                : AppColors.gray200,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDifficultyEmoji(TourDifficulty difficulty) {
    switch (difficulty) {
      case TourDifficulty.easy:
        return '🚶';
      case TourDifficulty.moderate:
        return '🥾';
      case TourDifficulty.challenging:
        return '🏔️';
      case TourDifficulty.extreme:
        return '⛰️';
      case TourDifficulty.difficult:
        return '🏋️';
    }
  }
}