# novyse_auth

Flutter client for the Novyse authentication backend. The public API mirrors
`@novyse/auth`: OPAQUE signup/signin, token refresh, session management, API
keys, QR login, password setup, account deletion and logout.

## OPAQUE adapter

The package includes native Rust-backed OPAQUE support for Mobile, Desktop, and Web via `flutter_opaque`.

The HTTP API and all payloads are aligned with the backend routes and the
TypeScript SDK.

## Usage

```dart
final auth = NovyseAuth(NovyseAuthOptions(
  platform: Platform.mobile, // Platform.mobile, Platform.desktop, Platform.web
  branch: Branch.development, // Branch.production, Branch.preview, Branch.development
  baseUrl: Uri.parse('http://localhost:3000'), // optional, useful in tests
));

final result = await auth.apikey.list();
final jwt = await auth.token.get();
```

Storage and HTTP credentials are automatically handled per platform:
- **Mobile / Desktop**: Automatically persists `sessionId` using `FlutterSecureStorage`.
- **Web**: Uses browser credentials (`withCredentials: true`) to automatically send and maintain `HttpOnly` session cookies.

## Validation

```bash
flutter pub get
dart analyze
flutter test
dart pub publish --dry-run
```
