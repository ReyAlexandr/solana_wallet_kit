# Solana Wallet Kit Project Guide

## Purpose

`solana_wallet_kit` is a Flutter plugin for creating and restoring
self-custodial Solana wallets. Recovery phrases stay inside the package and are
stored with `flutter_secure_storage`; host callbacks receive only
`WalletAccount`.

## Navigation

- `lib/solana_wallet_kit.dart`: public package entry point.
- `lib/wallet/`: models, services, storage, widgets, and ready-made screens.
- `android/`: package-owned Android document export plugin.
- `example/`: Android host-app integration example and security configuration.
- `doc/USAGE.md`: public integration and customization guide.
- `test/`: unit and widget tests.
- `wallet_old/`: ignored local archive; never import from or publish it.

## Development

- Run `flutter analyze` and `flutter test` from the repository root.
- Build the example with `cd example && flutter build apk --debug`.
- Format Dart with `dart format lib test example/lib`.
- Before publishing, run `dart pub publish --dry-run`.
- Never log, transmit, analyze, or crash-report mnemonic phrases or private key
  material.
- Keep Android backup exclusion documented and enabled in the example app.
- Version `0.1.0` supports and verifies Android only; iOS support is planned.

## Public Release

- Package name: `solana_wallet_kit`.
- Start preview releases at `0.1.x` and document user-visible changes in
  `CHANGELOG.md`.
- Keep README installation, Android setup, security boundaries, and public APIs
  synchronized with implementation changes.
- Update this file whenever package layout, commands, public APIs, security
  requirements, or platform support changes.
