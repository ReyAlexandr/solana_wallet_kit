# Usage Guide

This guide explains the available integration levels and customization options
in `solana_wallet_kit`.

## 1. Choose an integration style

### Complete setup flow

Use `WalletSetupScreen` when the host app needs a ready-made entry screen with
Create and Restore actions:

```dart
WalletSetupScreen(
  onWalletReady: (account) async {
    await savePublicAddress(account.address);
    navigateAfterWalletSetup();
  },
)
```

This is the recommended starting point. The package handles generation,
restoration, backup UI, phrase confirmation, and secure local persistence.

### Separate Create and Restore screens

Use the individual screens when the host app already has its own wallet-choice
page or navigation structure:

```dart
CreateSolanaWalletScreen(
  onContinue: handleWalletReady,
)
```

```dart
RestoreSolanaWalletScreen(
  onContinue: handleWalletReady,
)
```

Both completion callbacks receive a `WalletAccount`, never the recovery phrase.

### Service-level integration

Use `WalletRegistryService` when you need wallet operations without the
ready-made screens:

```dart
const service = WalletRegistryService();

final account = await service.restoreAndSaveSolanaWallet(
  mnemonicPhrase: phraseEnteredByTheUser,
);
```

Service-level code can temporarily handle a recovery phrase, so keep it out of
logs, analytics, crash reports, application state snapshots, and backend
requests.

## 2. Handle completion correctly

The package saves the recovery phrase before calling `onWalletReady`,
`onContinue`, or `WalletRestoredCallback`.

The callback should perform host-owned work such as:

- Saving the public wallet address to a backend.
- Updating application state.
- Navigating to the next screen.

```dart
Future<void> handleWalletReady(WalletAccount account) async {
  await api.addWalletAddress(account.address);
  await refreshCurrentUser();
}
```

Make this operation idempotent. If backend registration fails, the screen keeps
the saved wallet available and lets the user retry the host callback.

Useful public account fields include:

```dart
account.chain;
account.address;
account.label;
account.source;
account.derivationPath;
```

Do not expect a mnemonic or private key in the callback.

## 3. Customize the screens

### Theme

The screens use the nearest Flutter `ThemeData`, so configure colors,
typography, buttons, inputs, and app bars in the host application:

```dart
MaterialApp(
  theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
  ),
  home: const MyHomeScreen(),
)
```

### Wording

Pass `WalletUiText` to change the built-in copy:

```dart
WalletSetupScreen(
  text: const WalletUiText(
    setupTitle: 'Connect your wallet',
    setupMessage: 'Create a wallet or recover one you already own.',
    continueAction: 'Finish setup',
    restoreContinueAction: 'Recover wallet',
  ),
  onWalletReady: handleWalletReady,
)
```

`WalletUiText` also includes action labels, tooltips, success messages, and the
host-callback failure message.

### Recovery phrase lengths

Create and Restore support 12, 15, 18, 21, and 24 words by default. Restrict
the choices when an application wants a smaller set:

```dart
CreateSolanaWalletScreen(
  strengthOptions: const [
    MnemonicStrength.words12,
    MnemonicStrength.words24,
  ],
  initialStrength: MnemonicStrength.words12,
  onContinue: handleWalletReady,
)
```

Use the same allowed values on the Restore screen if imported phrases should
follow the same policy.

### Layout

`phraseColumns` sets the maximum number of mnemonic columns. The widgets
automatically reduce the count on narrow screens:

```dart
RestoreSolanaWalletScreen(
  phraseColumns: 3,
  onContinue: handleWalletReady,
)
```

### Backup confirmation and lifecycle privacy

The Create screen asks users to confirm selected recovery words before saving.
Keep this enabled for normal applications:

```dart
CreateSolanaWalletScreen(
  requireBackupConfirmation: true,
  protectSensitiveContent: true,
  onContinue: handleWalletReady,
)
```

`protectSensitiveContent` covers the screen when the application is paused or
inactive. It does not block all screenshots while the application is in the
foreground.

## 4. Configure backup import and export

### Default behavior

The default backup flow:

- Exports on Android through the system `ACTION_CREATE_DOCUMENT` picker.
- Imports JSON backups through `file_selector`.
- Uses `WalletPhraseImportService` to validate imported metadata against the
  derived Solana address.

The exported JSON contains the recovery phrase in plain text. Anyone with the
file can control the wallet.

### Replace both operations

Implement `WalletBackupGateway` for an application-specific file flow:

```dart
class AppWalletBackupGateway implements WalletBackupGateway {
  @override
  Future<bool> exportBackup(WalletPhraseFile file) async {
    return saveWithHostFileService(
      name: file.fileName,
      contents: file.contents,
    );
  }

  @override
  Future<WalletPhraseFile?> importBackup() {
    return loadWithHostFileService();
  }
}
```

Inject it into any supplied screen:

```dart
WalletSetupScreen(
  backupGateway: AppWalletBackupGateway(),
  onWalletReady: handleWalletReady,
)
```

### Replace one screen action

The individual screens also provide focused callbacks:

```dart
CreateSolanaWalletScreen(
  onDownloadRequested: (file) async {
    await saveBackupFile(file);
  },
  onContinue: handleWalletReady,
)
```

```dart
RestoreSolanaWalletScreen(
  onImportRequested: pickBackupFile,
  onContinue: handleWalletReady,
)
```

`pickBackupFile` returns `WalletPhraseFile?`; return `null` when the user
cancels.

## 5. Use custom secret storage

The default `SecureWalletSecretStore` uses OS-protected storage. Advanced hosts
can implement `WalletSecretStore` and inject it through
`WalletRegistryService`:

```dart
final walletService = WalletRegistryService(
  secretStore: MyReviewedWalletSecretStore(),
);

WalletSetupScreen(
  walletService: walletService,
  onWalletReady: handleWalletReady,
)
```

A custom store must securely implement save, read, and delete operations. Do
not replace secure storage with preferences, a normal database, plaintext
files, or backend persistence.

## 6. Derive and manage accounts

`SolanaDerivation.primary` uses:

```text
m/44'/501'/0'/0'
```

Derive another public account from a phrase with:

```dart
final account = await service.deriveSolanaAccount(
  mnemonicPhrase: phrase,
  accountIndex: 1,
);
```

The current secure store indexes a phrase by address. Before presenting many
derived accounts from one phrase, introduce a reviewed root-wallet model so
the phrase is stored once and accounts reference that root.

Read or delete a stored phrase only when implementing a reviewed wallet
operation:

```dart
final words = await service.readSolanaMnemonic(address: address);
await service.deleteSolanaMnemonic(address: address);
```

Treat the returned words as highly sensitive and clear references as soon as
the operation finishes.

## 7. Android checklist

Before shipping:

1. Set Android minimum SDK to 23 or newer.
2. Disable Android cloud backup and device transfer.
3. Copy the example `data_extraction_rules.xml`.
4. Perform a full rebuild after adding the plugin.
5. Test Create, Restore, export, import, cancellation, and app
   pause/resume behavior on a real device.
6. Confirm no recovery phrase reaches logs, analytics, crash reporting, or the
   backend.

See the root [README](../README.md) for the exact manifest configuration.

## 8. Current limitations

- Version `0.1.0` currently supports and verifies Android only; iOS support is
  planned for a future release.
- Web secure storage is intentionally unsupported.
- JSON backups are not encrypted.
- Lifecycle obscuring is not a universal screenshot blocker.
- The package currently targets Solana only.
