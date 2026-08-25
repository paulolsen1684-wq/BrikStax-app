// lib/main.dart — BrikStax
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'modules/avatar/avatar_module.dart';
import 'modules/avatar/services/hidden_theme_service.dart';
import 'modules/avatar/services/dev_mode.dart';
import 'modules/avatar/services/daily_five_service.dart';
import 'providers/collection.dart';
import 'services/wishlist_service.dart';
import 'modules/community/services/community_service.dart';
import 'services/feature_flag_service.dart';
import 'services/device_identity.dart';
import 'screens/dashboard.dart';
import 'screens/inventory.dart';
import 'screens/scanner.dart';
import 'screens/settings.dart';
import 'screens/add_set.dart';
import 'screens/wishlist_screen.dart';
import 'screens/community_feed_screen.dart';
import 'screens/set_lookup_screen.dart';
import 'screens/set_detail.dart';
import 'theme/app_theme.dart';
import 'services/theme_service.dart';
import 'theme/app_themes.dart';
import 'utils/brik_page_route.dart';
import 'services/widget_service.dart';
import 'services/deep_link_service.dart';
import 'services/local_notification_service.dart';
import 'services/whats_new_service.dart';
import 'services/push_service.dart';
import 'widgets/whats_new_popup.dart';

/// Flip to false to hide the Wishlist tab everywhere. Single source of truth.
const bool kWishlistEnabled = true;
/// Flip to false to hide the Community tab everywhere.
const bool kCommunityEnabled = true;

// Sentry project DSN — paste yours from sentry.io (Settings → Client Keys).
// A DSN isn't a secret (it's a write-only client identifier, same trust
// level as the Rebrickable/BrickSet keys already embedded elsewhere in this
// app) so it's fine committed here. Left blank, Sentry's SDK silently
// no-ops instead of erroring — safe to ship as-is until a real value lands.
const String _kSentryDsn =
    'https://0160da363ec184032237bdb7866495a4@o4511775363825664.ingest.us.sentry.io/4511775367168000';

void main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = _kSentryDsn;
      options.environment = kReleaseMode ? 'production' : 'debug';
    },
    appRunner: () async {
      WidgetsFlutterBinding.ensureInitialized();
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

      await AchievementService.instance.init();
      await LootService.instance.init();
      await DevMode.instance.init();
      await DailyFiveService.instance.init();
      // Real feature (not dev-gated, unlike push_service.dart's FCM stack)
      // -- fully on-device, so there's no server-side risk in initializing
      // it for every user. restoreOptedIn() only actually schedules
      // anything if the Settings toggle was previously turned on.
      await LocalNotificationService.instance.init();
      await LocalNotificationService.instance.restoreOptedIn();
      await HiddenThemeService.instance.init();
      await WishlistService.instance.init();
      await ThemeService.instance.init();
      await FeatureFlagService.instance.init();
      await DeviceIdentity.instance.init();
      await WhatsNewService.instance.init();

      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => CollectionProvider()..init()),
            ChangeNotifierProvider.value(value: WishlistService.instance),
            ChangeNotifierProvider.value(value: CommunityService.instance),
          ],
          child: const BrikStaxApp(),
        ),
      );
    },
  );
}

class BrikStaxApp extends StatelessWidget {
  const BrikStaxApp({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: ThemeService.instance,
    builder: (_, __) {
      final svc = ThemeService.instance;
      return MaterialApp(
        title: 'BrikStax',
        debugShowCheckedModeBanner: false,
        theme: svc.activeTheme,
        home: const _Shell(),
      );
    },
  );
}

class _Shell extends StatefulWidget {
  const _Shell();
  @override State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _checkWidgetLaunch();
    _initDeepLinks();
    _checkWhatsNew();
    // Silent, automatic push activation -- no Settings toggle, see
    // push_service.dart's header comment. Safe to fire-and-forget on every
    // launch: gated behind DevMode/FeatureFlagService internally, so this
    // is a cheap no-op for the vast majority of users until the server
    // flag is flipped on.
    PushService.instance.maybeAutoActivate(DeviceIdentity.instance.id);
  }

  // One-time "What's New" intro popup -- a version can have any number of
  // published quests (see whats_new_service.dart), each shown exactly
  // once, oldest-unseen-first, one per launch rather than all stacked in
  // the same session. Never again once markIntroSeen() (called inside
  // WhatsNewPopup.show itself) has recorded that specific quest's id. A
  // quest still in progress on a later launch is surfaced by
  // widgets/whats_new_banner.dart on the Dashboard instead of re-showing
  // this popup every time. Runs after the widget launch/deep-link checks
  // above so a scan/lookup/set-detail redirect from a home-screen widget
  // still takes priority over an announcement popping up mid-navigation.
  void _checkWhatsNew() {
    final entry = WhatsNewService.instance.nextUnseenEntry;
    if (entry == null || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) WhatsNewPopup.show(context, entry);
    });
  }

  /// Initialize deep link listener for ongoing widget navigation during app lifetime.
  void _initDeepLinks() {
    DeepLinkService.instance.init(
      onScan: _goToScanner,
      onLookup: _goToSetLookup,
      onSetDetail: _goToSetDetail,
    );
  }

  void _goToScanner() {
    if (mounted) {
      Navigator.push(context, BrikPageRoute(page: const ScannerScreen()));
    }
  }

  void _goToSetLookup() {
    if (mounted) {
      Navigator.push(context, BrikPageRoute(page: const SetLookupScreen()));
    }
  }

  void _goToSetDetail(String setNum) {
    if (mounted) {
      final collection = context.read<CollectionProvider>();
      final sets = collection.sets.where((s) => s.num == setNum).toList();
      final screen = sets.isNotEmpty
          ? SetDetailScreen(setId: sets.first.id)
          : const DashboardScreen();
      Navigator.push(context, BrikPageRoute(page: screen));
    }
  }

  // If the app was opened via the home screen widget's "Scan" button
  // (brikstax://scan), jump straight to the scanner instead of landing
  // on the normal Dashboard start.
  Future<void> _checkWidgetLaunch() async {
    final fromScanWidget = await WidgetService.instance.launchedFromScanWidget();
    final fromLookupWidget = await WidgetService.instance.launchedFromLookupWidget();
    final setNum = await WidgetService.instance.launchedFromSetWidget();

    if ((fromScanWidget || fromLookupWidget || setNum != null) && mounted) {
      // Wait for the first frame so Navigator/context are fully ready.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Widget screen;
          if (fromScanWidget) {
            screen = const ScannerScreen();
          } else if (fromLookupWidget) {
            screen = const SetLookupScreen();
          } else {
            // setNum is not null — find the set in the collection by number
            final collection = context.read<CollectionProvider>();
            final sets = collection.sets.where((s) => s.num == setNum).toList();
            screen = sets.isNotEmpty
                ? SetDetailScreen(setId: sets.first.id)
                : const DashboardScreen();
          }
          Navigator.push(context, BrikPageRoute(page: screen));
        }
      });
    }
  }

  // Body screens (scanner is excluded — it opens as a modal).
  // Wishlist and Community are appended only when their flags are on.
  // Index map: 0 Home · 1 Sets · 2 Tools (Settings screen) · 3 Wishlist · 4 Community
  List<Widget> get _bodyScreens => [
    const DashboardScreen(),
    const InventoryScreen(),
    const SettingsScreen(),
    if (kWishlistEnabled)  const WishlistScreen(),
    if (kCommunityEnabled) const CommunityFeedScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(index: _tab, children: _bodyScreens),
      bottomNavigationBar: _BottomNav(
        current: _tab,
        onScan: () => Navigator.push(context,
            BrikPageRoute(page: const ScannerScreen())),
        onTab: (i) => setState(() => _tab = i),
      ),
      floatingActionButton: _tab == 1
          ? FloatingActionButton(
              heroTag: 'wishlist_fab',
              onPressed: () => Navigator.push(context,
                  BrikPageRoute(page: const AddSetScreen())),
              backgroundColor: BT.yellow,
              foregroundColor: BT.ink,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: BT.ink, width: BT.bw),
              ),
              elevation: 0,
              child: const Icon(Icons.add, size: 26),
            )
          : null,
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int current;
  final VoidCallback onScan;
  final void Function(int) onTab;
  const _BottomNav({
    required this.current,
    required this.onScan,
    required this.onTab,
  });

  @override
  Widget build(BuildContext context) {
    final bt = context.bt;
    return Container(
      height: 68 + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        color: bt.navBg,
        border: Border(top: BorderSide(color: bt.cardBorder, width: BT.bw)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom),
        child: Row(children: [
          _btn(context, Icons.grid_view_outlined, Icons.grid_view, 'Home',
              active: current == 0, onTap: () => onTab(0)),
          _btn(context, Icons.inventory_2_outlined, Icons.inventory_2, 'Sets',
              active: current == 1, onTap: () => onTab(1)),

          // Scan — centre action, opens modal
          Expanded(child: GestureDetector(
            onTap: onScan,
            behavior: HitTestBehavior.opaque,
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(Icons.qr_code_scanner,
                    color: bt.navInactive, size: 22),
              ),
              const SizedBox(height: 2),
              Text('Scan',
                  style: BT.mono(size: 8, color: bt.navInactive)),
            ]),
          )),

          if (kCommunityEnabled)
            _btn(context, Icons.photo_library_outlined, Icons.photo_library,
                'Community',
                active: current == 4, onTap: () => onTab(4)),

          if (kWishlistEnabled)
            _btn(context, Icons.favorite_border, Icons.favorite, 'Wishlist',
                active: current == 3, onTap: () => onTab(3)),

          _btn(context, Icons.settings_outlined, Icons.settings, 'Tools',
              active: current == 2, onTap: () => onTab(2)),
        ]),
      ),
    );
  }

  Widget _btn(BuildContext context, IconData icon, IconData activeIcon,
      String label,
      {required bool active, required VoidCallback onTap}) {
    final bt = context.bt;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: active ? bt.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(13),
              border: active
                  ? Border.all(color: bt.cardBorder, width: BT.bw)
                  : null,
            ),
            child: Icon(active ? activeIcon : icon,
                color: active ? bt.navBg : bt.navInactive, size: 22),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: BT.mono(size: 8,
                  color: active ? bt.navActive : bt.navInactive,
                  weight: active
                      ? FontWeight.w500 : FontWeight.w400)),
        ]),
      ),
    );
  }
}
