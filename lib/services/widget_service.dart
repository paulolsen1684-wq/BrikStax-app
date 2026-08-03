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
}
