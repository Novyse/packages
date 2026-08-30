import '../config.dart';
import '../token_manager.dart';
import '../account.dart';
import '../signup/opaque.dart';

class OpaqueSettings {
  OpaqueSettings(this.api, this.tokens, this.opaque);
  final AuthApi api;
  final TokenManager tokens;
  final OpaqueClient? opaque;
  Future<AuthResult<JsonMap>> setup(String password) async {
    try {
      final client = opaque!;
      final start = await client.startRegistration(password);
      final jwt = await tokens.get();
      final challenge = await api.send(
          'POST', '/settings/opaque/setup/challenge',
          body: {'registrationRequest': start.registrationRequest},
          headers: authHeaders(jwt));
      final record = await client.finishRegistration(
          password: password,
          clientRegistrationState: start.clientRegistrationState,
          registrationResponse: challenge['registrationResponse'] as String,
          serverIdentity: opaqueServerIdentity);
      return AuthResult.success(await api.send(
          'POST', '/settings/opaque/setup/complete',
          body: {'registrationRecord': record}, headers: authHeaders(jwt)));
    } catch (e) {
      return AuthResult.failure('$e');
    }
  }
}
