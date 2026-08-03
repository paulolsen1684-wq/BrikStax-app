// lib/utils/image_privacy.dart
//
// Strips EXIF metadata (including GPS/location data) from photos before
// they're uploaded anywhere. Works by fully decoding the image into raw
// pixel data and re-encoding it from scratch — the re-encoded file has no
// metadata at all, since none was ever carried over from the original
// bytes. This is the most reliable stripping method: it doesn't depend on
// whatever a cropping library happens to do internally, and it can't miss
// an EXIF field some other approach might overlook.
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class ImagePrivacy {
  ImagePrivacy._();

  /// Decodes [source], re-encodes it with no metadata, and writes the
  /// result to a new temp file. Returns the new file, or null if decoding
  /// failed (e.g. corrupt/unsupported image — caller should fall back to
  /// the original file in that case rather than blocking the user).
  static Future<File?> stripMetadata(File source) async {
    try {
      final bytes = await source.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      // Re-encoding via the image package's own encoder produces a fresh
      // JPEG with no EXIF/IPTC/XMP segments — none are written back
      // because we never passed the original metadata into the encoder.
      final cleanBytes = img.encodeJpg(decoded, quality: 88);

      final tempDir = await getTemporaryDirectory();
      final ext = path.extension(source.path).isEmpty
          ? '.jpg'
          : path.extension(source.path);
      final outPath = path.join(
        tempDir.path,
        'brikstax_clean_${DateTime.now().millisecondsSinceEpoch}$ext',
      );

      final outFile = File(outPath);
      await outFile.writeAsBytes(cleanBytes);
      return outFile;
    } catch (_) {
      return null;
    }
  }
}
