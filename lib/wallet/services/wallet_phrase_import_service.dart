import 'dart:convert';

import 'package:bip39/bip39.dart' as bip39;

import '../models/imported_wallet_backup.dart';
import '../models/solana_derivation.dart';
import '../models/wallet_exception.dart';
import '../models/wallet_phrase_file.dart';
import '../models/wallet_info.dart';
import '../solana/solana_wallet_creation_service.dart';
import '../solana/solana_wallet_validator.dart';
import 'wallet_phrase_export_service.dart';

class WalletPhraseImportService {
  const WalletPhraseImportService({
    SolanaWalletCreationService? creationService,
  }) : _creationService = creationService ?? const SolanaWalletCreationService();

  final SolanaWalletCreationService _creationService;

  Future<ImportedWalletBackup> readBackup(WalletPhraseFile file) async {
    final contents = file.contents.trim();

    if (contents.isEmpty) {
      throw const WalletException('Wallet backup file is empty.');
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(contents);
    } on FormatException {
      throw const WalletException('Wallet backup file is not valid JSON.');
    }

    if (decoded is! Map) {
      throw const WalletException('Wallet backup file has an invalid format.');
    }

    final data = Map<String, dynamic>.from(decoded);
    final format = data['format'];
    final version = data['version'];
    final chain = data['chain'];
    final mnemonic = _normalizeMnemonic(data['mnemonic']);
    final address = data['address'];
    final rootId = data['root_id'];
    final privateKey = data['private_key'];
    final privateKeyEncoding = data['private_key_encoding'];
    final derivationPath = data['derivation_path'];
    final derivation = derivationPath is String ? SolanaDerivation.tryParse(derivationPath) : null;

    if (format != WalletPhraseExportService.formatId) {
      throw const WalletException('Wallet backup file has an invalid format.');
    }

    if (version != WalletPhraseExportService.formatVersion) {
      throw const WalletException('Unsupported wallet backup version.');
    }

    if (chain != WalletInfo.solanaChain) {
      throw const WalletException('Wallet backup is not for Solana.');
    }

    if (!bip39.validateMnemonic(mnemonic)) {
      throw const WalletException(
        'Wallet backup contains an invalid recovery phrase.',
      );
    }

    if (address is! String ||
        !SolanaWalletValidator.isValidAddress(address) ||
        rootId is! String ||
        !SolanaWalletValidator.isValidAddress(rootId) ||
        privateKey is! String ||
        privateKey.trim().isEmpty ||
        privateKeyEncoding != 'base58' ||
        derivation == null) {
      throw const WalletException('Wallet backup metadata is invalid.');
    }

    final restored = await _creationService.restoreFromMnemonic(
      mnemonic,
      derivation: derivation,
    );
    if (restored.info.address != address ||
        restored.info.rootId != rootId ||
        restored.secret.privateKeyBase58 != privateKey.trim()) {
      throw const WalletException(
        'Wallet backup does not match its recovery phrase.',
      );
    }

    return ImportedWalletBackup(
      mnemonicPhrase: mnemonic,
      address: address,
      rootId: rootId,
      privateKeyBase58: privateKey.trim(),
      derivation: derivation,
    );
  }

  static String _normalizeMnemonic(Object? value) {
    if (value is! String) return '';

    return value.trim().toLowerCase().split(RegExp(r'\s+')).join(' ');
  }
}
