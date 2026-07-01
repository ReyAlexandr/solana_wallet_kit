import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:solana_wallet_kit/solana_wallet_kit.dart';

void main() {
  const mnemonic = 'nothing steak step patient peasant assist add coral tone harsh hint dilemma';
  const creationService = SolanaWalletCreationService();
  const exportService = WalletPhraseExportService();
  const importService = WalletPhraseImportService();

  test('export and import round-trip preserves verified wallet metadata', () async {
    final wallet = await creationService.restoreFromMnemonic(
      mnemonic,
      derivation: SolanaDerivation(accountIndex: 2, changeIndex: 1),
    );
    final file = exportService.createFile(wallet);
    final backup = await importService.readBackup(file);

    expect(backup.mnemonicPhrase, mnemonic);
    expect(backup.address, wallet.address);
    expect(backup.rootId, wallet.rootId);
    expect(backup.privateKeyBase58, wallet.privateKeyBase58);
    expect(backup.derivation.path, wallet.derivationPath);
  });

  test('export clearly marks backup as unencrypted', () async {
    final wallet = await creationService.restoreFromMnemonic(mnemonic);
    final file = exportService.createFile(wallet);
    final data = jsonDecode(file.contents) as Map<String, dynamic>;

    expect(data['format'], WalletPhraseExportService.formatId);
    expect(data['encrypted'], isFalse);
    expect(data['warning'], isNotEmpty);
    expect(data['private_key'], wallet.privateKeyBase58);
    expect(data['private_key_encoding'], 'base58');
    expect(data['root_id'], wallet.rootId);
  });

  test('import rejects a backup with a tampered address', () async {
    final wallet = await creationService.restoreFromMnemonic(mnemonic);
    final file = exportService.createFile(wallet);
    final data = jsonDecode(file.contents) as Map<String, dynamic>;
    data['address'] = '7vVcBLQwT1rmjiTXhhvmHKfiaCda2giGMeKchc2jwmBN';

    await expectLater(
      importService.readBackup(
        WalletPhraseFile(
          fileName: file.fileName,
          contents: jsonEncode(data),
        ),
      ),
      throwsA(isA<WalletException>()),
    );
  });

  test('import rejects a backup with an invalid derivation path', () async {
    final wallet = await creationService.restoreFromMnemonic(mnemonic);
    final file = exportService.createFile(wallet);
    final data = jsonDecode(file.contents) as Map<String, dynamic>;
    data['derivation_path'] = "m/44'/60'/0'/0'";

    await expectLater(
      importService.readBackup(
        WalletPhraseFile(
          fileName: file.fileName,
          contents: jsonEncode(data),
        ),
      ),
      throwsA(isA<WalletException>()),
    );
  });

  test('import rejects a backup with a tampered private key', () async {
    final wallet = await creationService.restoreFromMnemonic(mnemonic);
    final file = exportService.createFile(wallet);
    final data = jsonDecode(file.contents) as Map<String, dynamic>;
    data['private_key'] = 'tampered';

    await expectLater(
      importService.readBackup(
        WalletPhraseFile(
          fileName: file.fileName,
          contents: jsonEncode(data),
        ),
      ),
      throwsA(isA<WalletException>()),
    );
  });

  test('import rejects unknown backup formats', () async {
    final wallet = await creationService.restoreFromMnemonic(mnemonic);
    final file = exportService.createFile(wallet);
    final data = jsonDecode(file.contents) as Map<String, dynamic>;
    data['format'] = 'unknown';

    await expectLater(
      importService.readBackup(
        WalletPhraseFile(
          fileName: file.fileName,
          contents: jsonEncode(data),
        ),
      ),
      throwsA(isA<WalletException>()),
    );
  });
}
