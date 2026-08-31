import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_opaque/flutter_opaque.dart' as opaque;

import '../signup/opaque.dart';

/// OPAQUE client backed by the Rust implementation used by flutter_opaque.
///
/// Messages are encoded as URL-safe Base64 without padding, as expected by
/// the Serenity Kit backend.
class FlutterOpaqueClient implements OpaqueClient {
  static bool _initialized = false;
  static Future<void>? _initFuture;

  /// Initializes the native OPAQUE library.
  /// Automatically invoked on-demand if not called manually.
  static Future<void> initialize() async {
    if (_initialized) return;
    _initFuture ??= _doInit();
    await _initFuture;
  }

  static Future<void> _doInit() async {
    try {
      await opaque.RustLib.init();
      _initialized = true;
    } catch (_) {
      _initialized = true;
    }
  }

  Future<void> _ensureInitialized() => initialize();

  @override
  Future<OpaqueRegistrationStart> startRegistration(String password) async {
    await _ensureInitialized();
    final result = await opaque.clientRegistrationStart(
      password: utf8.encode(password),
    );
    return OpaqueRegistrationStart(
      clientRegistrationState: _encode(utf8.encode(result.stateId.toString())),
      registrationRequest: _encode(result.registrationRequest),
    );
  }

  @override
  Future<String> finishRegistration({
    required String password,
    required String clientRegistrationState,
    required String registrationResponse,
    required String serverIdentity,
  }) async {
    await _ensureInitialized();
    final result = await opaque.clientRegistrationFinish(
      stateId: _decodeStateId(clientRegistrationState),
      password: utf8.encode(password),
      registrationResponse: _decode(registrationResponse),
    );
    return _encode(result.registrationUpload);
  }

  @override
  Future<OpaqueLoginStart> startLogin(String password) async {
    await _ensureInitialized();
    final result = await opaque.clientLoginStart(
      password: utf8.encode(password),
    );
    return OpaqueLoginStart(
      clientLoginState: _encode(utf8.encode(result.stateId.toString())),
      startLoginRequest: _encode(result.credentialRequest),
    );
  }

  @override
  Future<String> finishLogin({
    required String password,
    required String clientLoginState,
    required String loginResponse,
    required String serverIdentity,
  }) async {
    await _ensureInitialized();
    final result = await opaque.clientLoginFinish(
      stateId: _decodeStateId(clientLoginState),
      password: utf8.encode(password),
      credentialResponse: _decode(loginResponse),
    );
    return _encode(result.credentialFinalization);
  }

  String _encode(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');

  List<int> _decode(String value) {
    final padding = (4 - value.length % 4) % 4;
    return base64Url.decode(value + ('=' * padding));
  }

  dynamic _decodeStateId(String value) {
    final decoded = utf8.decode(_decode(value));
    if (kIsWeb) {
      return BigInt.parse(decoded);
    }
    return int.parse(decoded);
  }
}
