import 'package:flutter/material.dart';
import '../../domain/enums/tour_category.dart';

/// Widget for selecting tour category
class TourCategorySelector extends StatelessWidget {
  final TourCategory selectedCategory;
  final Function(TourCategory) onCategoryChanged;

  const TourCategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: TourCategory.values.map((category) {
            final isSelected = category == selectedCategory;
            return FilterChip(
              label: Text(category.displayName),
              selected: isSelected,
              onSelected: (_) => onCategoryChanged(category),
              backgroundColor: Colors.grey[100],
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              checkmarkColor: Theme.of(context).primaryColor,
              labelStyle: TextStyle(
                color: isSelected 
                    ? Theme.of(context).primaryColor 
                    : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}