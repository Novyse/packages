import 'dart:convert';

import 'package:flutter_opaque/flutter_opaque.dart' as opaque;

import '../signup/opaque.dart';

/// OPAQUE client backed by the Rust implementation used by flutter_opaque.
///
/// Messages are encoded as URL-safe Base64 without padding, as expected by
/// the Serenity Kit backend.
class FlutterOpaqueClient implements OpaqueClient {
  /// Initializes the native OPAQUE library. Call this once before using it.
  static Future<void> initialize() => opaque.RustLib.init();

  @override
  Future<OpaqueRegistrationStart> startRegistration(String password) async {
    final result = await opaque.clientRegistrationStart(
      password: utf8.encode(password),
    );
    return OpaqueRegistrationStart(
      clientRegistrationState: _encodeInt(result.stateId.toInt()),
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
    final result = await opaque.clientRegistrationFinish(
      stateId: _decodeInt(clientRegistrationState),
      password: utf8.encode(password),
      registrationResponse: _decode(registrationResponse),
    );
    return _encode(result.registrationUpload);
  }

  @override
  Future<OpaqueLoginStart> startLogin(String password) async {
    final result = await opaque.clientLoginStart(
      password: utf8.encode(password),
    );
    return OpaqueLoginStart(
      clientLoginState: _encodeInt(result.stateId.toInt()),
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
    final result = await opaque.clientLoginFinish(
      stateId: _decodeInt(clientLoginState),
      password: utf8.encode(password),
      credentialResponse: _decode(loginResponse),
    );
    return _encode(result.credentialFinalization);
  }

  String _encode(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');

  String _encodeInt(int value) => _encode(utf8.encode(value.toString()));

  List<int> _decode(String value) {
    final padding = (4 - value.length % 4) % 4;
    return base64Url.decode(value + ('=' * padding));
  }

  int _decodeInt(String value) => int.parse(utf8.decode(_decode(value)));
}
