import 'config.dart';
import 'token_manager.dart';

class Logout {
  Logout(this.api, this.tokens);
  final AuthApi api;
  final TokenManager tokens;
  Future<bool> logout() async {
    try {
      final token = tokens.currentToken;
      if (token != null && token.isNotEmpty) {
        await api.send('POST', '/logout', headers: authHeaders(token));
      }
      if (tokens.storage != null) {
        await tokens.storage!.removeItem('sessionId');
      }
      tokens.setCurrentToken(null);
      return true;
    } catch (_) {
      tokens.setCurrentToken(null);
      return false;
    }
  }
}
