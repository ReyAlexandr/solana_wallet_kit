//

import 'wallet_account.dart';

class CreatedSolanaWallet {
  CreatedSolanaWallet({
    required this.account,
    required List<String> mnemonic,
  }) : mnemonic = List.unmodifiable(mnemonic);

  final WalletAccount account;
  final List<String> mnemonic;

  String get mnemonicPhrase => mnemonic.join(' ');
  String get address => account.address;
  String? get derivationPath => account.derivationPath;
}
