import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solana_wallet_kit/solana_wallet_kit.dart';

void main() {
  const mnemonic = 'nothing steak step patient peasant assist add coral tone harsh hint dilemma';
  const creationService = SolanaWalletCreationService();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('secure store saves, reads, and deletes a valid recovery phrase', () async {
    final wallet = await creationService.restoreFromMnemonic(mnemonic);
    const store = SecureWalletSecretStore();

    await store.saveCreatedSolanaWallet(wallet);
    expect(await store.readSolanaMnemonic(address: wallet.address), mnemonic.split(' '));

    await store.deleteSolanaMnemonic(address: wallet.address);
    expect(await store.readSolanaMnemonic(address: wallet.address), isNull);
  });

  test('secure store rejects invalid wallet addresses', () async {
    const store = SecureWalletSecretStore();

    await expectLater(
      store.readSolanaMnemonic(address: 'not-an-address'),
      throwsA(isA<WalletException>()),
    );
  });

  test('secure store detects corrupted stored recovery phrases', () async {
    final wallet = await creationService.restoreFromMnemonic(mnemonic);
    FlutterSecureStorage.setMockInitialValues({
      'wallet.solana.mnemonic.${wallet.address}': 'invalid recovery phrase',
    });
    const store = SecureWalletSecretStore();

    await expectLater(
      store.readSolanaMnemonic(address: wallet.address),
      throwsA(isA<WalletException>()),
    );
  });
}
