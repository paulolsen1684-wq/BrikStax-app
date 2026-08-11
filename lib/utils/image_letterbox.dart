// lib/utils/image_letterbox.dart
//
// Pads a photo out to a fixed aspect ratio instead of cropping it --
// counterpart to image_cropper's crop-based approach. Used specifically
// for Community feed uploads (see community_feed_screen.dart's _pickImage)
// after feedback that a tall/narrow photo (e.g. a portrait phone shot)
// forced through a locked 4:3 crop was losing most of the photo's content
// -- image_cropper is fundamentally a crop tool, it has no "shrink to fit
// and pad the rest" mode, so there was no cropper setting that could fix
// this.
//
// Computes a canvas just big enough to fully CONTAIN the source image at
// the target aspect ratio, centers the source on it, and fills the
// leftover space (bars top/bottom for a too-tall source, bars left/right
// for a too-wide one) with a solid background color -- nothing from the
// original photo is ever cut off, unlike a crop.
import 'dart:io';
import 'package:flutter/material.dart' show Color;
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class ImageLetterbox {
  ImageLetterbox._();

  /// Pads [source] out to [aspect] (width / height), centered, background
  /// filled with [bg]. Returns a new temp file, or null on decode failure
  /// (caller should fall back to the original file rather than blocking
  /// the user).
  static Future<File?> pad(
    File source, {
    double aspect = 4 / 3,
    Color bg = const Color(0xFF0A0907),
  }) async {
    try {
      final bytes = await source.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      final srcAspect = decoded.width / decoded.height;

      int canvasW, canvasH;
      if (srcAspect > aspect) {
        // Source is relatively wider than the target -- keep its width,
        // pad top/bottom.
        canvasW = decoded.width;
        canvasH = (canvasW / aspect).round();
      } else {
        // Source is relatively taller/narrower than the target (the
        // reported case: a tall portrait photo into a 4:3 box) -- keep
        // its height, pad left/right.
        canvasH = decoded.height;
        canvasW = (canvasH * aspect).round();
      }

      final canvas = img.Image(width: canvasW, height: canvasH);
      img.fill(canvas,
          color: img.ColorRgb8(
            (bg.r * 255).round(),
            (bg.g * 255).round(),
            (bg.b * 255).round(),
          ));
      img.compositeImage(canvas, decoded, center: true);

      final outBytes = img.encodeJpg(canvas, quality: 88);

      final tempDir = await getTemporaryDirectory();
      final outPath = path.join(
        tempDir.path,
        'brikstax_padded_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      final outFile = File(outPath);
      await outFile.writeAsBytes(outBytes);
      return outFile;
    } catch (_) {
      return null;
    }
  }
}
