import 'package:flutter/material.dart';
import 'package:tourpal/core/constants/app_text_styles.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/logger.dart';
import '../../../tours/domain/enums/tour_category.dart';
import '../../../tours/domain/enums/tour_difficulty.dart';

/// Tour filter bottom sheet for advanced filtering options
/// Follows TourPal BLoC architecture principles
class TourFilterSheet extends StatefulWidget {
  final TourCategory? selectedCategory;
  final TourDifficulty? selectedDifficulty;
  final double? minPrice;
  final double? maxPrice;
  final Function(TourFilterData) onApplyFilters;
  final VoidCallback onClearFilters;

  const TourFilterSheet({
    super.key,
    this.selectedCategory,
    this.selectedDifficulty,
    this.minPrice,
    this.maxPrice,
    required this.onApplyFilters,
    required this.onClearFilters,
  });

  @override
  State<TourFilterSheet> createState() => _TourFilterSheetState();
}

class _TourFilterSheetState extends State<TourFilterSheet> {
  late TourCategory? _selectedCategory;
  late TourDifficulty? _selectedDifficulty;
  late RangeValues _priceRange;
  
  static const double _minPrice = 0;
  static const double _maxPrice = 200;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategory;
    _selectedDifficulty = widget.selectedDifficulty;
    _priceRange = RangeValues(
      widget.minPrice ?? _minPrice,
      widget.maxPrice ?? _maxPrice,
    );
    
    AppLogger.info('TourFilterSheet initialized');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCategorySection(),
                  const SizedBox(height: 32),
                  _buildDifficultySection(),
                  const SizedBox(height: 32),
                  _buildPriceSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          _buildFooter(),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Tours',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: _clearAllFilters,
                child: Text(
                  'Clear All',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: AppTextStyles.headlineSmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildCategoryChip(null, 'All Categories'),
            ...TourCategory.values.map((category) =>
              _buildCategoryChip(category, category.displayName),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryChip(TourCategory? category, String label) {
    final isSelected = _selectedCategory == category;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
        AppLogger.info('Category filter selected: ${category?.displayName ?? 'All'}');
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.gray300,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (category != null) ...[
              Text(
                category.emoji,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Difficulty Level',
          style: AppTextStyles.headlineSmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Column(
          children: [
            _buildDifficultyOption(null, 'Any Difficulty'),
            ...TourDifficulty.values.map((difficulty) =>
              _buildDifficultyOption(difficulty, difficulty.displayName),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDifficultyOption(TourDifficulty? difficulty, String label) {
    final isSelected = _selectedDifficulty == difficulty;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDifficulty = difficulty;
        });
        AppLogger.info('Difficulty filter selected: ${difficulty?.displayName ?? 'Any'}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: .1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.gray300,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.gray400,
                  width: 2,
                ),
                shape: BoxShape.circle,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (difficulty != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildDifficultyIndicator(difficulty),
                        const SizedBox(width: 8),
                        Text(
                          difficulty.description,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyIndicator(TourDifficulty difficulty) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: index < difficulty.level ? difficulty.color : AppColors.gray300,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Price Range',
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '\$${_priceRange.start.round()} - \$${_priceRange.end.round()}',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.gray300,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: .2),
            valueIndicatorColor: AppColors.primary,
            rangeThumbShape: const RoundRangeSliderThumbShape(
              enabledThumbRadius: 12,
            ),
            rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
          ),
          child: RangeSlider(
            values: _priceRange,
            min: _minPrice,
            max: _maxPrice,
            divisions: 20,
            labels: RangeLabels(
              '\$${_priceRange.start.round()}',
              '\$${_priceRange.end.round()}',
            ),
            onChanged: (RangeValues values) {
              setState(() {
                _priceRange = values;
              });
            },
            onChangeEnd: (RangeValues values) {
              AppLogger.info('Price range changed: \$${values.start.round()} - \$${values.end.round()}');
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '\$${_minPrice.round()}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '\$${_maxPrice.round()}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooter() {
    final hasFilters = _selectedCategory != null ||
        _selectedDifficulty != null ||
        _priceRange.start != _minPrice ||
        _priceRange.end != _maxPrice;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: .1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: hasFilters ? _clearAllFilters : null,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(
                    color: hasFilters ? AppColors.primary : AppColors.gray300,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Clear',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: hasFilters ? AppColors.primary : AppColors.gray500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Apply Filters${hasFilters ? ' (${_getFilterCount()})' : ''}',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clearAllFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedDifficulty = null;
      _priceRange = const RangeValues(_minPrice, _maxPrice);
    });
    
    AppLogger.info('All filters cleared');
    widget.onClearFilters();
  }

  void _applyFilters() {
    final filterData = TourFilterData(
      category: _selectedCategory,
      difficulty: _selectedDifficulty,
      minPrice: _priceRange.start != _minPrice ? _priceRange.start : null,
      maxPrice: _priceRange.end != _maxPrice ? _priceRange.end : null,
    );
    
    AppLogger.info('Filters applied: ${filterData.toString()}');
    widget.onApplyFilters(filterData);
    Navigator.of(context).pop();
  }

  int _getFilterCount() {
    int count = 0;
    if (_selectedCategory != null) count++;
    if (_selectedDifficulty != null) count++;
    if (_priceRange.start != _minPrice || _priceRange.end != _maxPrice) count++;
    return count;
  }
}

/// Data class for tour filter parameters
class TourFilterData {
  final TourCategory? category;
  final TourDifficulty? difficulty;
  final double? minPrice;
  final double? maxPrice;

  const TourFilterData({
    this.category,
    this.difficulty,
    this.minPrice,
    this.maxPrice,
  });

  @override
  String toString() {
    return 'TourFilterData(category: ${category?.displayName}, difficulty: ${difficulty?.displayName}, minPrice: $minPrice, maxPrice: $maxPrice)';
  }
}