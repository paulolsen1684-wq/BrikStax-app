// lib/screens/push_test_screen.dart
//
// Dev-only (Settings > Developer, same DevMode gate as the other dev
// screens). Proves the Firebase Cloud Messaging client pipeline works
// end-to-end on a real device: init Firebase, request the notification
// permission, get a token, and register it with the Worker. Actually
// SENDING a push isn't wired up yet (needs a Firebase service account key
// on the Worker side, not yet provided) -- until then, the intended test
// path is: get the token here, paste it into Firebase Console's own
// "Cloud Messaging > Send test message" tool, and confirm it arrives.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/push_service.dart';
import '../services/device_identity.dart';
import '../theme/app_theme.dart';
import '../theme/app_themes.dart';

class PushTestScreen extends StatefulWidget {
  const PushTestScreen({super.key});
  @override State<PushTestScreen> createState() => _State();
}

class _State extends State<PushTestScreen> {
  final _svc = PushService.instance;
  bool _registering = false;
  bool? _registerOk;

  @override
  void initState() {
    super.initState();
    _svc.addListener(_onChange);
    _svc.ensureInitialized();
  }

  @override
  void dispose() {
    _svc.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() { if (mounted) setState(() {}); }

  Future<void> _register() async {
    setState(() { _registering = true; _registerOk = null; });
    final ok = await _svc.registerToken(DeviceIdentity.instance.id);
    if (!mounted) return;
    setState(() { _registering = false; _registerOk = ok; });
  }

  String _statusLabel(AuthorizationStatus? s) => switch (s) {
    AuthorizationStatus.authorized => 'Authorized',
    AuthorizationStatus.denied => 'Denied',
    AuthorizationStatus.notDetermined => 'Not asked yet',
    AuthorizationStatus.provisional => 'Provisional',
    null => '—',
  };

  @override
  Widget build(BuildContext context) {
    final bt = context.bt;
    return Scaffold(
      backgroundColor: bt.surface,
      appBar: AppBar(
        title: Text('Push Notifications (Dev)', style: BT.display(size: 20, color: bt.tx)),
        backgroundColor: bt.surface,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _statusCard(bt),
            const SizedBox(height: 14),
            _actionButton(bt, 'Request permission & get token',
                onTap: _svc.requestPermissionAndToken),
            const SizedBox(height: 10),
            _actionButton(bt,
                _registering ? 'Registering…' : 'Register token with server',
                onTap: _svc.token == null || _registering ? null : _register),
            if (_registerOk != null) Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _registerOk! ? '✓ Registered' : '✗ Registration failed',
                style: BT.body(size: 12, color: _registerOk! ? BT.green : BT.red),
              ),
            ),
            const SizedBox(height: 20),
            Text('Foreground messages received', style: BT.display(size: 15, color: bt.tx)),
            const SizedBox(height: 4),
            Text(
              'Only fires while this screen is open with the app in the foreground -- '
              'background/terminated pushes show as normal system notifications instead, '
              'nothing to see here for those.',
              style: BT.mono(size: 10, color: bt.tx3),
            ),
            const SizedBox(height: 8),
            if (_svc.foregroundLog.isEmpty)
              Text('(none yet)', style: BT.mono(size: 12, color: bt.txMuted))
            else
              ..._svc.foregroundLog.map((line) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(line, style: BT.mono(size: 11, color: bt.tx2)),
              )),
          ],
        ),
      ),
    );
  }

  Widget _statusCard(BrikStaxColors bt) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: bt.cardBg,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: bt.cardBorder, width: BT.bw),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _row(bt, 'Firebase', _svc.firebaseReady ? 'Initialized' : 'Not initialized',
          color: _svc.firebaseReady ? BT.green : bt.txMuted),
      const SizedBox(height: 8),
      _row(bt, 'Permission', _statusLabel(_svc.permissionStatus)),
      const SizedBox(height: 8),
      Text('FCM Token', style: BT.mono(size: 10, color: bt.tx3)),
      const SizedBox(height: 4),
      if (_svc.token != null)
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: _svc.token!));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Token copied')));
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bt.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: bt.cardBorder, width: BT.bw),
            ),
            child: Row(children: [
              Expanded(child: Text(_svc.token!,
                  style: BT.mono(size: 10, color: bt.tx),
                  maxLines: 3, overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 6),
              Icon(Icons.copy, size: 14, color: bt.txMuted),
            ]),
          ),
        )
      else
        Text('—', style: BT.mono(size: 12, color: bt.txMuted)),
      if (_svc.lastError != null) ...[
        const SizedBox(height: 10),
        Text('Error: ${_svc.lastError}', style: BT.body(size: 11, color: BT.red)),
      ],
    ]),
  );

  Widget _row(BrikStaxColors bt, String label, String value, {Color? color}) => Row(
    children: [
      Text(label, style: BT.mono(size: 11, color: bt.tx3)),
      const Spacer(),
      Text(value, style: BT.body(size: 12, color: color ?? bt.tx, weight: FontWeight.w600)),
    ],
  );

  Widget _actionButton(BrikStaxColors bt, String label, {VoidCallback? onTap}) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: onTap == null ? bt.surface2 : BT.yellow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bt.cardBorder, width: BT.bw),
      ),
      child: Center(child: Text(label,
          style: BT.body(size: 13, weight: FontWeight.w700,
              color: onTap == null ? bt.txMuted : BT.ink))),
    ),
  );
}
