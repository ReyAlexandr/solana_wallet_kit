//
//
// ======================================================

import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/created_solana_wallet.dart';
import '../models/wallet_exception.dart';
import '../solana/solana_wallet_validator.dart';
import 'wallet_secret_store.dart';

// ======================================================
//
//

class SecureWalletSecretStore implements WalletSecretStore {
  //

  const SecureWalletSecretStore({
    FlutterSecureStorage? storage, //
  }) : _storage =
           storage ??
           const FlutterSecureStorage(
             iOptions: IOSOptions(
               accessibility: KeychainAccessibility.unlocked_this_device,
             ),
             mOptions: MacOsOptions(
               accessibility: KeychainAccessibility.unlocked_this_device,
             ),
           );

  // ======================================================

  static const _solanaMnemonicPrefix = 'wallet.solana.mnemonic';

  final FlutterSecureStorage _storage;

  // ======================================================

  @override
  Future<void> saveCreatedSolanaWallet(
    CreatedSolanaWallet wallet, //
  ) {
    _ensureSupportedPlatform();
    _validateAddress(wallet.address);
    if (!bip39.validateMnemonic(wallet.mnemonicPhrase)) {
      throw const WalletException('Refusing to store an invalid recovery phrase.');
    }

    return _storage.write(
      key: _mnemonicKey(wallet.address),
      value: wallet.mnemonicPhrase,
    );
  }

  // ======================================================

  @override
  Future<List<String>?> readSolanaMnemonic({
    required String address, //
  }) async {
    //
    _ensureSupportedPlatform();
    _validateAddress(address);

    final mnemonicPhrase = await _storage.read(
      key: _mnemonicKey(address), //
    );

    if (mnemonicPhrase == null || mnemonicPhrase.trim().isEmpty) {
      return null;
    }

    final normalized = mnemonicPhrase.trim().split(RegExp(r'\s+')).join(' ');
    if (!bip39.validateMnemonic(normalized)) {
      throw const WalletException('Stored recovery phrase is corrupted.');
    }

    return List.unmodifiable(normalized.split(' '));
  }

  // ======================================================

  @override
  Future<void> deleteSolanaMnemonic({required String address}) {
    _ensureSupportedPlatform();
    _validateAddress(address);
    return _storage.delete(key: _mnemonicKey(address));
  }

  // ======================================================

  static String _mnemonicKey(String address) {
    return '$_solanaMnemonicPrefix.$address';
  }

  static void _validateAddress(String address) {
    if (!SolanaWalletValidator.isValidAddress(address)) {
      throw const WalletException('Invalid Solana wallet address.');
    }
  }

  static void _ensureSupportedPlatform() {
    if (kIsWeb) {
      throw const WalletException(
        'Provide a reviewed WalletSecretStore implementation for web builds.',
      );
    }
  }
}

// ======================================================
//
//
