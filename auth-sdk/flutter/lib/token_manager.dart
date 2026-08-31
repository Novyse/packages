import 'dart:convert' show base64Url, jsonDecode, utf8;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'config.dart';

abstract interface class StorageAdapter {
  Future<String?> getItem(String key);
  Future<void> setItem(String key, String value);
  Future<void> removeItem(String key);
}

class DefaultSecureStorageAdapter implements StorageAdapter {
  const DefaultSecureStorageAdapter([this._storage = const FlutterSecureStorage()]);
  final FlutterSecureStorage _storage;

  @override
  Future<String?> getItem(String key) => _storage.read(key: key);

  @override
  Future<void> setItem(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> removeItem(String key) => _storage.delete(key: key);
}

DateTime? _extractJwtExpiry(String? token) {
  if (token == null || token.isEmpty) return null;
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    final normalized = base64Url.normalize(parts[1]);
    final payloadString = utf8.decode(base64Url.decode(normalized));
    final payload = jsonDecode(payloadString);
    if (payload is Map && payload['exp'] is num) {
      final expSeconds = (payload['exp'] as num).toInt();
      return DateTime.fromMillisecondsSinceEpoch(expSeconds * 1000, isUtc: true);
    }
  } catch (_) {}
  return null;
}

class TokenManager {
  TokenManager(this.api, this.platform)
      : storage = kIsWeb ? null : const DefaultSecureStorageAdapter();

  final AuthApi api;
  final Platform platform;
  final StorageAdapter? storage;
  String? _token;
  DateTime? _expiry;
  Future<String?>? _pending;
  final _listeners = <void Function(String?)>[];
  void Function()? onInvalidSession;

  String? get currentToken => _token;

  void onUpdate(void Function(String?) callback) => _listeners.add(callback);

  void _notify() {
    for (final listener in List.of(_listeners)) {
      listener(_token);
    }
  }

  void setCurrentToken(String? token) {
    _token = token;
    _expiry = _extractJwtExpiry(token) ??
        (token == null
            ? null
            : DateTime.now().toUtc().add(const Duration(minutes: 15)));
    _notify();
  }

  Future<String?> get({bool forceRefresh = false}) {
    final now = DateTime.now().toUtc();
    final isTokenValid = _token != null &&
        _expiry != null &&
        now.isBefore(_expiry!.subtract(const Duration(seconds: 30)));

    if (!forceRefresh && isTokenValid) {
      return Future.value(_token);
    }
    return _pending ??= _fetch().whenComplete(() => _pending = null);
  }

  Future<String?> _fetch() async {
    try {
      final headers = <String, String>{'x-platform': platform.name};
      if (platform != Platform.web && storage != null) {
        final id = await storage!.getItem('sessionId');
        if (id != null) {
          headers['x-session-id'] = id;
        }
      }
      final data = await api.send('POST', '/token', headers: headers);
      if (platform != Platform.web &&
          storage != null &&
          data['session_id'] != null) {
        await storage!.setItem('sessionId', '${data['session_id']}');
      }
      setCurrentToken(data['token'] as String?);
      return _token;
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        setCurrentToken(null);
        onInvalidSession?.call();
      }
      return _token;
    }
  }
}
