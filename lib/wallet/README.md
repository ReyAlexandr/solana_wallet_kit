# Wallet module security notes

This module creates and restores BIP39 Solana wallets locally.

- Recovery phrases must never be logged, sent to APIs, added to analytics, or
  included in crash reports.
- Screens save phrases through `WalletSecretStore` before invoking the host
  completion callback.
- Host completion callbacks intentionally receive only `WalletInfo`.
- `SecureWalletSecretStore` rejects web builds.
- Android host apps must disable cloud backup and device transfer.
- `WalletSensitiveContent` obscures wallet UI while the app is inactive. It
  deliberately avoids Flutter's unstable `SensitiveContent` registration API.

JSON exports are unencrypted. Anyone with an exported file can control the
wallet. The create screen requires explicit confirmation before export.

One mnemonic can derive multiple addresses through `SolanaDerivation`. The
current secure store indexes phrases by address. Introduce a root-wallet record
before persisting many derived accounts from one mnemonic.
