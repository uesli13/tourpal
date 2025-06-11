import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/image_upload_result.dart';

class MultiImageUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload multiple images for a tour
  Future<List<String>> uploadTourImages({
    required String tourId,
    required List<File> images,
    Function(double)? onProgress,
  }) async {
    return _uploadImages(
      images: images,
      basePath: 'tours/$tourId/images',
      onProgress: onProgress,
    );
  }

  /// Upload multiple images for a place within a tour
  Future<List<String>> uploadPlaceImages({
    required String tourId,
    required String placeId,
    required List<File> images,
    Function(double)? onProgress,
  }) async {
    return _uploadImages(
      images: images,
      basePath: 'tours/$tourId/places/$placeId/images',
      onProgress: onProgress,
    );
  }

  /// Upload a single cover image for a tour
  Future<String> uploadTourCoverImage({
    required String tourId,
    required File image,
    Function(double)? onProgress,
  }) async {
    final results = await _uploadImages(
      images: [image],
      basePath: 'tours/$tourId/cover',
      onProgress: onProgress,
    );
    return results.first;
  }

  /// Upload multiple images with detailed progress tracking
  Future<List<ImageUploadResult>> uploadImagesWithProgress({
    required List<File> images,
    required String basePath,
  }) async {
    final results = <ImageUploadResult>[];
    
    for (int i = 0; i < images.length; i++) {
      final image = images[i];
      final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}_$i${path.extension(image.path)}';
      
      try {
        // Compress image before upload
        final compressedImage = await _compressImage(image);
        
        final ref = _storage.ref().child('$basePath/$fileName');
        final uploadTask = ref.putFile(compressedImage);
        
        String? downloadUrl;
        Exception? error;
        
        try {
          final snapshot = await uploadTask;
          downloadUrl = await snapshot.ref.getDownloadURL();
        } catch (e) {
          error = e as Exception;
        }
        
        results.add(ImageUploadResult(
          originalFile: image,
          downloadUrl: downloadUrl,
          fileName: fileName,
          error: error,
          isSuccess: downloadUrl != null,
        ));
        
        // Clean up compressed file if it's different from original
        if (compressedImage.path != image.path) {
          await compressedImage.delete();
        }
      } catch (e) {
        results.add(ImageUploadResult(
          originalFile: image,
          downloadUrl: null,
          fileName: fileName,
          error: e as Exception,
          isSuccess: false,
        ));
      }
    }
    
    return results;
  }

  /// Internal method to upload multiple images
  Future<List<String>> _uploadImages({
    required List<File> images,
    required String basePath,
    Function(double)? onProgress,
  }) async {
    final downloadUrls = <String>[];
    
    for (int i = 0; i < images.length; i++) {
      final image = images[i];
      final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}_$i${path.extension(image.path)}';
      
      try {
        // Compress image before upload
        final compressedImage = await _compressImage(image);
        
        final ref = _storage.ref().child('$basePath/$fileName');
        final uploadTask = ref.putFile(compressedImage);
        
        // Track progress for individual file
        uploadTask.snapshotEvents.listen((snapshot) {
          final progress = (i + (snapshot.bytesTransferred / snapshot.totalBytes)) / images.length;
          onProgress?.call(progress);
        });
        
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);
        
        // Clean up compressed file if it's different from original
        if (compressedImage.path != image.path) {
          await compressedImage.delete();
        }
      } catch (e) {
        throw Exception('Failed to upload image ${i + 1}: $e');
      }
    }
    
    return downloadUrls;
  }

  /// Compress image to reduce file size and improve upload speed
  Future<File> _compressImage(File image) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = path.basename(image.path);
      final targetPath = path.join(tempDir.path, 'compressed_$fileName');
      
      final compressedImage = await FlutterImageCompress.compressAndGetFile(
        image.absolute.path,
        targetPath,
        quality: 85,
        minWidth: 800,
        minHeight: 600,
        format: CompressFormat.jpeg,
      );
      
      return compressedImage != null ? File(compressedImage.path) : image;
    } catch (e) {
      // If compression fails, return original image
      return image;
    }
  }

  /// Delete images from Firebase Storage
  Future<void> deleteImages(List<String> imageUrls) async {
    for (final url in imageUrls) {
      try {
        final ref = _storage.refFromURL(url);
        await ref.delete();
      } catch (e) {
        // Continue deleting other images even if one fails
        print('Failed to delete image: $url, Error: $e');
      }
    }
  }

  /// Delete all images for a tour
  Future<void> deleteTourImages(String tourId) async {
    try {
      final ref = _storage.ref().child('tours/$tourId');
      final listResult = await ref.listAll();
      
      // Delete all files in the tour directory
      for (final item in listResult.items) {
        await item.delete();
      }
      
      // Recursively delete subdirectories
      for (final prefix in listResult.prefixes) {
        await _deleteDirectory(prefix);
      }
    } catch (e) {
      throw Exception('Failed to delete tour images: $e');
    }
  }

  /// Recursively delete a directory and its contents
  Future<void> _deleteDirectory(Reference ref) async {
    try {
      final listResult = await ref.listAll();
      
      // Delete all files
      for (final item in listResult.items) {
        await item.delete();
      }
      
      // Recursively delete subdirectories
      for (final prefix in listResult.prefixes) {
        await _deleteDirectory(prefix);
      }
    } catch (e) {
      print('Failed to delete directory: ${ref.fullPath}, Error: $e');
    }
  }

  /// Get the file size of an image
  Future<int> getImageFileSize(File image) async {
    try {
      final stat = await image.stat();
      return stat.size;
    } catch (e) {
      return 0;
    }
  }

  /// Validate image files before upload
  Future<List<String>> validateImages(List<File> images, {int maxSizeInMB = 10}) async {
    final errors = <String>[];
    final maxSizeInBytes = maxSizeInMB * 1024 * 1024;
    
    for (int i = 0; i < images.length; i++) {
      final image = images[i];
      
      // Check if file exists
      if (!await image.exists()) {
        errors.add('Image ${i + 1}: File does not exist');
        continue;
      }
      
      // Check file size
      final size = await getImageFileSize(image);
      if (size > maxSizeInBytes) {
        errors.add('Image ${i + 1}: File size (${(size / 1024 / 1024).toStringAsFixed(1)}MB) exceeds ${maxSizeInMB}MB limit');
      }
      
      // Check file extension
      final extension = path.extension(image.path).toLowerCase();
      const allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
      if (!allowedExtensions.contains(extension)) {
        errors.add('Image ${i + 1}: Unsupported file format ($extension)');
      }
    }
    
    return errors;
  }
}