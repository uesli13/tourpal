import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;

class ImageUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  static const int maxImageSizeKB = 500; // 500KB max per image
  static const int imageQuality = 80; // Compression quality (0-100)
  static const int maxImagesPerTour = 10;
  static const int maxImagesPerPlace = 5;

  /// Upload multiple images for a tour cover
  Future<List<String>> uploadTourCoverImages({
    required String tourId,
    required List<File> imageFiles,
  }) async {
    if (imageFiles.length > maxImagesPerTour) {
      throw Exception('Maximum $maxImagesPerTour images allowed per tour');
    }

    final List<String> downloadUrls = [];
    
    for (int i = 0; i < imageFiles.length; i++) {
      try {
        final compressedFile = await _compressImage(imageFiles[i]);
        final fileName = 'tour_cover_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final storageRef = _storage.ref().child('tours/$tourId/covers/$fileName');
        
        final uploadTask = await storageRef.putFile(compressedFile);
        final downloadUrl = await uploadTask.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);
      } catch (e) {
        // If any upload fails, clean up previously uploaded images
        await _cleanupUploadedImages(downloadUrls);
        throw Exception('Failed to upload tour cover image ${i + 1}: $e');
      }
    }
    
    return downloadUrls;
  }

  /// Upload multiple images for a place
  Future<List<String>> uploadPlaceImages({
    required String tourId,
    required String placeId,
    required List<File> imageFiles,
  }) async {
    if (imageFiles.length > maxImagesPerPlace) {
      throw Exception('Maximum $maxImagesPerPlace images allowed per place');
    }

    final List<String> downloadUrls = [];
    
    for (int i = 0; i < imageFiles.length; i++) {
      try {
        final compressedFile = await _compressImage(imageFiles[i]);
        final fileName = 'place_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final storageRef = _storage.ref().child('tours/$tourId/places/$placeId/$fileName');
        
        final uploadTask = await storageRef.putFile(compressedFile);
        final downloadUrl = await uploadTask.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);
      } catch (e) {
        // If any upload fails, clean up previously uploaded images
        await _cleanupUploadedImages(downloadUrls);
        throw Exception('Failed to upload place image ${i + 1}: $e');
      }
    }
    
    return downloadUrls;
  }

  /// Upload a single image (for backward compatibility)
  Future<String> uploadSingleImage({
    required String tourId,
    required File imageFile,
    required String type, // 'cover' or 'place'
    String? placeId,
  }) async {
    final compressedFile = await _compressImage(imageFile);
    final fileName = '${type}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    
    final String storagePath;
    if (type == 'cover') {
      storagePath = 'tours/$tourId/covers/$fileName';
    } else if (type == 'place' && placeId != null) {
      storagePath = 'tours/$tourId/places/$placeId/$fileName';
    } else {
      throw Exception('Invalid upload type or missing placeId for place image');
    }
    
    final storageRef = _storage.ref().child(storagePath);
    final uploadTask = await storageRef.putFile(compressedFile);
    return await uploadTask.ref.getDownloadURL();
  }

  /// Delete images from Firebase Storage
  Future<void> deleteImages(List<String> imageUrls) async {
    for (final url in imageUrls) {
      try {
        final ref = _storage.refFromURL(url);
        await ref.delete();
      } catch (e) {
        print('Warning: Failed to delete image $url: $e');
        // Continue with other deletions even if one fails
      }
    }
  }

  /// Delete all images for a tour
  Future<void> deleteTourImages(String tourId) async {
    try {
      final tourRef = _storage.ref().child('tours/$tourId');
      final result = await tourRef.listAll();
      
      // Delete all files in the tour directory
      for (final item in result.items) {
        await item.delete();
      }
      
      // Recursively delete subdirectories
      for (final prefix in result.prefixes) {
        await _deleteDirectory(prefix);
      }
    } catch (e) {
      print('Warning: Failed to delete tour images for $tourId: $e');
    }
  }

  /// Replace existing images with new ones
  Future<List<String>> replaceImages({
    required List<String> oldImageUrls,
    required List<File> newImageFiles,
    required String tourId,
    required String type,
    String? placeId,
  }) async {
    List<String> newUrls = [];
    
    try {
      // Upload new images first
      if (type == 'cover') {
        newUrls = await uploadTourCoverImages(
          tourId: tourId,
          imageFiles: newImageFiles,
        );
      } else if (type == 'place' && placeId != null) {
        newUrls = await uploadPlaceImages(
          tourId: tourId,
          placeId: placeId,
          imageFiles: newImageFiles,
        );
      }
      
      // Only delete old images if new upload was successful
      await deleteImages(oldImageUrls);
      
      return newUrls;
    } catch (e) {
      // If new upload failed, clean up any uploaded images
      if (newUrls.isNotEmpty) {
        await _cleanupUploadedImages(newUrls);
      }
      rethrow;
    }
  }

  /// Compress image to reduce file size
  Future<File> _compressImage(File imageFile) async {
    try {
      final String targetPath = path.join(
        path.dirname(imageFile.path),
        'compressed_${path.basename(imageFile.path)}',
      );

      final compressedXFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: imageQuality,
        format: CompressFormat.jpeg,
      );

      if (compressedXFile == null) {
        throw Exception('Failed to compress image');
      }

      // Convert XFile to File
      final compressedFile = File(compressedXFile.path);

      // Check if compressed file is within size limit
      final fileSizeKB = await compressedFile.length() / 1024;
      if (fileSizeKB > maxImageSizeKB) {
        // If still too large, compress further
        final secondCompressionXFile = await FlutterImageCompress.compressAndGetFile(
          compressedFile.absolute.path,
          targetPath.replaceAll('.jpg', '_2.jpg'),
          quality: 60, // Lower quality for very large images
          format: CompressFormat.jpeg,
        );
        
        if (secondCompressionXFile != null) {
          await compressedFile.delete(); // Clean up first compression
          return File(secondCompressionXFile.path); // Convert XFile to File
        }
      }

      return compressedFile;
    } catch (e) {
      throw Exception('Failed to compress image: $e');
    }
  }

  /// Clean up uploaded images in case of partial failure
  Future<void> _cleanupUploadedImages(List<String> urls) async {
    for (final url in urls) {
      try {
        final ref = _storage.refFromURL(url);
        await ref.delete();
      } catch (e) {
        print('Warning: Failed to cleanup image $url: $e');
      }
    }
  }

  /// Recursively delete a directory in Firebase Storage
  Future<void> _deleteDirectory(Reference ref) async {
    try {
      final result = await ref.listAll();
      
      for (final item in result.items) {
        await item.delete();
      }
      
      for (final prefix in result.prefixes) {
        await _deleteDirectory(prefix);
      }
    } catch (e) {
      print('Warning: Failed to delete directory ${ref.fullPath}: $e');
    }
  }

  /// Get upload progress stream for multiple files
  Stream<double> getUploadProgress({
    required List<File> files,
    required String tourId,
    required String type,
    String? placeId,
  }) async* {
    double totalProgress = 0.0;
    final int totalFiles = files.length;
    
    for (int i = 0; i < files.length; i++) {
      try {
        final compressedFile = await _compressImage(files[i]);
        final fileName = '${type}_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        
        final String storagePath;
        if (type == 'cover') {
          storagePath = 'tours/$tourId/covers/$fileName';
        } else if (type == 'place' && placeId != null) {
          storagePath = 'tours/$tourId/places/$placeId/$fileName';
        } else {
          throw Exception('Invalid upload type or missing placeId');
        }
        
        final storageRef = _storage.ref().child(storagePath);
        final uploadTask = storageRef.putFile(compressedFile);
        
        await for (final snapshot in uploadTask.snapshotEvents) {
          final fileProgress = snapshot.bytesTransferred / snapshot.totalBytes;
          totalProgress = (i + fileProgress) / totalFiles;
          yield totalProgress;
        }
      } catch (e) {
        throw Exception('Failed to upload file ${i + 1}: $e');
      }
    }
  }
}