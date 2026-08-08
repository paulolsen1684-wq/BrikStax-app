// lib/screens/scanner.dart — BrikStax
// Real camera barcode scanning via mobile_scanner, gated behind dev mode.
// Default: "Coming Soon" screen (barcode DB still being seeded).
// Dev mode ON (magic set 041793): real camera scanner is unlocked.
//
// Two modes, toggled at the top of the live scanner:
//   Inventory — scan → add to collection (original flow)
//   Retail    — scan → quick price-check card (MSRP + 10/30/60% off math),
//               nothing is added to the collection
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/app_theme.dart';
import '../theme/app_themes.dart';
import '../modules/avatar/services/dev_mode.dart';
import '../services/feature_flag_service.dart';
import '../services/device_identity.dart';
import '../services/api.dart';
import 'add_set.dart';
import 'set_lookup_screen.dart';

const String _kWorkerUrl =
    'https://brikstax-worker.paul-olsen1684.workers.dev';

enum ScanMode { inventory, retail }

class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dev mode always bypasses the gate. Otherwise, the scanner only
    // unlocks when the Worker's /features flag says it's ready for real
    // users — flip FEATURE_SCANNER=true in Cloudflare dashboard vars,
    // no app update needed.
    final unlocked = DevMode.instance.isOn ||
        FeatureFlagService.instance.scannerEnabled;
    return unlocked
        ? const _LiveScannerScreen()
        : const _ComingSoonScreen();
  }
}

// ── Coming Soon (default) ─────────────────────────────────────────────────────
class _ComingSoonScreen extends StatelessWidget {
  const _ComingSoonScreen();

  @override
  Widget build(BuildContext context) {
    final bt = context.bt;

    return Scaffold(
      backgroundColor: bt.surface,
      body: SafeArea(
        child: Column(children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            decoration: BoxDecoration(
              color: bt.surface,
              border: Border(
                  bottom: BorderSide(color: bt.cardBorder, width: BT.bw)),
            ),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: bt.cardBg,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: bt.cardBorder, width: BT.bw),
                    boxShadow: [BoxShadow(color: bt.shadowColor,
                        offset: const Offset(2, 2))],
                  ),
                  child: Icon(Icons.arrow_back_ios_new,
                      color: bt.tx, size: 16),
                ),
              ),
              const SizedBox(width: 12),
              Text('Scan Set', style: BT.display(size: 26, color: bt.tx)),
            ]),
          ),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    color: BT.yellow,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: BT.ink, width: BT.bw),
                    boxShadow: BT.shadow,
                  ),
                  child: const Center(
                    child: Icon(Icons.qr_code_scanner,
                        size: 64, color: BT.ink),
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: BT.ink,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text('COMING SOON',
                      style: BT.display(size: 14, color: BT.yellow)),
                ),
                const SizedBox(height: 20),
                Text('Barcode Scanner',
                    style: BT.display(size: 30, color: bt.tx)),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Scan any LEGO set box to instantly identify and add it to your collection.',
                    style: BT.mono(size: 12, color: bt.tx2),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(children: [
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const SetLookupScreen())),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: BT.yellow,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: BT.yellow, width: BT.bw),
                          boxShadow: BT.shadow,
                        ),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                          const Icon(Icons.search, color: BT.ink, size: 20),
                          const SizedBox(width: 8),
                          Text('Research a set',
                              style: BT.body(size: 15, color: BT.ink)),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(
                            builder: (_) => const AddSetScreen()));
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: BT.ink,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: BT.ink, width: BT.bw),
                          boxShadow: BT.shadow,
                        ),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                          const Icon(Icons.add, color: BT.yellow, size: 20),
                          const SizedBox(width: 8),
                          Text('Add set manually',
                              style: BT.body(size: 15, color: BT.yellow)),
                        ]),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Live scanner (dev mode only) ──────────────────────────────────────────────
class _LiveScannerScreen extends StatefulWidget {
  const _LiveScannerScreen();
  @override State<_LiveScannerScreen> createState() => _LiveScannerScreenState();
}

class _LiveScannerScreenState extends State<_LiveScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
    ],
  );

  ScanMode _mode = ScanMode.inventory;
  bool _looking = false;
  bool _torchOn = false;
  String? _lastCode;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_looking) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code == _lastCode) return;
    _lastCode = code;

    setState(() => _looking = true);
    await _controller.stop();

    try {
      final uri = Uri.parse('$_kWorkerUrl/barcode?ean=${Uri.encodeComponent(code)}');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final setNum = data['set_num'] as String?;
        final setName = data['set_name'] as String?;

        if (setNum != null && mounted) {
          if (_mode == ScanMode.inventory) {
            Navigator.pushReplacement(context, MaterialPageRoute(
                builder: (_) => AddSetScreen(initialNum: setNum, fromScan: true)));
          } else {
            await _showRetailCheck(setNum, setName);
          }
          return;
        }
      }

      if (mounted) _showNotFound(code);
    } catch (e) {
      if (mounted) _showError();
    } finally {
      if (mounted) setState(() => _looking = false);
      _lastCode = null;
      await _controller.start();
    }
  }

  Future<void> _showRetailCheck(String setNum, String? setName) async {
    // Fetch retail price via the existing Api helper (same source used
    // elsewhere in the app — BrickSet via the Worker).
    double? retail;
    try {
      retail = await Api.instance.fetchRetail(setNum);
    } catch (_) {}

    // Also check eBay's cache for a current market price. This calls the
    // SAME /ebay endpoint the collection refresh uses, meaning it hits the
    // 7-day cache first — if a set has already been priced recently (via
    // your collection or a prior scan), this reuses that data at zero
    // extra API cost. Only a genuine cache miss triggers a real RapidAPI
    // call, and the Worker's monthly cap (1350) protects against runaway
    // costs even then. Retail-mode scans are read-only — nothing here
    // writes to your collection.
    double? ebayPrice;
    bool ebayBlocked = false;
    try {
      final uri = Uri.parse('$_kWorkerUrl/ebay');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'num': setNum, 'condition': 'sealed', 'name': setName}),
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        ebayPrice = (data['avg'] as num?)?.toDouble();
      } else if (res.statusCode == 429) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['error'] == 'ebay_monthly_cap_reached') ebayBlocked = true;
      }
    } catch (_) {}

    if (!mounted) return;

    final bt = context.bt;
    await showModalBottomSheet(
      context: context,
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
            Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(setName ?? 'Set #$setNum',
                      style: BT.display(size: 20, color: bt.tx),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  Text('#$setNum', style: BT.mono(size: 11, color: bt.tx3)),
                ],
              )),
            ]),
            const SizedBox(height: 16),

            if (retail == null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bt.surface2,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  Icon(Icons.info_outline, size: 18, color: bt.txMuted),
                  const SizedBox(width: 10),
                  Expanded(child: Text(
                      'No retail price on file for this set yet.',
                      style: BT.mono(size: 12, color: bt.tx2))),
                ]),
              )
            else ...[
              _priceRow(bt, 'MSRP', retail, isMsrp: true),
              const SizedBox(height: 8),
              _priceRow(bt, '10% off', retail * 0.90),
              const SizedBox(height: 8),
              _priceRow(bt, '30% off', retail * 0.70),
              const SizedBox(height: 8),
              _priceRow(bt, '60% off', retail * 0.40),
            ],

            if (ebayPrice != null) ...[
              const SizedBox(height: 8),
              _priceRow(bt, 'eBay avg (sealed)', ebayPrice, isEbay: true),
            ] else if (ebayBlocked) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bt.surface2,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'eBay price check unavailable right now (monthly limit reached).',
                  style: BT.mono(size: 9, color: bt.txMuted),
                ),
              ),
            ],


            const SizedBox(height: 18),
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: BT.yellow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: BT.ink, width: BT.bw),
                  boxShadow: BT.shadow,
                ),
                child: Text('Scan another',
                    textAlign: TextAlign.center,
                    style: BT.body(size: 15, color: BT.ink)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _priceRow(BrikStaxColors bt, String label, double price,
      {bool isMsrp = false, bool isEbay = false}) {
    final color = isEbay ? BT.blue : (isMsrp ? bt.tx2 : BT.green);
    final bg    = isEbay ? const Color(0xFFE3F2FD)
        : (isMsrp ? bt.surface2 : BT.greenBg);
    final border = isEbay ? BT.blue : (isMsrp ? bt.cardBorder : BT.green);
    final valueColor = isEbay ? BT.blue : (isMsrp ? bt.tx : BT.green);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border, width: BT.bw),
      ),
      child: Row(children: [
        Text(label, style: BT.mono(size: 11, color: color)),
        const Spacer(),
        Text('\$${price.toStringAsFixed(2)}',
            style: BT.display(size: 20, color: valueColor)),
      ]),
    );
  }

  void _showNotFound(String code) {
    final bt = context.bt;
    final setNumCtrl = TextEditingController();
    bool submitting = false;
    bool submitted = false;
    String? resultMsg;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: bt.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: bt.cardBorder, width: BT.bw),
      ),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 20, right: 20, top: 20,
          ),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Set not found', style: BT.display(size: 22, color: bt.tx)),
            const SizedBox(height: 8),
            Text(
              'Barcode $code isn\'t in our database yet.'
              '${_mode == ScanMode.inventory ? " You can add the set manually using its set number instead." : ""}',
              style: BT.mono(size: 12, color: bt.tx2),
            ),
            const SizedBox(height: 18),

            // ── "I know this set" — contribute barcode→set pairing ─────────
            if (!submitted) ...[
              Text('KNOW WHAT SET THIS IS?',
                  style: BT.mono(size: 9, color: bt.tx3)),
              const SizedBox(height: 6),
              Text(
                'Enter the set number and help us add it for everyone. '
                'Once 2 people confirm the same set, it\'s added automatically.',
                style: BT.mono(size: 10, color: bt.tx3),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: bt.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: bt.cardBorder, width: BT.bw),
                    ),
                    child: TextField(
                      controller: setNumCtrl,
                      keyboardType: TextInputType.number,
                      style: BT.mono(size: 14, color: bt.tx),
                      decoration: InputDecoration(
                        hintText: 'e.g. 75192',
                        hintStyle: BT.mono(size: 14, color: bt.txMuted),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: submitting ? null : () async {
                    final num = setNumCtrl.text.trim();
                    if (num.isEmpty) return;
                    setSheet(() => submitting = true);

                    final msg = await _submitBarcodeGuess(code, num);

                    setSheet(() {
                      submitting = false;
                      submitted = true;
                      resultMsg = msg;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: BT.green,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: BT.ink, width: BT.bw),
                    ),
                    child: submitting
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white)))
                        : const Icon(Icons.check, color: Colors.white, size: 18),
                  ),
                ),
              ]),
              const SizedBox(height: 18),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: BT.greenBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: BT.green, width: BT.bw),
                ),
                child: Row(children: [
                  const Icon(Icons.check_circle, color: BT.green, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(
                      resultMsg ?? 'Thanks for the submission!',
                      style: BT.mono(size: 11, color: BT.green))),
                ]),
              ),
              const SizedBox(height: 18),
            ],

            if (_mode == ScanMode.inventory)
              GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushReplacement(context, MaterialPageRoute(
                      builder: (_) => const AddSetScreen()));
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: BT.yellow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: BT.ink, width: BT.bw),
                    boxShadow: BT.shadow,
                  ),
                  child: Text('Add set manually',
                      textAlign: TextAlign.center,
                      style: BT.body(size: 15, color: BT.ink)),
                ),
              ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: bt.surface2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: bt.cardBorder, width: BT.bw),
                ),
                child: Text('Try scanning again',
                    textAlign: TextAlign.center,
                    style: BT.body(size: 15, color: bt.tx)),
              ),
            ),
          ]),
        ),
      )),
    );
  }

  void _showError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Lookup failed — check your connection and try again'),
    ));
  }

  Future<String> _submitBarcodeGuess(String barcode, String setNum) async {
    try {
      final uri = Uri.parse('$_kWorkerUrl/barcode/submit');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'barcode': barcode,
          'set_num': setNum,
          'user_id': DeviceIdentity.instance.id,
        }),
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode != 200) {
        return 'Submitted, but something went wrong on our end. Thanks anyway!';
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final promoted = data['promoted'] == true;
      final agreeCount = data['agree_count'] as int? ?? 1;
      final threshold = data['threshold'] as int? ?? 2;

      if (promoted) {
        return 'Added to the database — thanks for confirming!';
      }
      final remaining = threshold - agreeCount;
      return remaining > 0
          ? 'Got it! Need $remaining more ${remaining == 1 ? "person" : "people"} to confirm before it\'s added.'
          : 'Thanks! This will be added shortly.';
    } catch (_) {
      return 'Couldn\'t submit right now — check your connection.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
        ),

        Center(
          child: Container(
            width: 260, height: 260,
            decoration: BoxDecoration(
              border: Border.all(
                color: _looking ? BT.green : BT.yellow,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),

        // ── Top bar with mode toggle ────────────────────────────────────────
        SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white24, width: BT.bw),
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: BT.green.withOpacity(.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: BT.green, width: 1.5),
                  ),
                  child: Text('DEV', style: BT.mono(size: 8, color: BT.green)),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    await _controller.toggleTorch();
                    setState(() => _torchOn = !_torchOn);
                  },
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: _torchOn
                          ? BT.yellow
                          : Colors.black.withOpacity(.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white24, width: BT.bw),
                    ),
                    child: Icon(
                      _torchOn ? Icons.flash_on : Icons.flash_off,
                      color: _torchOn ? BT.ink : Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 12),

            // ── Mode toggle ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(.55),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24, width: 1.5),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                _modeTab('Inventory', ScanMode.inventory),
                _modeTab('Retail', ScanMode.retail),
              ]),
            ),
          ]),
        ),

        Positioned(
          left: 0, right: 0, bottom: 0,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(.6),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: _looking
                      ? Row(mainAxisSize: MainAxisSize.min, children: [
                          const SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(BT.yellow)),
                          ),
                          const SizedBox(width: 8),
                          Text(
                              _mode == ScanMode.inventory
                                  ? 'Looking up set…'
                                  : 'Checking price…',
                              style: BT.mono(size: 11, color: Colors.white)),
                        ])
                      : Text(
                          _mode == ScanMode.inventory
                              ? 'Point at the barcode to add this set'
                              : 'Point at the barcode to check the price',
                          style: BT.mono(size: 11, color: Colors.white)),
                ),
                const SizedBox(height: 14),
                if (_mode == ScanMode.inventory)
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const SetLookupScreen())),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: BT.yellow.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: BT.ink, width: BT.bw),
                          boxShadow: BT.shadow,
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.search, color: BT.ink, size: 16),
                          const SizedBox(width: 6),
                          Text('Research',
                              style: BT.body(size: 12, color: BT.ink)),
                        ]),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (_) => const AddSetScreen())),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: BT.yellow.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: BT.ink, width: BT.bw),
                          boxShadow: BT.shadow,
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.keyboard, color: BT.ink, size: 16),
                          const SizedBox(width: 6),
                          Text('Enter number',
                              style: BT.body(size: 12, color: BT.ink)),
                        ]),
                      ),
                    ),
                  ]),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _modeTab(String label, ScanMode mode) {
    final selected = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() => _mode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? BT.yellow : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(label,
            style: BT.body(size: 13,
                color: selected ? BT.ink : Colors.white70)),
      ),
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
