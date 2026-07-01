//
//
// ======================================================

import 'package:bip39/bip39.dart' as bip39;
import 'package:solana/base58.dart';
import 'package:solana/solana.dart';

import '../models/mnemonic_secret.dart';
import '../models/wallet_info.dart';
import '../models/wallet_material.dart';
import '../models/wallet_secret.dart';

import '../models/mnemonic_strength.dart';

import '../models/solana_derivation.dart';
import '../models/wallet_exception.dart';

// ======================================================

//
class SolanaWalletCreationService {
  //

  // ======================================================

  const SolanaWalletCreationService();

  // ======================================================

  Future<WalletMaterial> createWallet({
    MnemonicStrength mnemonicStrength = MnemonicStrength.words12,
    SolanaDerivation derivation = SolanaDerivation.primary,
  }) async {
    //

    final mnemonicPhrase = bip39.generateMnemonic(
      strength: mnemonicStrength.bits, //
    );

    return _deriveWallet(
      mnemonicPhrase: mnemonicPhrase,
      derivation: derivation,
      source: WalletInfo.createdInAppSource,
    );
  }

  // ======================================================

  Future<WalletMaterial> restoreFromMnemonic(
    String mnemonicPhrase, {
    SolanaDerivation derivation = SolanaDerivation.primary,
  }) async {
    //

    final normalizedMnemonic = _normalizeMnemonic(mnemonicPhrase);

    if (!bip39.validateMnemonic(normalizedMnemonic)) {
      throw const WalletException('Enter a valid recovery phrase.');
    }

    return _deriveWallet(
      mnemonicPhrase: normalizedMnemonic,
      derivation: derivation,
      source: WalletInfo.importedMnemonicSource,
    );
  }

  // ======================================================

  Future<WalletMaterial> _deriveWallet({
    required String mnemonicPhrase,
    required SolanaDerivation derivation,
    required String source,
  }) async {
    final rootKeyPair = await Ed25519HDKeyPair.fromMnemonic(
      mnemonicPhrase,
      account: SolanaDerivation.primary.accountIndex,
      change: SolanaDerivation.primary.changeIndex,
    );

    final keyPair = await Ed25519HDKeyPair.fromMnemonic(
      mnemonicPhrase,
      account: derivation.accountIndex,
      change: derivation.changeIndex,
    );

    final info = WalletInfo.solana(
      address: keyPair.address,
      rootId: rootKeyPair.address,
      derivationPath: derivation.path,
      source: source,
    );

    final keyPairData = await keyPair.extract();

    return WalletMaterial(
      info: info,
      secret: WalletSecret(
        info: info,
        privateKeyBase58: base58encode(keyPairData.bytes),
      ),
      mnemonicSecret: MnemonicSecret(
        rootId: rootKeyPair.address,
        mnemonic: mnemonicPhrase.split(' '),
      ),
    );
  }

  // ======================================================

  static String _normalizeMnemonic(String value) {
    return value.trim().toLowerCase().split(RegExp(r'\s+')).join(' ');
  }

  // ======================================================
}
