// lib/services/den_screenshot_service.dart
//
// Captures a screenshot of the user's den/avatar and caches it for display on the Den widget.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

class DenScreenshotService {
  DenScreenshotService._();
  static final instance = DenScreenshotService._();

  static const String _cachedFileName = 'den_screenshot.png';
  GlobalKey<State>? _denKey;

  /// Register the GlobalKey for the den scene widget that should be captured.
  void registerDenKey(GlobalKey<State> key) {
    _denKey = key;
  }

  /// Capture the den scene widget and cache it as a PNG.
  /// Returns the path to the cached file, or null if capture fails.
  Future<String?> captureDen() async {
    try {
      final renderObject = _denKey?.currentContext?.findRenderObject();
      if (renderObject == null || renderObject is! RenderRepaintBoundary) {
        return null;
      }

      // Capture the widget as an image
      final image = await renderObject.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData?.buffer.asUint8List();

      if (bytes == null) return null;

      // Save to cache directory
      final cacheDir = await getTemporaryDirectory();
      final file = File('${cacheDir.path}/$_cachedFileName');
      await file.writeAsBytes(bytes);

      return file.path;
    } catch (e) {
      print('DenScreenshotService error: $e');
      return null;
    }
  }

  /// Get the path to the cached den screenshot, if it exists.
  /// Returns null if no cached screenshot is available.
  Future<String?> getCachedDenPath() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final file = File('${cacheDir.path}/$_cachedFileName');
      if (await file.exists()) {
        return file.path;
      }
    } catch (_) {}
    return null;
  }

  /// Clear the cached den screenshot.
  Future<void> clearCache() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final file = File('${cacheDir.path}/$_cachedFileName');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
