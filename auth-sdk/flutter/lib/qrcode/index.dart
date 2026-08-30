import '../account.dart';
import '../config.dart';
import '../token_manager.dart';

class QrCode {
  QrCode(this.api, this.tokens, this.platform);
  final AuthApi api;
  final TokenManager tokens;
  final Platform platform;
  Future<AuthResult<JsonMap>> newSession() =>
      _run('POST', '/signin/qrcode/new');
  Future<AuthResult<JsonMap>> status(String token) =>
      _run('GET', '/signin/qrcode/status/$token',
          headers: {'x-platform': platform.name});
  Future<AuthResult<JsonMap>> authenticate(String token) async =>
      _run('POST', '/signin/qrcode/authenticate/$token',
          headers: authHeaders(await tokens.get()));
  Future<AuthResult<JsonMap>> _run(String method, String path,
      {Map<String, String> headers = const {}}) async {
    try {
      return AuthResult.success(await api.send(method, path, headers: headers));
    } catch (e) {
      return AuthResult.failure('$e');
    }
  }
}
