# novyse_auth

Flutter client for the Novyse authentication backend. The public API mirrors
`@novyse/auth`: OPAQUE signup/signin, token refresh, session management, API
keys, QR login, password setup, account deletion and logout.

## OPAQUE adapter

There is currently no compatible OPAQUE package on pub.dev. The backend uses
`@serenity-kit/opaque` and requires real OPAQUE messages, so this package does
not implement cryptography or send passwords as a workaround. Provide an
`OpaqueClient` backed by a verified Dart/native implementation before calling
`signup.opaque`, `signin.opaque` or `settings.opaque`.

The HTTP API and all payloads are aligned with the backend routes and the
TypeScript SDK.

## Usage

```dart
final auth = NovyseAuth(NovyseAuthOptions(
  platform: Platform.mobile,
  baseUrl: Uri.parse('http://localhost:3000'), // optional, useful in tests
  storageAdapter: MySecureStorageAdapter(),
));

final result = await auth.apikey.list();
final jwt = await auth.token.get();
```

For production storage, adapt `flutter_secure_storage` to `StorageAdapter`.
The package accepts an injected `http.Client`, making endpoint tests and
custom platform clients straightforward.

## Validation

```bash
flutter pub get
dart analyze
flutter test
dart pub publish --dry-run
```
