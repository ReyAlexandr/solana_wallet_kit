# Solana Wallet Kit

`solana_wallet_kit` is a Flutter plugin for adding self-custodial Solana wallet
creation and restoration to an application.

It provides ready-made, theme-aware screens while keeping the security boundary
small: recovery phrases are generated on-device, stored in protected local
storage, and never returned through the host application's completion callback.
The host receives only the public `WalletAccount`.

> This package is an early preview. Review the security model and test the
> complete flow for your application before using it with real funds.

## What it includes

- A `WalletSetupScreen` with Create and Restore choices.
- Standalone Create and Restore screens for custom navigation.
- BIP39 recovery phrases with 12, 15, 18, 21, or 24 words.
- Solana account derivation and address validation.
- Secure local recovery-phrase storage.
- Android system-document backup export without broad storage permissions.
- Verified JSON backup import.
- Responsive layouts that inherit the host application's `ThemeData`.
- Customizable titles, instructions, labels, tooltips, and messages.
- Lifecycle obscuring while the app is inactive.
- Injectable storage, clipboard, import, and export services.

## Installation

From pub.dev:

```sh
flutter pub add solana_wallet_kit
```

Until the first pub.dev release, use the Git repository:

```yaml
dependencies:
  solana_wallet_kit:
    git:
      url: https://github.com/ReyAlexandr/solana_wallet_kit.git
```

Import the package:

```dart
import 'package:solana_wallet_kit/solana_wallet_kit.dart';
```

## Quick start

Open the complete setup screen and decide what the host app should do after the
wallet is securely saved:

```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => WalletSetupScreen(
      onWalletReady: (account) async {
        // The callback receives public account data only.
        await api.saveWalletAddress(account.address);

        if (!context.mounted) return;
        Navigator.of(context).pushReplacementNamed('/next');
      },
    ),
  ),
);
```

`onWalletReady` runs after secure local persistence succeeds. Make the callback
idempotent because users can retry it after a network or navigation failure.

For separate screens, custom backup behavior, supported phrase lengths,
service-level usage, and other options, read the
[Usage Guide](doc/USAGE.md).

## Required Android configuration

The host application must prevent wallet secrets from entering cloud backup or
device-to-device transfer.

Configure the host application's `<application>` element:

```xml
<application
    android:allowBackup="false"
    android:fullBackupContent="false"
    android:dataExtractionRules="@xml/data_extraction_rules">
```

Copy
[`example/android/app/src/main/res/xml/data_extraction_rules.xml`](example/android/app/src/main/res/xml/data_extraction_rules.xml)
into the host application. The host Android minimum SDK must be 23 or newer.

Backup export uses Android's `ACTION_CREATE_DOCUMENT` flow. It requires no broad
storage permission because Android grants access only to the destination the
user selects.

After first adding the plugin, perform a full rebuild:

```sh
flutter clean
flutter pub get
flutter run
```

## Security model

- Recovery phrases are generated and restored locally.
- Default storage uses `flutter_secure_storage`.
- Completion callbacks receive only `WalletAccount`.
- Recovery phrases must never be sent to a backend, logs, analytics, or crash
  reports.
- Exported JSON backups are unencrypted and must be protected like the recovery
  phrase itself.
- `protectSensitiveContent` hides wallet screens while the app is inactive. It
  is not a universal foreground screenshot blocker.
- Web secret storage is intentionally unsupported.

Please report vulnerabilities privately as described in
[SECURITY.md](SECURITY.md).

## Platform support

Version `0.1.0` currently supports and verifies Android only. iOS support is
planned for a future release. Platform-neutral Dart code may work elsewhere,
but other platforms are not currently promised or tested.

## Example and development

The [`example`](example/) app demonstrates the complete host integration and
required Android configuration.

```sh
flutter pub get
flutter analyze
flutter test
cd example
flutter build apk --debug
```

## License

MIT. See [LICENSE](LICENSE).

## Built with

This package builds on these open-source projects:

- [`solana`](https://pub.dev/packages/solana) — Solana key generation, account
  derivation, and address utilities.
- [`bip39`](https://pub.dev/packages/bip39) — recovery-phrase generation and
  validation.
- [`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage) —
  protected local storage for recovery phrases.
- [`file_selector`](https://pub.dev/packages/file_selector) — backup-file
  selection and platform file dialogs.
