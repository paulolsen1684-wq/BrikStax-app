// lib/services/widget_service.dart
//
// Bridges Flutter data to the native Android home screen widget via the
// home_widget package. Call updateWidget() whenever the collection's
// portfolio value or set count changes.
import 'package:home_widget/home_widget.dart';

class WidgetService {
  WidgetService._();
  static final instance = WidgetService._();

  static const String _androidWidgetName = 'BrikStaxWidgetProvider';

  /// Push fresh stats to the widget and ask Android to redraw it.
  /// Safe to call often — cheap SharedPreferences write + a broadcast.
  Future<void> updateWidget({
    required int setCount,
    required double portfolioValue,
  }) async {
    try {
      await HomeWidget.saveWidgetData<String>('set_count', setCount.toString());
      await HomeWidget.saveWidgetData<String>(
        'portfolio_value',
        portfolioValue > 0 ? '\$${_fmt(portfolioValue)}' : '—',
      );
      await HomeWidget.updateWidget(
        name: _androidWidgetName,
        androidName: _androidWidgetName,
      );
    } catch (_) {
      // Widget update failing (e.g. no widget currently placed on the home
      // screen) should never crash or block the app — just skip silently.
    }
  }

  String _fmt(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  /// Call once at app startup to check if the app was launched via the
  /// widget's Scan button (brikstax://scan). Returns true if so — the
  /// caller should navigate straight to ScannerScreen in that case.
  Future<bool> launchedFromScanWidget() async {
    try {
      final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      return uri?.host == 'scan';
    } catch (_) {
      return false;
    }
  }

  /// Call once at app startup to check if the app was launched via the
  /// Set Lookup widget (brikstax://lookup). Returns true if so — the
  /// caller should navigate straight to SetLookupScreen in that case.
  Future<bool> launchedFromLookupWidget() async {
    try {
      final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      return uri?.host == 'lookup';
    } catch (_) {
      return false;
    }
  }

  /// Call once at app startup to check if the app was launched from the
  /// Random Set widget (brikstax://set/12345). Returns the set number if so,
  /// or null otherwise — the caller should navigate to SetDetailScreen with
  /// that set number in that case.
  Future<String?> launchedFromSetWidget() async {
    try {
      final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (uri?.host == 'set') return uri?.pathSegments.lastOrNull;
    } catch (_) {}
    return null;
  }

  /// Update the Random Set widget with data for a random owned set.
  /// Called from CollectionProvider whenever the collection changes,
  /// to keep the widget data fresh.
  Future<void> updateRandomSetWidget({
    required String setName,
    required String setNum,
    required String setYear,
    required String pieces,
    required String retail,
    required String sealedValue,
  }) async {
    try {
      await HomeWidget.saveWidgetData<String>('random_set_name', setName);
      await HomeWidget.saveWidgetData<String>('random_set_num', setNum);
      await HomeWidget.saveWidgetData<String>('random_set_year', setYear);
      await HomeWidget.saveWidgetData<String>('random_set_pieces', pieces);
      await HomeWidget.saveWidgetData<String>('random_set_retail', retail);
      await HomeWidget.saveWidgetData<String>('random_set_sealed', sealedValue);
      await HomeWidget.updateWidget(
        name: 'RandomSetWidgetProvider',
        androidName: 'RandomSetWidgetProvider',
      );
    } catch (_) {
      // Widget update failing should never crash the app.
    }
  }

  /// Trigger the Avatar/Den widget to refresh from cached den screenshot.
  /// Call this after capturing a den screenshot via DenScreenshotService.
  Future<void> updateDenWidget() async {
    try {
      await HomeWidget.updateWidget(
        name: 'AvatarDenWidgetProvider',
        androidName: 'AvatarDenWidgetProvider',
      );
    } catch (_) {
      // Widget update failing should never crash the app.
    }
  }
}
