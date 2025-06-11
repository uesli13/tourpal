import 'dart:io';

/// Result of an image upload operation
class ImageUploadResult {
  final File originalFile;
  final String? downloadUrl;
  final String fileName;
  final Exception? error;
  final bool isSuccess;

  const ImageUploadResult({
    required this.originalFile,
    required this.downloadUrl,
    required this.fileName,
    required this.error,
    required this.isSuccess,
  });

  /// Create a successful upload result
  factory ImageUploadResult.success({
    required File originalFile,
    required String downloadUrl,
    required String fileName,
  }) {
    return ImageUploadResult(
      originalFile: originalFile,
      downloadUrl: downloadUrl,
      fileName: fileName,
      error: null,
      isSuccess: true,
    );
  }

  /// Create a failed upload result
  factory ImageUploadResult.failure({
    required File originalFile,
    required String fileName,
    required Exception error,
  }) {
    return ImageUploadResult(
      originalFile: originalFile,
      downloadUrl: null,
      fileName: fileName,
      error: error,
      isSuccess: false,
    );
  }

  /// Get file size in bytes
  Future<int> get fileSizeBytes async {
    try {
      final stat = await originalFile.stat();
      return stat.size;
    } catch (e) {
      return 0;
    }
  }

  /// Get file size in MB
  Future<double> get fileSizeMB async {
    final bytes = await fileSizeBytes;
    return bytes / (1024 * 1024);
  }

  @override
  String toString() {
    return 'ImageUploadResult{fileName: $fileName, isSuccess: $isSuccess, downloadUrl: $downloadUrl, error: $error}';
  }
}