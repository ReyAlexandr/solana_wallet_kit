import 'package:flutter_test/flutter_test.dart';
import 'package:solana_wallet_kit/solana_wallet_kit.dart';

void main() {
  const mnemonic = 'nothing steak step patient peasant assist add coral tone harsh hint dilemma';
  const primaryAddress = 'AZ9tSkwgBjvgNrSBKujYVobWkcVy7QuJJHUiiUs7PTG';

  const service = SolanaWalletCreationService();

  test('restores the expected primary Solana account', () async {
    final wallet = await service.restoreFromMnemonic(mnemonic);

    expect(wallet.address, primaryAddress);
    expect(wallet.derivationPath, SolanaDerivation.primary.path);
    expect(wallet.info.source, WalletInfo.importedMnemonicSource);
  });

  test('derives different addresses for different account indexes', () async {
    final primary = await service.restoreFromMnemonic(mnemonic);
    final secondary = await service.restoreFromMnemonic(
      mnemonic,
      derivation: SolanaDerivation(accountIndex: 1),
    );

    expect(secondary.address, isNot(primary.address));
    expect(secondary.derivationPath, "m/44'/501'/1'/0'");
  });

  test('invalid recovery phrase is not included in exception text', () async {
    const invalidPhrase = 'secret words that must never appear in errors';

    await expectLater(
      service.restoreFromMnemonic(invalidPhrase),
      throwsA(
        isA<WalletException>().having(
          (error) => error.toString(),
          'message',
          isNot(contains(invalidPhrase)),
        ),
      ),
    );
  });

  test('generated mnemonic length matches selected strength', () async {
    final wallet = await service.createWallet(
      mnemonicStrength: MnemonicStrength.words24,
    );

    expect(wallet.mnemonic, hasLength(24));
    expect(SolanaWalletValidator.isValidAddress(wallet.address), isTrue);
  });

  test('created mnemonic collection cannot be modified', () async {
    final wallet = await service.createWallet();

    expect(() => wallet.mnemonic!.add('word'), throwsUnsupportedError);
  });

  test('derivation parser accepts valid paths and rejects invalid paths', () {
    final parsed = SolanaDerivation.tryParse("m/44'/501'/7'/2'");

    expect(parsed?.accountIndex, 7);
    expect(parsed?.changeIndex, 2);
    expect(SolanaDerivation.tryParse("m/44'/60'/0'/0'"), isNull);
    expect(SolanaDerivation.tryParse("m/44'/501'/-1'/0'"), isNull);
  });
}
