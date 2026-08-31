import 'package:flutter/foundation.dart' show debugPrint;
import '../account.dart';
import '../config.dart';
import '../opaque/flutter.dart';
import '../signup/opaque.dart';
import '../token_manager.dart';

class OpaqueSignIn {
  OpaqueSignIn(this.api, this.tokens, this.platform, this.opaque);
  final AuthApi api;
  final TokenManager tokens;
  final Platform platform;
  final OpaqueClient? opaque;
  Future<AuthResult<JsonMap>> signIn(
      String username, String password, String turnstileToken) async {
    try {
      final client = opaque ?? FlutterOpaqueClient();
      debugPrint('[OpaqueSignIn] 1. Calling startLogin...');
      final start = await client.startLogin(password);
      debugPrint('[OpaqueSignIn] 1. startLogin success.');

      debugPrint('[OpaqueSignIn] 2. Sending challenge request...');
      final challenge =
          await api.send('POST', '/signin/opaque/challenge', body: {
        'username': username,
        'ke1': start.startLoginRequest,
        'turnstileToken': turnstileToken
      });
      debugPrint('[OpaqueSignIn] 2. challenge response received: $challenge');

      debugPrint('[OpaqueSignIn] 3. Calling finishLogin...');
      final ke3 = await client.finishLogin(
          password: password,
          clientLoginState: start.clientLoginState,
          loginResponse: challenge['ke2'] as String,
          serverIdentity: opaqueServerIdentity);
      debugPrint('[OpaqueSignIn] 3. finishLogin success.');

      debugPrint('[OpaqueSignIn] 4. Sending complete request...');
      final data = await api.send('POST', '/signin/opaque/complete',
          body: {'challengeId': challenge['challengeId'], 'ke3': ke3},
          headers: {'x-platform': platform.name});
      debugPrint('[OpaqueSignIn] 4. complete response received: $data');

      if (data['requires2FA'] != true)
        tokens.setCurrentToken(data['token'] as String?);
      return AuthResult.success(data);
    } catch (e, st) {
      debugPrint('[OpaqueSignIn] ERROR during signIn: $e\n$st');
      return AuthResult.failure('$e');
    }
  }
}
