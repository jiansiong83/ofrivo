import 'dart:io';

class ImageValidationResult {
  const ImageValidationResult({this.paths = const [], this.error});

  final List<String> paths;
  final String? error;

  bool get isValid => error == null;
}

abstract final class ImageValidation {
  static const defaultMaxBytes = 8 * 1024 * 1024;
  static const supportedExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
    'gif',
    'heic',
    'heif',
  };

  static Future<ImageValidationResult> validatePaths(
    List<String> paths, {
    required int maxCount,
    int maxBytes = defaultMaxBytes,
  }) async {
    if (paths.length > maxCount) {
      return ImageValidationResult(
          error: 'Choose no more than $maxCount images.');
    }
    final normalized = paths.map((path) => path.trim()).toList();
    if (normalized.any((path) => path.isEmpty)) {
      return const ImageValidationResult(error: 'An image path is empty.');
    }
    if (normalized.toSet().length != normalized.length) {
      return const ImageValidationResult(
          error: 'The same image cannot be selected twice.');
    }
    for (final path in normalized) {
      final error = await validatePath(path, maxBytes: maxBytes);
      if (error != null) return ImageValidationResult(error: error);
    }
    return ImageValidationResult(paths: List.unmodifiable(normalized));
  }

  static Future<String?> validatePath(
    String path, {
    int maxBytes = defaultMaxBytes,
  }) async {
    final normalized = path.trim();
    if (normalized.isEmpty) return 'Choose an image file.';
    final extension = _extension(normalized);
    if (!supportedExtensions.contains(extension)) {
      return 'Use a JPG, PNG, WEBP, GIF, or HEIC image.';
    }

    final file = File(normalized);
    if (!await file.exists()) return 'The selected image is no longer available.';
    final length = await file.length();
    if (length == 0) return 'The selected image is empty.';
    if (length > maxBytes) {
      return 'Each image must be smaller than ${maxBytes ~/ (1024 * 1024)} MB.';
    }

    final header = await _readHeader(file);
    if (!_matchesSignature(extension, header)) {
      return 'The selected file is not a supported image.';
    }
    return null;
  }

  static String _extension(String path) {
    final name = path.split(RegExp(r'[\\/]')).last.toLowerCase();
    final dot = name.lastIndexOf('.');
    return dot < 0 ? '' : name.substring(dot + 1);
  }

  static Future<List<int>> _readHeader(File file) async {
    final handle = await file.open();
    try {
      return await handle.read(12);
    } finally {
      await handle.close();
    }
  }

  static bool _matchesSignature(String extension, List<int> bytes) {
    bool startsWith(List<int> signature) {
      if (bytes.length < signature.length) return false;
      for (var index = 0; index < signature.length; index++) {
        if (bytes[index] != signature[index]) return false;
      }
      return true;
    }

    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return startsWith([0xFF, 0xD8, 0xFF]);
      case 'png':
        return startsWith([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
      case 'gif':
        return startsWith([0x47, 0x49, 0x46, 0x38]);
      case 'webp':
        return startsWith([0x52, 0x49, 0x46, 0x46]) &&
            bytes.length >= 12 &&
            String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP';
      case 'heic':
      case 'heif':
        return bytes.length >= 8 &&
            String.fromCharCodes(bytes.sublist(4, 8)) == 'ftyp';
      default:
        return false;
    }
  }
}
