export 'http_client_stub.dart'
    if (dart.library.js_interop) 'http_client_web.dart'
    if (dart.library.html) 'http_client_web.dart';
