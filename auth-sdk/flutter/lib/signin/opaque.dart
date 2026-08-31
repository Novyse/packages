import '../account.dart';
import '../config.dart';
import '../opaque/flutter.dart';
import '../token_manager.dart';

class OpaqueSignIn {
  OpaqueSignIn(this.api, this.tokens, this.platform);
  final AuthApi api;
  final TokenManager tokens;
  final Platform platform;
  final opaque = FlutterOpaqueClient();
  Future<AuthResult<JsonMap>> signIn(
      String username, String password, String turnstileToken) async {
    try {
      final start = await opaque.startLogin(password);
      final challenge =
          await api.send('POST', '/signin/opaque/challenge', body: {
        'username': username,
        'ke1': start.startLoginRequest,
        'turnstileToken': turnstileToken
      });
      final ke3 = await opaque.finishLogin(
          password: password,
          clientLoginState: start.clientLoginState,
          loginResponse: challenge['ke2'] as String,
          serverIdentity: opaqueServerIdentity);
      final data = await api.send('POST', '/signin/opaque/complete',
          body: {'challengeId': challenge['challengeId'], 'ke3': ke3},
          headers: {'x-platform': platform.name});
      if (data['requires2FA'] != true)
        tokens.setCurrentToken(data['token'] as String?);
      return AuthResult.success(data);
    } catch (e) {
      return AuthResult.failure('$e');
    }
  }
}
