import 'config.dart';
import 'token_manager.dart';

class Logout {
  Logout(this.api, this.tokens);
  final AuthApi api;
  final TokenManager tokens;
  Future<bool> logout() async {
    try {
      await api.send('POST', '/logout',
          headers: authHeaders(await tokens.get()));
      tokens.setCurrentToken(null);
      return true;
    } catch (_) {
      return false;
    }
  }
}
