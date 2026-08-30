import '../account.dart';
import '../config.dart';
import '../token_manager.dart';

class SessionSettings {
  SessionSettings(this.api, this.tokens);
  final AuthApi api;
  final TokenManager tokens;
  Future<AuthResult<JsonMap>> getCurrent() => _mapped('/session', 'session');
  Future<AuthResult<List<dynamic>>> list() =>
      _mapped('/session/list', 'sessions');
  Future<AuthResult<JsonMap>> revoke(int id) =>
      _call('/session/revoke', {'id': id});
  Future<AuthResult<JsonMap>> revokeOther() =>
      _call('/session/revokeOther', {});
  Future<AuthResult<T>> _mapped<T>(String path, String key) async {
    try {
      final data =
          await api.send('GET', path, headers: authHeaders(await tokens.get()));
      return AuthResult.success(data[key] as T);
    } catch (e) {
      return AuthResult.failure('$e');
    }
  }

  Future<AuthResult<JsonMap>> _call(String path, Object body) async {
    try {
      return AuthResult.success(await api.send('POST', path,
          body: body, headers: authHeaders(await tokens.get())));
    } catch (e) {
      return AuthResult.failure('$e');
    }
  }
}
