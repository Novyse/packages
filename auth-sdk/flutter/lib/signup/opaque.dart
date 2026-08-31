import 'package:flutter/foundation.dart' show debugPrint;
import '../account.dart';
import '../config.dart';
import '../opaque/flutter.dart';

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
  OpaqueSignUp(this.api);
  final AuthApi api;
  final opaque = FlutterOpaqueClient();
  Future<AuthResult<JsonMap>> signUp(String username, String password,
      String name, JsonMap gdpr, String turnstileToken) async {
    try {
      debugPrint('[OpaqueSignUp] 1. Calling startRegistration...');
      final start = await opaque.startRegistration(password);
      debugPrint('[OpaqueSignUp] 1. startRegistration success.');

      debugPrint('[OpaqueSignUp] 2. Sending challenge request...');
      final challenge =
          await api.send('POST', '/signup/opaque/challenge', body: {
        'username': username,
        'registrationRequest': start.registrationRequest,
        'turnstileToken': turnstileToken
      });
      debugPrint('[OpaqueSignUp] 2. challenge response received: $challenge');

      debugPrint('[OpaqueSignUp] 3. Calling finishRegistration...');
      final record = await opaque.finishRegistration(
          password: password,
          clientRegistrationState: start.clientRegistrationState,
          registrationResponse: challenge['registrationResponse'] as String,
          serverIdentity: opaqueServerIdentity);
      debugPrint('[OpaqueSignUp] 3. finishRegistration success.');

      debugPrint('[OpaqueSignUp] 4. Sending complete request...');
      final completeRes = await api.send('POST', '/signup/opaque/complete', body: {
        'signupId': challenge['signupId'],
        'username': username,
        'name': name,
        'registrationRecord': record,
        'privacyPolicyAccepted': gdpr['privacy'] == true,
        'termsOfServiceAccepted': gdpr['tos'] == true,
        'isOver16': gdpr['isOver16'] == true
      });
      debugPrint('[OpaqueSignUp] 4. complete response received: $completeRes');

      return AuthResult.success(completeRes);
    } catch (e, st) {
      debugPrint('[OpaqueSignUp] ERROR during signUp: $e\n$st');
      return AuthResult.failure('$e');
    }
  }
}
