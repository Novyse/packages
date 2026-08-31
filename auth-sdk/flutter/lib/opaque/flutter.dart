import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
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
      debugPrint('[FlutterOpaqueClient] Calling opaque.RustLib.init()...');
      await opaque.RustLib.init();
      debugPrint('[FlutterOpaqueClient] opaque.RustLib.init() succeeded.');
      _initialized = true;
    } catch (e, st) {
      debugPrint('[FlutterOpaqueClient] opaque.RustLib.init() FAILED: $e\n$st');
      rethrow;
    }
  }

  Future<void> _ensureInitialized() => initialize();

  @override
  Future<OpaqueRegistrationStart> startRegistration(String password) async {
    debugPrint('[FlutterOpaqueClient] startRegistration called');
    await _ensureInitialized();
    final result = await opaque.clientRegistrationStart(
      password: utf8.encode(password),
    );
    debugPrint('[FlutterOpaqueClient] startRegistration completed successfully');
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
    debugPrint('[FlutterOpaqueClient] finishRegistration called');
    await _ensureInitialized();
    final result = await opaque.clientRegistrationFinish(
      stateId: _decodeStateId(clientRegistrationState),
      password: utf8.encode(password),
      registrationResponse: _decode(registrationResponse),
    );
    debugPrint('[FlutterOpaqueClient] finishRegistration completed successfully');
    return _encode(result.registrationUpload);
  }

  @override
  Future<OpaqueLoginStart> startLogin(String password) async {
    debugPrint('[FlutterOpaqueClient] startLogin called');
    await _ensureInitialized();
    final result = await opaque.clientLoginStart(
      password: utf8.encode(password),
    );
    debugPrint('[FlutterOpaqueClient] startLogin completed successfully');
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
    debugPrint('[FlutterOpaqueClient] finishLogin called');
    await _ensureInitialized();
    final result = await opaque.clientLoginFinish(
      stateId: _decodeStateId(clientLoginState),
      password: utf8.encode(password),
      credentialResponse: _decode(loginResponse),
    );
    debugPrint('[FlutterOpaqueClient] finishLogin completed successfully');
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
