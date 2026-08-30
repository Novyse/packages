import 'account.dart';
import 'config.dart';
import 'token_manager.dart';

class ApiKey {
  ApiKey(this.api, this.tokens);
  final AuthApi api;
  final TokenManager tokens;
  Future<AuthResult<JsonMap>> list() => _call('GET', '/apikey');
  Future<AuthResult<JsonMap>> create(String name,
          [Object permissions = const {}, Object expiresIn = -1]) =>
      _call('POST', '/apikey',
          {'name': name, 'permissions': permissions, 'expiresIn': expiresIn});
  Future<AuthResult<JsonMap>> toggleActive(int id, bool active) =>
      _call('PATCH', '/apikey/$id', {'active': active});
  Future<AuthResult<JsonMap>> revoke(int id) => _call('DELETE', '/apikey/$id');
  Future<AuthResult<JsonMap>> _call(String method, String path,
      [Object? body]) async {
    try {
      return AuthResult.success(await api.send(method, path,
          body: body, headers: authHeaders(await tokens.get())));
    } catch (e) {
      return AuthResult.failure('$e');
    }
  }
}
