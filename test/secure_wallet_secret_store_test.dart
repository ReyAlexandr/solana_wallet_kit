import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solana_wallet_kit/solana_wallet_kit.dart';

void main() {
  const mnemonic = 'nothing steak step patient peasant assist add coral tone harsh hint dilemma';
  const creationService = SolanaWalletCreationService();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('secure store saves wallet info, private key, and mnemonic root', () async {
    final wallet = await creationService.restoreFromMnemonic(mnemonic);
    const store = SecureWalletSecretStore();

    await store.saveWalletMaterial(wallet);

    final info = await store.readWalletInfo(address: wallet.address);
    final secret = await store.readWalletSecret(address: wallet.address);
    final mnemonicSecret = await store.readMnemonicSecret(rootId: wallet.rootId);

    expect(info?.address, wallet.address);
    expect(secret?.privateKeyBase58, wallet.privateKeyBase58);
    expect(mnemonicSecret?.mnemonic, mnemonic.split(' '));

    await store.deleteWallet(address: wallet.address);
    expect(await store.readWalletInfo(address: wallet.address), isNull);
    expect(await store.readWalletSecret(address: wallet.address), isNull);
    expect(await store.readMnemonicSecret(rootId: wallet.rootId), isNotNull);

    await store.deleteMnemonicSecret(rootId: wallet.rootId);
    expect(await store.readMnemonicSecret(rootId: wallet.rootId), isNull);
  });

  test('secure store rejects invalid wallet addresses', () async {
    const store = SecureWalletSecretStore();

    await expectLater(
      store.readWalletInfo(address: 'not-an-address'),
      throwsA(isA<WalletException>()),
    );
  });

  test('secure store detects corrupted stored recovery phrases', () async {
    final wallet = await creationService.restoreFromMnemonic(mnemonic);
    FlutterSecureStorage.setMockInitialValues({
      'wallet.solana.mnemonic.${wallet.rootId}': 'invalid recovery phrase',
    });
    const store = SecureWalletSecretStore();

    await expectLater(
      store.readMnemonicSecret(rootId: wallet.rootId),
      throwsA(isA<WalletException>()),
    );
  });

  test('registry derives and saves another address from the stored phrase', () async {
    const service = WalletRegistryService();
    final primary = await service.restoreAndSaveSolanaWallet(
      mnemonicPhrase: mnemonic,
    );

    final secondary = await service.deriveAndSaveSolanaAddress(
      sourceAddress: primary.address,
      accountIndex: 1,
    );
    const store = SecureWalletSecretStore();
    final secondarySecret = await store.readWalletSecret(
      address: secondary.address,
    );
    final mnemonicSecret = await store.readMnemonicSecret(
      rootId: primary.rootId,
    );
    final walletInfos = await store.readWalletInfos(rootId: primary.rootId);

    expect(secondary.address, isNot(primary.address));
    expect(secondary.rootId, primary.rootId);
    expect(secondary.derivationPath, "m/44'/501'/1'/0'");
    expect(secondarySecret?.address, secondary.address);
    expect(mnemonicSecret?.mnemonic, mnemonic.split(' '));
    expect(
      walletInfos.map((wallet) => wallet.address),
      [primary.address, secondary.address],
    );
  });
}
