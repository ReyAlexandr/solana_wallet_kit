//
//
// ======================================================

import '../models/wallet_secret.dart';
import '../models/wallet_info.dart';
import '../solana/solana_wallet_creation_service.dart';
import '../storage/secure_wallet_secret_store.dart';
import '../storage/wallet_secret_store.dart';
import '../models/mnemonic_strength.dart';
import '../models/solana_derivation.dart';

// ======================================================
//
//

class WalletRegistryService {
  //

  // ======================================================

  const WalletRegistryService({
    //
    SolanaWalletCreationService? creationService,
    WalletSecretStore? secretStore,
    //
  }) : _creationService = creationService ?? const SolanaWalletCreationService(),
       _secretStore = secretStore ?? const SecureWalletSecretStore();

  // ======================================================

  final SolanaWalletCreationService _creationService;
  final WalletSecretStore _secretStore;

  // ======================================================

  Future<WalletInfo> createAndSaveSolanaWallet({
    MnemonicStrength mnemonicStrength = MnemonicStrength.words12,
    SolanaDerivation derivation = SolanaDerivation.primary,
  }) async {
    //

    final wallet = await _creationService.createWallet(
      mnemonicStrength: mnemonicStrength,
      derivation: derivation,
    );

    await _secretStore.saveWalletSecret(wallet);

    return wallet.info;
  }

  // ======================================================

  Future<WalletInfo> restoreAndSaveSolanaWallet({
    required String mnemonicPhrase,
    SolanaDerivation derivation = SolanaDerivation.primary,
  }) async {
    //

    final wallet = await _creationService.restoreFromMnemonic(
      mnemonicPhrase,
      derivation: derivation,
    );

    await _secretStore.saveWalletSecret(wallet);

    return wallet.info;
  }

  // ======================================================

  Future<List<String>?> readSolanaMnemonic({
    required String address, //
  }) {
    return _secretStore.readSolanaMnemonic(address: address);
  }

  // ======================================================

  Future<void> deleteSolanaMnemonic({required String address}) {
    return _secretStore.deleteSolanaMnemonic(address: address);
  }

  // ======================================================

  Future<WalletSecret> createWalletSecretForBackup({
    MnemonicStrength mnemonicStrength = MnemonicStrength.words12,
    SolanaDerivation derivation = SolanaDerivation.primary,
  }) {
    return _creationService.createWallet(
      mnemonicStrength: mnemonicStrength,
      derivation: derivation,
    );
  }

  // ======================================================

  Future<WalletInfo> deriveSolanaAccount({
    required String mnemonicPhrase,
    required int accountIndex,
    int changeIndex = 0,
  }) async {
    final wallet = await _creationService.restoreFromMnemonic(
      mnemonicPhrase,
      derivation: SolanaDerivation(
        accountIndex: accountIndex,
        changeIndex: changeIndex,
      ),
    );

    return wallet.info;
  }

  // ======================================================

  Future<void> saveBackedUpWalletSecret(
    WalletSecret wallet, //
  ) {
    return _secretStore.saveWalletSecret(wallet);
  }
}

// ======================================================
//
//
