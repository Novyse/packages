import '../account.dart';
import '../config.dart';

abstract interface class OpaqueClient {
  Future<OpaqueRegistrationStart> startRegistration(String password);
  Future<String> finishRegistration(
      {required String password,
      required String clientRegistrationState,
      required String registrationResponse,
      required String serverIdentity});
  Future<OpaqueLoginStart> startLogin(String password);
  Future<String> finishLogin(
      {required String password,
      required String clientLoginState,
      required String loginResponse,
      required String serverIdentity});
}

class OpaqueRegistrationStart {
  const OpaqueRegistrationStart(
      {required this.clientRegistrationState,
      required this.registrationRequest});
  final String clientRegistrationState;
  final String registrationRequest;
}

class OpaqueLoginStart {
  const OpaqueLoginStart(
      {required this.clientLoginState, required this.startLoginRequest});
  final String clientLoginState;
  final String startLoginRequest;
}

class OpaqueSignUp {
  OpaqueSignUp(this.api, this.opaque);
  final AuthApi api;
  final OpaqueClient? opaque;
  Future<AuthResult<JsonMap>> signUp(String username, String password,
      String name, JsonMap gdpr, String turnstileToken) async {
    try {
      final client = opaque!;
      final start = await client.startRegistration(password);
      final challenge =
          await api.send('POST', '/signup/opaque/challenge', body: {
        'username': username,
        'registrationRequest': start.registrationRequest,
        'turnstileToken': turnstileToken
      });
      final record = await client.finishRegistration(
          password: password,
          clientRegistrationState: start.clientRegistrationState,
          registrationResponse: challenge['registrationResponse'] as String,
          serverIdentity: opaqueServerIdentity);
      return AuthResult.success(
          await api.send('POST', '/signup/opaque/complete', body: {
        'signupId': challenge['signupId'],
        'username': username,
        'name': name,
        'registrationRecord': record,
        'privacyPolicyAccepted': gdpr['privacy'] == true,
        'termsOfServiceAccepted': gdpr['tos'] == true,
        'isOver16': gdpr['isOver16'] == true
      }));
    } catch (e) {
      return AuthResult.failure('$e');
    }
  }
}
