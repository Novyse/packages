import '../account.dart';
import '../config.dart';
import '../opaque/flutter.dart';
import '../token_manager.dart';

class OpaqueSettings {
  OpaqueSettings(this.api, this.tokens);
  final AuthApi api;
  final TokenManager tokens;
  final opaque = FlutterOpaqueClient();
  Future<AuthResult<JsonMap>> setup(String password) async {
    try {
      final start = await opaque.startRegistration(password);
      final jwt = await tokens.get();
      final challenge = await api.send(
          'POST', '/settings/opaque/setup/challenge',
          body: {'registrationRequest': start.registrationRequest},
          headers: authHeaders(jwt));
      final record = await opaque.finishRegistration(
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
