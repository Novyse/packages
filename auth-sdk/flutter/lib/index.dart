import 'package:http/http.dart' as http;
import 'account.dart';
import 'apikey.dart';
import 'config.dart';
import 'logout.dart';
import 'qrcode/index.dart';
import 'settings/opaque.dart';
import 'settings/session.dart';
import 'signin/opaque.dart';
import 'signup/opaque.dart';
import 'token_manager.dart';
export 'account.dart' show Account, AuthResult;
export 'apikey.dart';
export 'config.dart' show Branch, Platform, JsonMap;
export 'qrcode/index.dart';
export 'signup/opaque.dart'
    show OpaqueClient, OpaqueRegistrationStart, OpaqueLoginStart;
export 'opaque/flutter.dart' show FlutterOpaqueClient;
export 'token_manager.dart' show StorageAdapter;

class NovyseAuthOptions {
  const NovyseAuthOptions(
      {required this.platform,
      this.branch = Branch.production,
      this.baseUrl,
      this.storageAdapter,
      this.client});
  final Platform platform;
  final Branch branch;
  final Uri? baseUrl;
  final StorageAdapter? storageAdapter;
  final http.Client? client;
}

class NovyseAuth {
  NovyseAuth(NovyseAuthOptions options) {
    final api = AuthApi(
        options.baseUrl ?? Uri.https(authDomain(options.branch)),
        options.client ?? http.Client());
    final tokens = TokenManager(api, options.platform, options.storageAdapter);
    token = TokenApi(tokens);
    signin = OpaqueSignIn(api, tokens, options.platform);
    signup = OpaqueSignUp(api);
    settings = SettingsApi(
        OpaqueSettings(api, tokens), SessionSettings(api, tokens));
    account = Account(api, tokens);
    apikey = ApiKey(api, tokens);
    qrcode = QrCode(api, tokens, options.platform);
    logout = Logout(api, tokens).logout;
  }
  late final TokenApi token;
  late final OpaqueSignIn signin;
  late final OpaqueSignUp signup;
  late final SettingsApi settings;
  late final Account account;
  late final ApiKey apikey;
  late final QrCode qrcode;
  late final Future<bool> Function() logout;
}

class TokenApi {
  const TokenApi(this.manager);
  final TokenManager manager;
  Future<String?> get() => manager.get();
  void onUpdate(void Function(String?) callback) => manager.onUpdate(callback);
  void onInvalidSession(void Function() callback) =>
      manager.onInvalidSession = callback;
}

class SettingsApi {
  const SettingsApi(this.opaque, this.session);
  final OpaqueSettings opaque;
  final SessionSettings session;
}
