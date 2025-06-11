import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';

class MultiImagePicker extends StatefulWidget {
  final List<File> selectedImages;
  final Function(List<File>) onImagesSelected;
  final int maxImages;
  final String title;
  final String emptyStateText;
  final double imageHeight;

  const MultiImagePicker({
    Key? key,
    required this.selectedImages,
    required this.onImagesSelected,
    this.maxImages = 5,
    this.title = 'Images',
    this.emptyStateText = 'No images selected',
    this.imageHeight = 120,
  }) : super(key: key);

  @override
  State<MultiImagePicker> createState() => _MultiImagePickerState();
}

class _MultiImagePickerState extends State<MultiImagePicker> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImages() async {
    final remainingSlots = widget.maxImages - widget.selectedImages.length;
    
    if (remainingSlots <= 0) {
      _showMaxImagesDialog();
      return;
    }

    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 85,
      );

      if (pickedFiles.isNotEmpty) {
        final List<File> newImages = [];
        
        // Limit the number of selected images to remaining slots
        final imagesToAdd = pickedFiles.take(remainingSlots).toList();
        
        for (final pickedFile in imagesToAdd) {
          newImages.add(File(pickedFile.path));
        }

        final updatedImages = [...widget.selectedImages, ...newImages];
        widget.onImagesSelected(updatedImages);

        // Show message if user tried to select more than allowed
        if (pickedFiles.length > remainingSlots) {
          _showLimitReachedMessage(pickedFiles.length - remainingSlots);
        }
      }
    } catch (e) {
      _showErrorDialog('Failed to pick images: $e');
    }
  }

  Future<void> _pickSingleImage() async {
    if (widget.selectedImages.length >= widget.maxImages) {
      _showMaxImagesDialog();
      return;
    }

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final updatedImages = [...widget.selectedImages, File(pickedFile.path)];
        widget.onImagesSelected(updatedImages);
      }
    } catch (e) {
      _showErrorDialog('Failed to pick image: $e');
    }
  }

  Future<void> _takePhoto() async {
    if (widget.selectedImages.length >= widget.maxImages) {
      _showMaxImagesDialog();
      return;
    }

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final updatedImages = [...widget.selectedImages, File(pickedFile.path)];
        widget.onImagesSelected(updatedImages);
      }
    } catch (e) {
      _showErrorDialog('Failed to take photo: $e');
    }
  }

  void _removeImage(int index) {
    final updatedImages = [...widget.selectedImages];
    updatedImages.removeAt(index);
    widget.onImagesSelected(updatedImages);
  }

  void _reorderImages(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    
    final updatedImages = [...widget.selectedImages];
    final item = updatedImages.removeAt(oldIndex);
    updatedImages.insert(newIndex, item);
    widget.onImagesSelected(updatedImages);
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickSingleImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Select Multiple'),
              onTap: () {
                Navigator.pop(context);
                _pickImages();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMaxImagesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Maximum Images Reached'),
        content: Text('You can only add up to ${widget.maxImages} images.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLimitReachedMessage(int extraImages) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$extraImages image(s) were not added due to the ${widget.maxImages} image limit.'),
        backgroundColor: AppColors.warning, // Use AppColors.warning here
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${widget.selectedImages.length}/${widget.maxImages}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        if (widget.selectedImages.isEmpty)
          _buildEmptyState()
        else
          _buildImageGrid(),
        
        const SizedBox(height: 16),
        
        if (widget.selectedImages.length < widget.maxImages)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showImageOptions,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Add Images'),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: widget.imageHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: _showImageOptions,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              size: 48,
              color: AppColors.gray400,
            ),
            const SizedBox(height: 8),
            Text(
              widget.emptyStateText,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to add images',
              style: TextStyle(
                color: AppColors.gray500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      onReorder: _reorderImages,
      itemCount: widget.selectedImages.length,
      itemBuilder: (context, index) {
        final image = widget.selectedImages[index];
        
        return Container(
          key: ValueKey(image.path),
          margin: const EdgeInsets.only(bottom: 8),
          child: Stack(
            children: [
              Container(
                height: widget.imageHeight,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: FileImage(image),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              
              // Primary image indicator
              if (index == 0)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Primary',
                      style: TextStyle(
                        color: AppColors.textOnPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              
              // Remove button
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textOnPrimary, size: 20),
                    onPressed: () => _removeImage(index),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
              
              // Drag handle
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.shadowDark,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.drag_handle,
                    color: AppColors.textOnPrimary,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}