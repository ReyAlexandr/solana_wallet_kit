//
//
// ======================================================

import 'dart:convert';

import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/mnemonic_secret.dart';
import '../models/wallet_info.dart';
import '../models/wallet_material.dart';
import '../models/wallet_secret.dart';
import '../models/wallet_exception.dart';
import '../solana/solana_wallet_validator.dart';
import 'wallet_store.dart';

// ======================================================
//
//

class SecureWalletSecretStore implements WalletStore {
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

  static const _solanaInfoPrefix = 'wallet.solana.info';
  static const _solanaAddressListPrefix = 'wallet.solana.addresses';
  static const _solanaPrivateKeyPrefix = 'wallet.solana.pk';
  static const _solanaMnemonicPrefix = 'wallet.solana.mnemonic';

  final FlutterSecureStorage _storage;

  // ======================================================

  @override
  Future<void> saveWalletMaterial(WalletMaterial material) async {
    await saveWalletInfo(material.info);
    await saveWalletSecret(material.secret);

    final mnemonicSecret = material.mnemonicSecret;
    if (mnemonicSecret != null) {
      await saveMnemonicSecret(mnemonicSecret);
    }
  }

  // ======================================================

  @override
  Future<void> saveWalletInfo(WalletInfo info) async {
    _ensureSupportedPlatform();
    _validateAddress(info.address);
    _validateAddress(info.rootId);

    await _storage.write(
      key: _infoKey(info.address),
      value: jsonEncode(info.toJson()),
    );

    await addWalletAddress(
      rootId: info.rootId,
      address: info.address,
    );
  }

  // ======================================================

  @override
  Future<void> saveWalletAddresses({
    required String rootId,
    required List<String> addresses,
  }) {
    _ensureSupportedPlatform();
    _validateAddress(rootId);

    final normalized = <String>[];
    final seen = <String>{};

    for (final address in addresses) {
      final value = address.trim();
      _validateAddress(value);

      if (seen.add(value)) {
        normalized.add(value);
      }
    }

    return _writeWalletAddresses(
      rootId: rootId,
      addresses: normalized,
    );
  }

  // ======================================================

  @override
  Future<void> addWalletAddress({
    required String rootId,
    required String address,
  }) async {
    _ensureSupportedPlatform();
    _validateAddress(rootId);
    final value = address.trim();
    _validateAddress(value);

    final addresses = await _readWalletAddresses(rootId: rootId);
    if (addresses.contains(value)) return;

    await _writeWalletAddresses(
      rootId: rootId,
      addresses: [...addresses, value],
    );
  }

  // ======================================================

  @override
  Future<void> saveWalletSecret(WalletSecret wallet) {
    _ensureSupportedPlatform();
    _validateAddress(wallet.address);
    if (wallet.privateKeyBase58.trim().isEmpty) {
      throw const WalletException('Refusing to store an empty private key.');
    }

    return _storage.write(
      key: _privateKeyKey(wallet.address),
      value: wallet.privateKeyBase58.trim(),
    );
  }

  // ======================================================

  @override
  Future<void> saveMnemonicSecret(MnemonicSecret secret) {
    _ensureSupportedPlatform();
    _validateAddress(secret.rootId);
    if (!bip39.validateMnemonic(secret.mnemonicPhrase)) {
      throw const WalletException('Refusing to store an invalid recovery phrase.');
    }

    return _storage.write(
      key: _mnemonicKey(secret.rootId),
      value: secret.mnemonicPhrase,
    );
  }

  // ======================================================

  @override
  Future<List<WalletInfo>> readWalletInfos({required String rootId}) async {
    _ensureSupportedPlatform();
    _validateAddress(rootId);

    final infos = <WalletInfo>[];
    final addresses = await _readWalletAddresses(rootId: rootId);

    for (final address in addresses) {
      final info = await readWalletInfo(address: address);
      if (info != null && info.rootId == rootId) {
        infos.add(info);
      }
    }

    return List.unmodifiable(infos);
  }

  // ======================================================

  @override
  Future<WalletInfo?> readWalletInfo({required String address}) async {
    _ensureSupportedPlatform();
    _validateAddress(address);

    final rawInfo = await _storage.read(key: _infoKey(address));
    if (rawInfo == null || rawInfo.trim().isEmpty) return null;

    try {
      final value = jsonDecode(rawInfo);
      if (value is! Map<String, dynamic>) {
        throw const FormatException('Invalid wallet info.');
      }
      return WalletInfo.fromJson(value);
    } on FormatException {
      throw const WalletException('Stored wallet info is corrupted.');
    }
  }

  // ======================================================

  @override
  Future<WalletSecret?> readWalletSecret({required String address}) async {
    _ensureSupportedPlatform();
    _validateAddress(address);

    final info = await readWalletInfo(address: address);
    final privateKey = await _storage.read(key: _privateKeyKey(address));

    if (info == null || privateKey == null || privateKey.trim().isEmpty) {
      return null;
    }

    return WalletSecret(
      info: info,
      privateKeyBase58: privateKey.trim(),
    );
  }

  // ======================================================

  @override
  Future<MnemonicSecret?> readMnemonicSecret({
    required String rootId, //
  }) async {
    _ensureSupportedPlatform();
    _validateAddress(rootId);

    final mnemonicPhrase = await _storage.read(key: _mnemonicKey(rootId));

    if (mnemonicPhrase == null || mnemonicPhrase.trim().isEmpty) {
      return null;
    }

    final normalized = mnemonicPhrase.trim().split(RegExp(r'\s+')).join(' ');
    if (!bip39.validateMnemonic(normalized)) {
      throw const WalletException('Stored recovery phrase is corrupted.');
    }

    return MnemonicSecret(
      rootId: rootId,
      mnemonic: normalized.split(' '),
    );
  }

  // ======================================================

  @override
  Future<void> deleteWallet({required String address}) async {
    _ensureSupportedPlatform();
    final value = address.trim();
    _validateAddress(value);
    final info = await readWalletInfo(address: value);

    await _storage.delete(key: _infoKey(value));
    await _storage.delete(key: _privateKeyKey(value));

    if (info != null) {
      final addresses = await _readWalletAddresses(rootId: info.rootId);
      await _writeWalletAddresses(
        rootId: info.rootId,
        addresses: addresses.where((item) => item != value).toList(),
      );
    }
  }

  // ======================================================

  @override
  Future<void> deleteMnemonicSecret({required String rootId}) {
    _ensureSupportedPlatform();
    _validateAddress(rootId);
    return _storage.delete(key: _mnemonicKey(rootId));
  }

  // ======================================================

  static String _infoKey(String address) {
    return '$_solanaInfoPrefix.$address';
  }

  static String _privateKeyKey(String address) {
    return '$_solanaPrivateKeyPrefix.$address';
  }

  static String _mnemonicKey(String address) {
    return '$_solanaMnemonicPrefix.$address';
  }

  static String _addressListKey(String rootId) {
    return '$_solanaAddressListPrefix.$rootId';
  }

  Future<void> _writeWalletAddresses({
    required String rootId,
    required List<String> addresses,
  }) {
    return _storage.write(
      key: _addressListKey(rootId),
      value: jsonEncode(addresses),
    );
  }

  Future<List<String>> _readWalletAddresses({required String rootId}) async {
    final rawAddresses = await _storage.read(key: _addressListKey(rootId));
    if (rawAddresses == null || rawAddresses.trim().isEmpty) {
      return const [];
    }

    try {
      final value = jsonDecode(rawAddresses);
      if (value is! List) {
        throw const FormatException('Invalid wallet address index.');
      }

      final addresses = <String>[];
      final seen = <String>{};

      for (final item in value) {
        if (item is! String) {
          throw const FormatException('Invalid wallet address index.');
        }

        final address = item.trim();
        _validateAddress(address);

        if (seen.add(address)) {
          addresses.add(address);
        }
      }

      return List.unmodifiable(addresses);
    } on FormatException {
      throw const WalletException('Stored wallet address list is corrupted.');
    }
  }

  static void _validateAddress(String address) {
    if (!SolanaWalletValidator.isValidAddress(address)) {
      throw const WalletException('Invalid Solana wallet address.');
    }
  }

  static void _ensureSupportedPlatform() {
    if (kIsWeb) {
      throw const WalletException(
        'Provide a reviewed WalletStore implementation for web builds.',
      );
    }
  }
}

// ======================================================
//
//
