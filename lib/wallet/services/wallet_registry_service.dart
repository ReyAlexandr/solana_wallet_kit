//
//
// ======================================================

import '../models/wallet_info.dart';
import '../models/wallet_material.dart';
import '../models/wallet_secret.dart';
import '../models/wallet_exception.dart';
import '../solana/solana_wallet_creation_service.dart';
import '../storage/secure_wallet_secret_store.dart';
import '../storage/wallet_store.dart';
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
    WalletStore? walletStore,
    //
  }) : _creationService = creationService ?? const SolanaWalletCreationService(),
       _walletStore = walletStore ?? const SecureWalletSecretStore();

  // ======================================================

  final SolanaWalletCreationService _creationService;
  final WalletStore _walletStore;

  // ======================================================

  Future<WalletInfo> createAndSaveSolanaWallet({
    MnemonicStrength mnemonicStrength = MnemonicStrength.words12,
    SolanaDerivation derivation = SolanaDerivation.primary,
  }) async {
    //

    final material = await _creationService.createWallet(
      mnemonicStrength: mnemonicStrength,
      derivation: derivation,
    );

    await _walletStore.saveWalletMaterial(material);

    return material.info;
  }

  // ======================================================

  Future<WalletInfo> restoreAndSaveSolanaWallet({
    required String mnemonicPhrase,
    SolanaDerivation derivation = SolanaDerivation.primary,
  }) async {
    //

    final material = await _creationService.restoreFromMnemonic(
      mnemonicPhrase,
      derivation: derivation,
    );

    await _walletStore.saveWalletMaterial(material);

    return material.info;
  }

  // ======================================================

  Future<List<String>?> readSolanaMnemonic({
    required String address, //
  }) async {
    final info = await _walletStore.readWalletInfo(address: address);
    if (info == null) return null;

    final secret = await _walletStore.readMnemonicSecret(rootId: info.rootId);
    return secret?.mnemonic;
  }

  // ======================================================

  Future<WalletMaterial?> readWalletMaterial({
    required String address, //
  }) async {
    final secret = await _walletStore.readWalletSecret(address: address);
    if (secret == null) return null;

    final mnemonicSecret = await _walletStore.readMnemonicSecret(
      rootId: secret.rootId,
    );

    return WalletMaterial(
      info: secret.info,
      secret: secret,
      mnemonicSecret: mnemonicSecret,
    );
  }

  // ======================================================

  Future<void> deleteSolanaMnemonic({required String address}) async {
    final info = await _walletStore.readWalletInfo(address: address);
    if (info == null) return;

    await _walletStore.deleteMnemonicSecret(rootId: info.rootId);
  }

  // ======================================================

  Future<void> deleteSolanaWallet({
    required String address,
    bool deleteMnemonicRoot = false,
  }) async {
    final info = await _walletStore.readWalletInfo(address: address);
    await _walletStore.deleteWallet(address: address);

    if (deleteMnemonicRoot && info != null) {
      await _walletStore.deleteMnemonicSecret(rootId: info.rootId);
    }
  }

  // ======================================================

  Future<WalletMaterial> createWalletMaterialForBackup({
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
    final material = await _creationService.restoreFromMnemonic(
      mnemonicPhrase,
      derivation: SolanaDerivation(
        accountIndex: accountIndex,
        changeIndex: changeIndex,
      ),
    );

    return material.info;
  }

  // ======================================================

  Future<WalletInfo> deriveAndSaveSolanaAddress({
    required String sourceAddress,
    required int accountIndex,
    int changeIndex = 0,
  }) async {
    final sourceInfo = await _walletStore.readWalletInfo(
      address: sourceAddress,
    );
    if (sourceInfo == null) {
      throw const WalletException('Wallet is not available on this device.');
    }

    final mnemonicSecret = await _walletStore.readMnemonicSecret(
      rootId: sourceInfo.rootId,
    );
    if (mnemonicSecret == null) {
      throw const WalletException(
        'Recovery phrase is not available on this device.',
      );
    }

    final material = await _creationService.restoreFromMnemonic(
      mnemonicSecret.mnemonicPhrase,
      derivation: SolanaDerivation(
        accountIndex: accountIndex,
        changeIndex: changeIndex,
      ),
    );

    if (material.rootId != sourceInfo.rootId) {
      throw const WalletException('Stored recovery phrase does not match wallet.');
    }

    await _walletStore.saveWalletMaterial(material);

    return material.info;
  }

  // ======================================================

  Future<void> saveBackedUpWalletMaterial(
    WalletMaterial material, //
  ) {
    return _walletStore.saveWalletMaterial(material);
  }

  // ======================================================

  Future<List<WalletInfo>> readWalletInfos({required String rootId}) {
    return _walletStore.readWalletInfos(rootId: rootId);
  }

  // ======================================================

  Future<WalletInfo?> readWalletInfo({
    required String address, //
  }) {
    return _walletStore.readWalletInfo(address: address);
  }

  // ======================================================

  Future<WalletSecret?> readWalletSecret({
    required String address, //
  }) {
    return _walletStore.readWalletSecret(address: address);
  }
}

// ======================================================
//
//
