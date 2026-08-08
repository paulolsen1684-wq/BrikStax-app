// lib/screens/settings.dart — BrikStax Brick UI
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/collection.dart';
import '../theme/app_theme.dart';
import '../theme/app_themes.dart';
import '../widgets/atoms.dart';
import '../screens/theme_picker_screen.dart';
import '../modules/avatar/services/dev_mode.dart';
import '../modules/avatar/widgets/pixel_avatar_preview_screen.dart';
import '../modules/avatar/widgets/pixel_item_tuner_screen.dart';
import '../modules/avatar/widgets/den_layout_tuner_screen.dart';
import 'push_test_screen.dart';
import 'deal_history_screen.dart';
import '../services/push_service.dart';
import '../services/device_identity.dart';
import 'package:http/http.dart' as http;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override State<SettingsScreen> createState() => _State();
}

class _State extends State<SettingsScreen> {
  bool _fillRetailBusy = false;
  bool _fillImagesBusy = false;
  bool _importRbBusy   = false;
  int  _progDone = 0, _progTotal = 0;
  final _rbCtrl = TextEditingController();

  static const String _kFeedbackForm  = 'https://docs.google.com/forms/d/e/1FAIpQLSes471gG7jptEtzWDtJ3zB5haOXwu4Td_loctCvAYz9sk5TYw/viewform';
  static const String _kPrivacyPolicy = 'https://brikstax.pages.dev/privacy';
  static const String _kTermsOfService= 'https://brikstax.pages.dev/terms';
  static const String _kPlayListing   =
      'https://play.google.com/store/apps/details?id=com.brixstax.android';

  @override
  void dispose() { _rbCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final bt = context.bt;

    return Consumer<CollectionProvider>(
      builder: (_, col, __) => CustomScrollView(
        slivers: [

          // ── Header ───────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              decoration: BoxDecoration(
                color: bt.surface,
                border: Border(bottom: BorderSide(color: bt.cardBorder, width: BT.bw)),
              ),
              child: SafeArea(
                bottom: false,
                child: Row(children: [
                  Text('BrikStax', style: BT.display(size: 26, color: bt.tx)),
                  const Spacer(),
                  Text('v2.1.0', style: BT.mono(size: 9, color: bt.tx3)),
                ]),
              ),
            ),
          ),

          // ── Appearance ───────────────────────────────────────────────────
          _header(bt, 'Appearance'),
          _tile(bt,
            icon: Icons.palette_outlined, bg: BT.yellowBg,
            iconColor: BT.gold,
            title: 'Themes',
            sub: 'Choose your colour palette · unlock new themes',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ThemePickerScreen())),
          ),

          // ── Deals ────────────────────────────────────────────────────────
          // Every deal posted via Discord's /deal etc. lives on the server,
          // but DealOfDayCard only ever surfaces the single most recent one
          // -- this is the only place the rest are actually visible.
          _header(bt, 'Deals'),
          _tile(bt,
            icon: Icons.local_offer_outlined, bg: const Color(0xFFE1F5EE),
            iconColor: BT.green,
            title: 'Deal History',
            sub: 'Every live deal, not just today\'s featured one',
            onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const DealHistoryScreen())),
          ),

          // ── Notifications ────────────────────────────────────────────────
          // Real feature UI (not a raw test screen), but still dev-gated
          // for now -- see push_service.dart's header comment. Once ready
          // for everyone, this whole `if` just gets removed; nothing about
          // the widget itself needs to change.
          if (DevMode.instance.isOn) ...[
            _header(bt, 'Notifications'),
            const SliverToBoxAdapter(child: _NotificationsOptIn()),
          ],

          // ── eBay ─────────────────────────────────────────────────────────
          _header(bt, 'eBay Prices'),
          _tile(bt,
            icon: Icons.refresh, bg: const Color(0xFFFFF0E6),
            iconColor: BT.orange,
            title: 'Refresh eBay prices',
            sub: '${col.quotaLeft}/3 calls remaining · only fetches stale sets',
            busy: col.ebayState == RefreshState.running,
            onTap: col.ebayState == RefreshState.running || col.quotaLeft <= 0
                ? null
                : () => col.refreshEbay(onError: (e) => _snack(e)),
          ),
          _tile(bt,
            icon: Icons.refresh_outlined, bg: bt.surface2,
            iconColor: bt.tx2,
            title: 'Force refresh all',
            sub: 'Ignores staleness — re-fetches all sets',
            onTap: col.ebayState == RefreshState.running || col.quotaLeft <= 0
                ? null
                : () => col.refreshEbay(forceAll: true, onError: (e) => _snack(e)),
          ),
          if (DevMode.instance.isOn)
            const SliverToBoxAdapter(child: _EbayUsageTile()),

          if (DevMode.instance.isOn) ...[
            _header(bt, 'Developer'),
            _tile(bt,
              icon: Icons.face_retouching_natural, bg: bt.surface2,
              iconColor: bt.tx2,
              title: 'Pixel Avatar Preview',
              sub: 'New ground-up art system — not live yet',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const PixelAvatarPreviewScreen())),
            ),
            _tile(bt,
              icon: Icons.open_with, bg: bt.surface2,
              iconColor: bt.tx2,
              title: 'Item Position Tuner',
              sub: 'Drag/pinch to fix outlier items one at a time',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const PixelItemTunerScreen())),
            ),
            _tile(bt,
              icon: Icons.chair_alt, bg: bt.surface2,
              iconColor: bt.tx2,
              title: 'Den Layout Tuner',
              sub: 'Drag/pinch the avatar and item placement in the Den',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const DenLayoutTunerScreen())),
            ),
            _tile(bt,
              icon: Icons.notifications_active_outlined, bg: bt.surface2,
              iconColor: bt.tx2,
              title: 'Push Notifications (Dev)',
              sub: 'FCM token + registration test — Android only, not sending yet',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const PushTestScreen())),
            ),
          ],

          // ── Fill missing ─────────────────────────────────────────────────
          _header(bt, 'Fill missing data'),
          _tile(bt,
            icon: Icons.sell_outlined, bg: BT.yellowBg,
            iconColor: BT.gold,
            title: 'Fill retail prices',
            sub: _fillRetailBusy
                ? 'Filling $_progDone / $_progTotal…'
                : 'Auto-fill MSRP from BrickSet',
            busy: _fillRetailBusy,
            progress: _progTotal > 0 ? _progDone / _progTotal : null,
            onTap: _fillRetailBusy ? null : () => _fillRetail(col),
          ),
          _tile(bt,
            icon: Icons.image_outlined, bg: BT.yellowBg,
            iconColor: BT.gold,
            title: 'Fill images',
            sub: _fillImagesBusy
                ? 'Fetching $_progDone / $_progTotal…'
                : 'Pull set images from Rebrickable',
            busy: _fillImagesBusy,
            progress: _progTotal > 0 ? _progDone / _progTotal : null,
            onTap: _fillImagesBusy ? null : () => _fillImages(col),
          ),

          // ── Import ───────────────────────────────────────────────────────
          _header(bt, 'Import'),
          _tile(bt,
            icon: Icons.cloud_download_outlined, bg: BT.greenBg,
            iconColor: BT.green,
            title: 'Import from Rebrickable',
            sub: 'Sync your full Rebrickable collection',
            busy: _importRbBusy,
            onTap: () => _showRbImport(col),
          ),

          // ── Export ───────────────────────────────────────────────────────
          _header(bt, 'Export'),
          _tile(bt,
            icon: Icons.ios_share_outlined, bg: bt.surface2,
            iconColor: bt.tx2,
            title: 'Backup collection',
            sub: 'Share .json · store offline',
            onTap: () => _backupJson(col),
          ),
          _tile(bt,
            icon: Icons.table_chart_outlined, bg: bt.surface2,
            iconColor: bt.tx2,
            title: 'Export CSV',
            sub: 'Open in Excel · Sheets · Numbers',
            onTap: () => _exportCsv(col),
          ),

          // ── Feedback & support ───────────────────────────────────────────
          _header(bt, 'Feedback & support'),
          _tile(bt,
            icon: Icons.feedback_outlined, bg: BT.yellowBg,
            iconColor: BT.gold,
            title: 'Send feedback',
            sub: 'Report a bug or share an idea',
            onTap: () => _openUrl(_kFeedbackForm, 'feedback form'),
          ),
          _tile(bt,
            icon: Icons.star_outline, bg: BT.yellowBg,
            iconColor: BT.gold,
            title: 'Rate BrikStax',
            sub: 'Leave a review on Google Play',
            onTap: () => _openUrl(_kPlayListing, 'Play Store'),
          ),

          // ── Restore ──────────────────────────────────────────────────────
          _header(bt, 'Restore'),
          _tile(bt,
            icon: Icons.settings_backup_restore, bg: BT.greenBg,
            iconColor: BT.green,
            title: 'Restore from backup',
            sub: 'Paste a backup .json to import your sets',
            onTap: () => _showRestore(col),
          ),

          // ── Legal & about ────────────────────────────────────────────────
          _header(bt, 'Legal & about'),
          _tile(bt,
            icon: Icons.privacy_tip_outlined, bg: bt.surface2,
            iconColor: bt.tx2,
            title: 'Privacy policy',
            sub: 'How your data is handled',
            onTap: () => _openUrl(_kPrivacyPolicy, 'privacy policy'),
          ),
          _tile(bt,
            icon: Icons.description_outlined, bg: bt.surface2,
            iconColor: bt.tx2,
            title: 'Terms of service',
            sub: 'The rules for using BrikStax',
            onTap: () => _openUrl(_kTermsOfService, 'terms'),
          ),
          _tile(bt,
            icon: Icons.info_outline, bg: bt.surface2,
            iconColor: bt.tx2,
            title: 'About BrikStax',
            sub: 'Version, credits & data sources',
            onTap: () => _showAbout(bt),
          ),

          // ── Danger ───────────────────────────────────────────────────────
          _header(bt, 'Danger zone'),
          _tile(bt,
            icon: Icons.delete_outline, bg: BT.redBg,
            iconColor: BT.red,
            title: 'Clear all data',
            sub: 'Remove all sets — cannot be undone. Backup first!',
            onTap: () => _clearAll(col, bt),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
    );
  }

  // ── Handlers ─────────────────────────────────────────────────────────────

  Future<void> _fillRetail(CollectionProvider col) async {
    setState(() { _fillRetailBusy = true; _progDone = 0; _progTotal = 0; });
    final ok = await col.fillRetail(
        onProgress: (d, t) => setState(() { _progDone=d; _progTotal=t; }));
    setState(() => _fillRetailBusy = false);
    _snack('Filled $ok retail price${ok!=1?"s":""}');
  }

  Future<void> _fillImages(CollectionProvider col) async {
    setState(() { _fillImagesBusy = true; _progDone = 0; _progTotal = 0; });
    final ok = await col.fillImages(
        onProgress: (d, t) => setState(() { _progDone=d; _progTotal=t; }));
    setState(() => _fillImagesBusy = false);
    _snack('Updated $ok image${ok!=1?"s":""}');
  }

  void _showRbImport(CollectionProvider col) {
    final bt = context.bt;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: bt.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: bt.cardBorder, width: BT.bw),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 20, right: 20, top: 20,
          ),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SheetHandle(),
            const SizedBox(height: 14),
            Text('Import from Rebrickable',
                style: BT.display(size: 24, color: bt.tx)),
            const SizedBox(height: 6),
            Text(
              'Enter your Rebrickable user token.\n'
              'Find it at rebrickable.com → Settings → API',
              style: BT.mono(size: 11, color: bt.tx2),
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: bt.cardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: bt.cardBorder, width: BT.bw),
                boxShadow: [BoxShadow(color: bt.shadowColor,
                    offset: const Offset(2, 2))],
              ),
              child: TextField(
                controller: _rbCtrl,
                style: BT.mono(size: 14, color: bt.tx),
                decoration: InputDecoration(
                  hintText: 'e.g. abc123xyz',
                  hintStyle: BT.mono(size: 14, color: bt.txMuted),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  fillColor: bt.cardBg,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: _importRbBusy ? null : () async {
                final token = _rbCtrl.text.trim();
                if (token.isEmpty) return;
                setState(() => _importRbBusy = true);
                Navigator.pop(ctx);
                final count = await col.importFromRebrickable(token);
                setState(() => _importRbBusy = false);
                _snack('Imported $count set${count!=1?"s":""}');
              },
              child: _importRbBusy
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(BT.yellow))
                  : const Text('Import collection'),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _backupJson(CollectionProvider col) async {
    final data = jsonEncode({
      'sets': col.exportJson(),
      'v': 'v2', 'app': 'BrikStax',
      'date': DateTime.now().toIso8601String(),
    });
    await Share.share(data,
        subject: 'brikstax-${DateTime.now().toIso8601String().substring(0,10)}.json');
  }

  Future<void> _exportCsv(CollectionProvider col) async {
    const hdr = 'Set #,Name,Condition,Qty,Pieces,Year,'
        'Retail,Paid,eBay Sealed,eBay Open,ROI %,Source,Notes,Retired';
    final rows = col.sets.map((s) => [
      s.num, '"${s.name.replaceAll('"', '""')}"',
      s.status, s.qty, s.pieces ?? '', s.year ?? '',
      s.retail ?? '', s.paid ?? '',
      s.ebaySealed ?? '', s.ebayOpen ?? '',
      s.roi != null ? s.roi!.toStringAsFixed(2) : '',
      s.purchaseSource.label,
      '"${s.notes.replaceAll('"', '""')}"',
      s.retired ? 'yes' : 'no',
    ].join(',')).join('\n');
    await Share.share('$hdr\n$rows',
        subject: 'brikstax-${DateTime.now().toIso8601String().substring(0,10)}.csv');
  }

  Future<void> _clearAll(CollectionProvider col, BrikStaxColors bt) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bt.cardBg,
        title: Text('Clear all data?',
            style: BT.display(size: 22, color: bt.tx)),
        content: Text(
          'All ${col.count} sets will be permanently deleted.',
          style: BT.mono(size: 12, color: bt.tx2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: BT.body(size: 14, color: bt.tx2)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: BT.red, foregroundColor: Colors.white),
            child: const Text('Delete all'),
          ),
        ],
      ),
    );
    if (ok == true) {
      for (final s in col.sets.toList()) await col.remove(s.id);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _openUrl(String url, String label) async {
    if (url.contains('YOUR_')) {
      _snack('$label link not set yet');
      return;
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _snack('Could not open the $label');
    }
  }

  void _showRestore(CollectionProvider col) {
    final bt = context.bt;
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: bt.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: bt.cardBorder, width: BT.bw),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 20, right: 20, top: 20,
          ),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SheetHandle(),
            const SizedBox(height: 14),
            Text('Restore from backup',
                style: BT.display(size: 24, color: bt.tx)),
            const SizedBox(height: 6),
            Text(
              'Paste the contents of a BrikStax backup .json file below. '
              'Your existing sets are kept — restored sets are merged in.',
              style: BT.mono(size: 11, color: bt.tx2),
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: bt.cardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: bt.cardBorder, width: BT.bw),
                boxShadow: [BoxShadow(color: bt.shadowColor,
                    offset: const Offset(2, 2))],
              ),
              child: TextField(
                controller: ctrl,
                maxLines: 6,
                style: BT.mono(size: 12, color: bt.tx),
                decoration: InputDecoration(
                  hintText: '{"sets":[...],"v":"v2",...}',
                  hintStyle: BT.mono(size: 12, color: bt.txMuted),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  fillColor: bt.cardBg,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () async {
                final raw = ctrl.text.trim();
                if (raw.isEmpty) return;
                Navigator.pop(ctx);
                await _doRestore(col, raw);
              },
              child: const Text('Restore collection'),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _doRestore(CollectionProvider col, String raw) async {
    try {
      final decoded = jsonDecode(raw);
      final List<dynamic> sets = decoded is Map
          ? (decoded['sets'] as List<dynamic>? ?? [])
          : (decoded as List<dynamic>);
      if (sets.isEmpty) { _snack('No sets found in that backup'); return; }
      final count = await col.importJson(sets);
      _snack('Restored $count set${count != 1 ? "s" : ""}');
    } catch (_) {
      _snack('That doesn\'t look like a valid backup');
    }
  }

  void _showAbout(BrikStaxColors bt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: bt.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: bt.cardBorder, width: BT.bw),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SheetHandle(),
            const SizedBox(height: 14),
            Row(children: [
              Text('BrikStax',
                  style: BT.display(size: 26, color: bt.tx)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: BT.yellow,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: BT.ink, width: BT.bw),
                ),
                child: FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (_, snap) => Text(
                      snap.hasData ? 'v${snap.data!.version}' : '',
                      style: BT.mono(size: 10, color: BT.ink)),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Text(
              'Track every brick. Manage your LEGO collection, follow market '
              'values, and grow your minifig avatar as you collect.',
              style: BT.mono(size: 11, color: bt.tx2),
            ),
            const SizedBox(height: 18),
            Text('DATA SOURCES', style: BT.mono(size: 9, color: bt.tx3)),
            const SizedBox(height: 6),
            Text(
              'Set data from BrickSet and Rebrickable. Market estimates from '
              'eBay sold listings. LEGO® is a trademark of the LEGO Group, '
              'which does not sponsor or endorse this app.',
              style: BT.mono(size: 10, color: bt.tx2),
            ),
            const SizedBox(height: 18),
            Text('LINKS', style: BT.mono(size: 9, color: bt.tx3)),
            const SizedBox(height: 8),
            _aboutLink(bt, 'Privacy policy',
                () => _openUrl(_kPrivacyPolicy, 'privacy policy')),
            _aboutLink(bt, 'Terms of service',
                () => _openUrl(_kTermsOfService, 'terms')),
            _aboutLink(bt, 'Send feedback',
                () => _openUrl(_kFeedbackForm, 'feedback form')),
          ]),
        ),
      ),
    );
  }

  Widget _aboutLink(BrikStaxColors bt, String label, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(children: [
            Text(label, style: BT.body(size: 13, color: bt.tx)),
            const Spacer(),
            Icon(Icons.open_in_new, size: 14, color: bt.txMuted),
          ]),
        ),
      );

  // ── UI builders ──────────────────────────────────────────────────────────

  SliverToBoxAdapter _header(BrikStaxColors bt, String title) =>
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
          child: Text(title.toUpperCase(),
              style: BT.mono(size: 9, color: bt.tx3)),
        ),
      );

  SliverToBoxAdapter _tile(
    BrikStaxColors bt, {
    required IconData icon,
    required Color bg,
    required Color iconColor,
    required String title,
    required String sub,
    VoidCallback? onTap,
    bool busy = false,
    double? progress,
  }) =>
      SliverToBoxAdapter(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            decoration: BoxDecoration(
              color: bt.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: onTap != null ? bt.cardBorder : bt.surface2,
                  width: BT.bw),
              boxShadow: onTap != null
                  ? [BoxShadow(color: bt.shadowColor,
                      offset: const Offset(2, 2))]
                  : [],
            ),
            child: Row(children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: BT.ink, width: BT.bw),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: BT.body(size: 14,
                    color: onTap != null ? bt.tx : bt.txMuted)),
                Text(sub, style: BT.mono(size: 9,
                    color: onTap != null ? bt.tx3 : bt.txMuted)),
              ])),
              if (busy)
                SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    value: progress,
                    valueColor: AlwaysStoppedAnimation(iconColor),
                  ),
                )
              else
                Icon(Icons.chevron_right,
                    color: onTap != null ? bt.txMuted : bt.surface2,
                    size: 18),
            ]),
          ),
        ),
      );
}

// ── Push notification opt-in (dev-gated for now) ───────────────────────────
// Real toggle UI: requests the OS permission, subscribes the device to the
// "all_users" broadcast topic, and registers the token with the Worker --
// same underlying pieces push_test_screen.dart exercises individually for
// debugging, wired together here as the actual one-tap flow a real user
// would see once this ships past dev-only.
class _NotificationsOptIn extends StatefulWidget {
  const _NotificationsOptIn();
  @override State<_NotificationsOptIn> createState() => _NotificationsOptInState();
}

class _NotificationsOptInState extends State<_NotificationsOptIn> {
  final _svc = PushService.instance;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _svc.addListener(_onChange);
    // Silently restores a previous opt-in (if any) without re-prompting --
    // see PushService.restoreIfOptedIn's own doc comment.
    _svc.restoreIfOptedIn(DeviceIdentity.instance.id);
  }

  @override
  void dispose() {
    _svc.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() { if (mounted) setState(() {}); }

  Future<void> _toggle(bool value) async {
    setState(() => _busy = true);
    await _svc.setOptedIn(value, userId: DeviceIdentity.instance.id);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final bt = context.bt;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: bt.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: bt.cardBorder, width: BT.bw),
        ),
        child: SwitchListTile(
          activeColor: BT.green,
          title: Text('Push Notifications',
              style: BT.body(size: 14, weight: FontWeight.w700, color: bt.tx)),
          subtitle: Text(
            _svc.optedIn
                ? 'On — you\'ll get restock, price, and other BrikStax alerts.'
                : 'Get notified about restocks, price drops, and other alerts.',
            style: BT.mono(size: 9, color: bt.tx3),
          ),
          value: _svc.optedIn,
          onChanged: _busy ? null : _toggle,
        ),
      ),
    );
  }
}

// ── Dev-mode-only eBay API usage counter ──────────────────────────────────────
// Shows current month's real RapidAPI call count against the 1350 cap.
// Only visible when dev mode is on (magic set 041793) — not shown to
// regular users, since it's an internal cost-monitoring detail.
class _EbayUsageTile extends StatefulWidget {
  const _EbayUsageTile();
  @override State<_EbayUsageTile> createState() => _EbayUsageTileState();
}

class _EbayUsageTileState extends State<_EbayUsageTile> {
  int? _calls;
  int? _cap;
  bool _loading = true;
  String? _error;

  static const _workerUrl =
      'https://brikstax-worker.paul-olsen1684.workers.dev';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await http.get(Uri.parse('$_workerUrl/ebay/usage'))
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() {
          _calls = data['calls'] as int?;
          _cap   = data['cap'] as int?;
        });
      } else {
        setState(() => _error = 'Error ${res.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Couldn\'t reach the Worker');
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final bt = context.bt;
    final pct = (_calls != null && _cap != null && _cap! > 0)
        ? _calls! / _cap!
        : null;
    final nearCap = pct != null && pct >= 0.9;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: bt.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: nearCap ? BT.red : bt.cardBorder, width: BT.bw),
        boxShadow: [BoxShadow(color: bt.shadowColor,
            offset: const Offset(2, 2))],
      ),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: nearCap ? BT.redBg : bt.surface2,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: BT.ink, width: BT.bw),
          ),
          child: Icon(Icons.api, size: 18,
              color: nearCap ? BT.red : bt.tx2),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('eBay API usage (this month)',
              style: BT.body(size: 14, color: bt.tx)),
          if (_loading)
            Text('Loading…', style: BT.mono(size: 9, color: bt.tx3))
          else if (_error != null)
            Text(_error!, style: BT.mono(size: 9, color: BT.red))
          else
            Text('$_calls / $_cap calls used',
                style: BT.mono(size: 9,
                    color: nearCap ? BT.red : bt.tx3)),
        ])),
        GestureDetector(
          onTap: _fetch,
          child: Icon(Icons.refresh, color: bt.txMuted, size: 18),
        ),
      ]),
    );
  }
}
