//
//
// ======================================================

import '../models/created_solana_wallet.dart';
import '../models/wallet_account.dart';
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

  Future<WalletAccount> createAndSaveSolanaWallet({
    MnemonicStrength mnemonicStrength = MnemonicStrength.words12,
    SolanaDerivation derivation = SolanaDerivation.primary,
  }) async {
    //

    final wallet = await _creationService.createWallet(
      mnemonicStrength: mnemonicStrength,
      derivation: derivation,
    );

    await _secretStore.saveCreatedSolanaWallet(wallet);

    return wallet.account;
  }

  // ======================================================

  Future<WalletAccount> restoreAndSaveSolanaWallet({
    required String mnemonicPhrase,
    SolanaDerivation derivation = SolanaDerivation.primary,
  }) async {
    //

    final wallet = await _creationService.restoreFromMnemonic(
      mnemonicPhrase,
      derivation: derivation,
    );

    await _secretStore.saveCreatedSolanaWallet(wallet);

    return wallet.account;
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

  Future<CreatedSolanaWallet> createSolanaWalletForBackup({
    MnemonicStrength mnemonicStrength = MnemonicStrength.words12,
    SolanaDerivation derivation = SolanaDerivation.primary,
  }) {
    return _creationService.createWallet(
      mnemonicStrength: mnemonicStrength,
      derivation: derivation,
    );
  }

  // ======================================================

  Future<WalletAccount> deriveSolanaAccount({
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

    return wallet.account;
  }

  // ======================================================

  Future<void> saveBackedUpSolanaWallet(
    CreatedSolanaWallet wallet, //
  ) {
    return _secretStore.saveCreatedSolanaWallet(wallet);
  }
}

// ======================================================
//
//
