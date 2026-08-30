import 'config.dart';
import 'token_manager.dart';

class AuthResult<T> {
  const AuthResult.success(this.data)
      : success = true,
        error = null;
  const AuthResult.failure(this.error)
      : success = false,
        data = null;
  final bool success;
  final T? data;
  final String? error;
}

class Account {
  Account(this.api, this.tokens);
  final AuthApi api;
  final TokenManager tokens;
  Future<AuthResult<JsonMap>> delete() async {
    try {
      return AuthResult.success(await api.send('DELETE', '/account',
          headers: authHeaders(await tokens.get())));
    } catch (e) {
      return AuthResult.failure('$e');
    }
  }
}
