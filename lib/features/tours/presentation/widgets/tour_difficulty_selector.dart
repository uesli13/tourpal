import 'package:flutter/material.dart';
import '../../domain/enums/tour_difficulty.dart';

/// Widget for selecting tour difficulty
class TourDifficultySelector extends StatelessWidget {
  final TourDifficulty selectedDifficulty;
  final Function(TourDifficulty) onDifficultyChanged;

  const TourDifficultySelector({
    super.key,
    required this.selectedDifficulty,
    required this.onDifficultyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Difficulty Level',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: TourDifficulty.values.map((difficulty) {
            final isSelected = difficulty == selectedDifficulty;
            return FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getDifficultyIcon(difficulty),
                    size: 16,
                    color: isSelected 
                        ? Theme.of(context).primaryColor 
                        : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(difficulty.displayName),
                ],
              ),
              selected: isSelected,
              onSelected: (_) => onDifficultyChanged(difficulty),
              backgroundColor: Colors.grey[100],
              selectedColor: _getDifficultyColor(difficulty).withOpacity(0.2),
              checkmarkColor: _getDifficultyColor(difficulty),
              labelStyle: TextStyle(
                color: isSelected 
                    ? _getDifficultyColor(difficulty)
                    : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  IconData _getDifficultyIcon(TourDifficulty difficulty) {
    switch (difficulty) {
      case TourDifficulty.easy:
        return Icons.sentiment_very_satisfied;
      case TourDifficulty.moderate:
        return Icons.sentiment_satisfied;
      case TourDifficulty.challenging:
        return Icons.sentiment_neutral;
      case TourDifficulty.difficult:
        return Icons.sentiment_dissatisfied;
      case TourDifficulty.extreme:
        return Icons.sentiment_very_dissatisfied;
    }
  }

  Color _getDifficultyColor(TourDifficulty difficulty) {
    switch (difficulty) {
      case TourDifficulty.easy:
        return Colors.green;
      case TourDifficulty.moderate:
        return Colors.orange;
      case TourDifficulty.challenging:
        return Colors.deepOrange;
      case TourDifficulty.difficult:
        return Colors.red;
      case TourDifficulty.extreme:
        return Colors.pink;
    }
  }
}