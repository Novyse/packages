import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;
import 'config.dart';

http.Client createDefaultClient(Platform platform) {
  if (platform == Platform.web) {
    return BrowserClient()..withCredentials = true;
  }
  return http.Client();
}
