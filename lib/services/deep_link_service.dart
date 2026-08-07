// lib/services/deep_link_service.dart
//
// Handles deep links from widgets (brikstax://scan, brikstax://lookup, brikstax://set/<num>)
// throughout the app's lifecycle, not just on startup.
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

class DeepLinkService {
  DeepLinkService._();
  static final instance = DeepLinkService._();

  AppLinks? _appLinks;
  VoidCallback? _onScan;
  VoidCallback? _onLookup;
  Function(String)? _onSetDetail;

  /// Initialize deep link listening. Call once in main() before runApp().
  /// Pass callbacks for what to do when each deep link is encountered.
  void init({
    required VoidCallback onScan,
    required VoidCallback onLookup,
    required Function(String setNum) onSetDetail,
  }) {
    _onScan = onScan;
    _onLookup = onLookup;
    _onSetDetail = onSetDetail;
    _appLinks = AppLinks();
    _listenDeepLinks();
  }

  void _listenDeepLinks() {
    _appLinks?.uriLinkStream.listen(
      (uri) {
        if (uri.host == 'scan') {
          _onScan?.call();
        } else if (uri.host == 'lookup') {
          _onLookup?.call();
        } else if (uri.host == 'set' && uri.pathSegments.isNotEmpty) {
          _onSetDetail?.call(uri.pathSegments.first);
        }
      },
      onError: (err) {
        print('DeepLinkService error: $err');
      },
    );
  }
}
