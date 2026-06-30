import 'dart:convert';

import 'package:bip39/bip39.dart' as bip39;

import '../models/wallet_secret.dart';
import '../models/solana_derivation.dart';
import '../models/wallet_exception.dart';
import '../models/wallet_phrase_file.dart';
import '../solana/solana_wallet_validator.dart';

class WalletPhraseExportService {
  const WalletPhraseExportService();

  static const formatVersion = 1;
  static const formatId = 'solana-wallet-backup';

  WalletPhraseFile createFile(
    WalletSecret wallet, {
    String? fileName,
  }) {
    final account = wallet.info;
    if (!bip39.validateMnemonic(wallet.mnemonicPhrase) ||
        !SolanaWalletValidator.isValidAddress(account.address) ||
        SolanaDerivation.tryParse(account.derivationPath) == null) {
      throw const WalletException('Wallet data is not valid for export.');
    }

    final contents = const JsonEncoder.withIndent('  ').convert({
      'format': formatId,
      'version': formatVersion,
      'chain': account.chain,
      'encrypted': false,
      'warning': 'Anyone with this file can control this wallet.',
      'mnemonic': wallet.mnemonicPhrase,
      'address': account.address,
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
