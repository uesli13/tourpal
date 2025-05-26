import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/logger.dart';
import '../../../tours/domain/entities/tour.dart';

/// Enhanced tour card widget with detailed tour information
class EnhancedTourCard extends StatelessWidget {
  final Tour tour;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool isFavorite;
  final bool showFullDetails;
  final bool showDistance;
  final TourCardLayout layout;

  const EnhancedTourCard({
    super.key,
    required this.tour,
    this.onTap,
    this.onFavorite,
    this.isFavorite = false,
    this.showFullDetails = true,
    this.showDistance = false,
    this.layout = TourCardLayout.vertical,
  });

  @override
  Widget build(BuildContext context) {
    AppLogger.debug('Building EnhancedTourCard for tour: ${tour.title}');
    
    if (layout == TourCardLayout.horizontal) {
      return _buildHorizontalCard();
    }
    
    return _buildVerticalCard();
  }

  Widget _buildVerticalCard() {
    return GestureDetector(
      onTap: () {
        AppLogger.info('Tour card tapped: ${tour.title}');
        onTap?.call();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSection(),
            if (showFullDetails) ...[
              _buildContentSection(),
              _buildFooterSection(),
            ] else
              _buildCompactContentSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalCard() {
    return GestureDetector(
      onTap: () {
        AppLogger.info('Tour card tapped: ${tour.title}');
        onTap?.call();
      },
      child: Container(
        height: 160, 
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(alpha: 0.15),
              blurRadius: 12, 
              offset: const Offset(0, 6),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            _buildHorizontalImage(),
            Expanded(child: _buildHorizontalContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    final imageUrl = tour.images.isNotEmpty ? tour.images.first : null;
    
    return Container(
      height: 200,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Stack(
        children: [
          _buildImage(imageUrl),
          _buildImageOverlay(),
          _buildImageContent(),
        ],
      ),
    );
  }

  Widget _buildHorizontalImage() {
    final imageUrl = tour.images.isNotEmpty ? tour.images.first : null;
    
    return Container(
      width: 140,
      height: 160, 
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(20)), 
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
            child: imageUrl != null
                ? Image.network(
                    imageUrl,
                    width: 140,
                    height: 160,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                  )
                : _buildImagePlaceholder(),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.1),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.3),
                ],
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: _buildCategoryChip(),
          ),
          Positioned(
            bottom: 12,
            left: 12,
            child: _buildCompactDifficultyChip(),
          ),
          if (showDistance)
            Positioned(
              bottom: 12,
              right: 12,
              child: _buildDistanceChip(),
            ),
        ],
      ),
    );
  }

  Widget _buildImage(String? imageUrl) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        color: AppColors.gray200,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: imageUrl != null
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  AppLogger.warning('Failed to load tour image: $imageUrl');
                  return _buildImagePlaceholder();
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildImagePlaceholder();
                },
              )
            : _buildImagePlaceholder(),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: AppColors.gray200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image,
              size: 48,
              color: AppColors.gray500,
            ),
            const SizedBox(height: 8),
            Text(
              tour.category.emoji,
              style: const TextStyle(fontSize: 32),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOverlay() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: .2),
            Colors.transparent,
            Colors.black.withValues(alpha: .6),
          ],
        ),
      ),
    );
  }

  Widget _buildImageContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildImageHeader(),
          const Spacer(),
          _buildImageFooter(),
        ],
      ),
    );
  }

  Widget _buildImageHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildCategoryChip(),
        _buildFavoriteButton(),
      ],
    );
  }

  Widget _buildCategoryChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tour.category.emoji,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 6),
          Text(
            tour.category.displayName,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return GestureDetector(
      onTap: () {
        AppLogger.info('Favorite button tapped for tour: ${tour.title}');
        onFavorite?.call();
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .9),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          size: 20,
          color: isFavorite ? AppColors.error : AppColors.gray600,
        ),
      ),
    );
  }

  Widget _buildImageFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildDifficultyChip(),
        _buildPriceTag(),
      ],
    );
  }

  Widget _buildDifficultyChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tour.difficulty.color.withValues(alpha: .9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tour.difficulty.displayName,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Row(
            children: List.generate(5, (index) {
              return Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(left: 1),
                decoration: BoxDecoration(
                  color: index < tour.difficulty.level
                      ? Colors.white
                      : Colors.white.withValues(alpha: .3),
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '\$${tour.price.toStringAsFixed(0)}',
        style: TextStyle(
          fontSize: 14,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildContentSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitle(),
          const SizedBox(height: 8),
          _buildLocation(),
          const SizedBox(height: 12),
          _buildDescription(),
          const SizedBox(height: 16),
          _buildHighlights(),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      tour.title,
      style: AppTextStyles.cardTitle.copyWith(
        color: AppColors.textPrimary,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildLocation() {
    return Row(
      children: [
        Icon(
          Icons.location_on,
          size: 16,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            tour.startLocation.address,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Text(
      tour.summary.isNotEmpty ? tour.summary : tour.description,
      style: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.textSecondary,
        height: 1.4,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildHighlights() {
    if (tour.highlights.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Highlights',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: tour.highlights.take(3).map((highlight) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                highlight,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFooterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildDurationInfo(),
          _buildParticipantsInfo(),
          _buildRatingInfo(),
        ],
      ),
    );
  }

  Widget _buildDurationInfo() {
    return Row(
      children: [
        Icon(
          Icons.access_time,
          size: 16,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          _formatDuration(tour.duration),
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantsInfo() {
    return Row(
      children: [
        Icon(
          Icons.group,
          size: 16,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          'Max ${tour.maxParticipants}',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingInfo() {
    // TODO: Mock rating - in real app would come from reviews
    const rating = 4.5;
    const reviewCount = 42;
    
    return Row(
      children: [
        Icon(
          Icons.star,
          size: 16,
          color: AppColors.rating,
        ),
        const SizedBox(width: 4),
        Text(
          '$rating ($reviewCount)',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactContentSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitle(),
          const SizedBox(height: 4),
          _buildLocation(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDurationInfo(),
              _buildRatingInfo(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tour.title,
                      style: AppTextStyles.cardTitle.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    _buildLocation(),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  _buildEnhancedPriceTag(),
                  const SizedBox(height: 4),
                  _buildFavoriteButton(),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            tour.summary.isNotEmpty ? tour.summary : tour.description,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDurationInfo(),
              _buildParticipantsInfo(),
              _buildRatingInfo(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedPriceTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '\$${tour.price.toStringAsFixed(0)}',
        style: const TextStyle(
          fontSize: 14,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDistanceChip() {
    // Mock distance - in real app would calculate from user location
    const distance = '2.3 km';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        distance,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildCompactDifficultyChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: tour.difficulty.color.withValues(alpha: .9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tour.difficulty.displayName,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Row(
            children: List.generate(5, (index) {
              return Container(
                width: 3,
                height: 3,
                margin: const EdgeInsets.only(left: 1),
                decoration: BoxDecoration(
                  color: index < tour.difficulty.level
                      ? Colors.white
                      : Colors.white.withValues(alpha: .3),
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
    }
  }
}