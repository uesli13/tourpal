import 'package:flutter/material.dart';
import 'package:path/path.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/enums/sort_criteria.dart';

/// Sort bottom sheet widget for selecting sort options
class SortBottomSheet extends StatelessWidget {
  final SortCriteria currentSortOption;
  final Function(SortCriteria) onSortChanged;

  const SortBottomSheet({
    super.key,
    required this.currentSortOption,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
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
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
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
    final isSelected = currentSortOption == criteria;
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(
        _getIconForCriteria(criteria),
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
      title: Text(
        criteria.displayName,
        style: AppTextStyles.bodyMedium.copyWith(
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        _getDescriptionForCriteria(criteria),
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      trailing: isSelected 
          ? Icon(
              Icons.check_circle,
              color: AppColors.primary,
            )
          : null,
      onTap: () {
        onSortChanged(criteria);
        Navigator.of(context as BuildContext).pop();
      },
    );
  }

  IconData _getIconForCriteria(SortCriteria criteria) {
    switch (criteria) {
      case SortCriteria.newest:
        return Icons.new_releases;
      case SortCriteria.featured:
        return Icons.star;
      case SortCriteria.name:
        return Icons.trending_down;
      case SortCriteria.rating:
        return Icons.star;
      case SortCriteria.duration:
        return Icons.schedule;
      case SortCriteria.popularity:
        return Icons.favorite;
      case SortCriteria.distance:
        return Icons.location_on;
      case SortCriteria.price:
        return Icons.attach_money;
    }
  }

  String _getDescriptionForCriteria(SortCriteria criteria) {
    switch (criteria) {
      case SortCriteria.newest:
        return 'Show newest tours first';
      case SortCriteria.rating:
        return 'Highest rated first';
      case SortCriteria.duration:
        return 'Shortest duration first';
      case SortCriteria.popularity:
        return 'Most popular first';
      case SortCriteria.distance:
        return 'Closest to you first';
      case SortCriteria.name:
        return 'Alphabetical order';
      case SortCriteria.price:
        return 'Sort by price';
      case SortCriteria.featured:
        return 'Featured tours first';
    }
  }
}