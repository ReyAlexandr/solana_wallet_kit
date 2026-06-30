//
//
// ======================================================

import 'package:bip39/bip39.dart' as bip39;
import 'package:solana/solana.dart';

import '../models/wallet_info.dart';
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

  Future<WalletSecret> createWallet({
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

  Future<WalletSecret> restoreFromMnemonic(
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

  Future<WalletSecret> _deriveWallet({
    required String mnemonicPhrase,
    required SolanaDerivation derivation,
    required String source,
  }) async {
    final keyPair = await Ed25519HDKeyPair.fromMnemonic(
      mnemonicPhrase,
      account: derivation.accountIndex,
      change: derivation.changeIndex,
    );

    final info = WalletInfo.solana(
      address: keyPair.address,
      derivationPath: derivation.path,
      source: source,
    );

    return WalletSecret(
      info: info,
      mnemonic: mnemonicPhrase.split(' '),
    );
  }

  // ======================================================

  static String _normalizeMnemonic(String value) {
    return value.trim().toLowerCase().split(RegExp(r'\s+')).join(' ');
  }

  // ======================================================
}
