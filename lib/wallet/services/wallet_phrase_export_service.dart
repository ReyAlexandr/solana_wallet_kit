import 'dart:convert';

import 'package:bip39/bip39.dart' as bip39;

import '../models/solana_derivation.dart';
import '../models/wallet_exception.dart';
import '../models/wallet_material.dart';
import '../models/wallet_phrase_file.dart';
import '../solana/solana_wallet_validator.dart';

class WalletPhraseExportService {
  const WalletPhraseExportService();

  static const formatVersion = 2;
  static const formatId = 'solana-wallet-backup';

  WalletPhraseFile createFile(
    WalletMaterial material, {
    String? fileName,
  }) {
    final account = material.info;
    final mnemonicSecret = material.mnemonicSecret;
    final mnemonicPhrase = mnemonicSecret?.mnemonicPhrase ?? '';
    final privateKey = material.secret.privateKeyBase58.trim();

    if (mnemonicSecret == null ||
        mnemonicSecret.rootId != account.rootId ||
        !bip39.validateMnemonic(mnemonicPhrase) ||
        !SolanaWalletValidator.isValidAddress(account.address) ||
        !SolanaWalletValidator.isValidAddress(account.rootId) ||
        privateKey.isEmpty ||
        SolanaDerivation.tryParse(account.derivationPath) == null) {
      throw const WalletException('Wallet data is not valid for export.');
    }

    final contents = const JsonEncoder.withIndent('  ').convert({
      'format': formatId,
      'version': formatVersion,
      'chain': account.chain,
      'encrypted': false,
      'warning': 'Anyone with this file can control this wallet.',
      'mnemonic': mnemonicPhrase,
      'private_key': privateKey,
      'private_key_encoding': 'base58',
      'address': account.address,
      'root_id': account.rootId,
      if (account.derivationPath != null) 'derivation_path': account.derivationPath,
    });

    return WalletPhraseFile(
      fileName: fileName ?? _defaultFileName(account.address),
      contents: contents,
    );
  }

  static String _defaultFileName(String address) {
    final suffix = address.length <= 8 ? address : address.substring(0, 8);

    return 'solana-wallet-$suffix.json';
  }
}
