import 'dart:convert';
import 'package:http/http.dart' as http;

typedef JsonMap = Map<String, dynamic>;
const opaqueServerIdentity = 'novyse-auth-service';

enum Branch { development, preview, production }

enum Platform { mobile, desktop, web }

String authDomain(Branch branch) => switch (branch) {
      Branch.production => 'auth.novyse.com',
      Branch.preview => 'auth.preview.novyse.com',
      Branch.development => 'auth.dev.novyse.com'
    };

class ApiException implements Exception {
  const ApiException(this.message, this.statusCode);
  final String message;
  final int statusCode;
  @override
  String toString() => message;
}

class AuthApi {
  AuthApi(this.baseUrl, this.client);
  final Uri baseUrl;
  final http.Client client;
  Future<JsonMap> send(String method, String path,
      {Object? body, Map<String, String> headers = const {}}) async {
    final request = http.Request(method, baseUrl.resolve(path));
    request.headers.addAll({'content-type': 'application/json', ...headers});
    if (body != null) request.body = jsonEncode(body);
    final response = await client.send(request);
    final text = await response.stream.bytesToString();
    final data =
        text.isEmpty ? <String, dynamic>{} : jsonDecode(text) as JsonMap;
    if (response.statusCode < 200 || response.statusCode >= 300)
      throw ApiException(
          data['message'] as String? ??
              data['error'] as String? ??
              'Request failed (${response.statusCode})',
          response.statusCode);
    return data;
  }
}

Map<String, String> authHeaders(String? token) =>
    token == null ? {} : {'authorization': 'Bearer $token'};
