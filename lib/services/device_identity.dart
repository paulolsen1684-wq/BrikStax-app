// lib/services/device_identity.dart
// Anonymous per-install id used purely for backend attribution — barcode
// crowdsourcing consensus (Worker counts DISTINCT user_id per barcode) and
// community post rate-limiting (Worker keys the cooldown by user_id). Not a
// real account: generated once on first launch, persisted locally, never
// sent anywhere except our own Worker.
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceIdentity {
  DeviceIdentity._();
  static final instance = DeviceIdentity._();

  static const _kKey = 'device_identity_id';
  static const _uuid = Uuid();

  String? _id;

  /// The persisted per-install id. init() must run first (see main.dart).
  String get id => _id ?? (throw StateError('DeviceIdentity.init() not called yet'));

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_kKey);
    if (id == null) {
      id = _uuid.v4();
      await prefs.setString(_kKey, id);
    }
    _id = id;
  }
}
