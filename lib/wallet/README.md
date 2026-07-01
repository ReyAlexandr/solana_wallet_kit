# Wallet module security notes

This module creates and restores BIP39 Solana wallets locally.

- Recovery phrases must never be logged, sent to APIs, added to analytics, or
  included in crash reports.
- Screens save wallet material through `WalletStore` before invoking the host
  completion callback.
- Host completion callbacks intentionally receive only `WalletInfo`.
- `SecureWalletSecretStore` stores wallet info, per-address private keys, and
  mnemonic roots separately, and rejects web builds.
- Android host apps must disable cloud backup and device transfer.
- `WalletSensitiveContent` obscures wallet UI while the app is inactive. It
  deliberately avoids Flutter's unstable `SensitiveContent` registration API.

JSON exports are unencrypted and include the recovery phrase plus private key.
Anyone with an exported file can control the wallet. The create screen requires
explicit confirmation before export.

One mnemonic can derive multiple addresses through `SolanaDerivation`.
`WalletInfo.rootId` identifies the primary root address, while mnemonic phrases
are stored once under that root and per-address private keys use
`wallet.solana.pk.<address>`.
