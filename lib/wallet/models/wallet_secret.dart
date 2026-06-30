//

import 'wallet_info.dart';

class WalletSecret {
  WalletSecret({
    // required this.rootId,
    required this.info,
    required List<String> mnemonic,
  }) : mnemonic = List.unmodifiable(mnemonic);

  // final String rootId;
  final WalletInfo info;
  final List<String> mnemonic;

  String get mnemonicPhrase => mnemonic.join(' ');
  String get address => info.address;
  String? get derivationPath => info.derivationPath;
}
