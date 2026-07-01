import 'mnemonic_secret.dart';
import 'wallet_info.dart';
import 'wallet_secret.dart';

class WalletMaterial {
  const WalletMaterial({
    required this.info,
    required this.secret,
    this.mnemonicSecret,
  });

  final WalletInfo info;
  final WalletSecret secret;
  final MnemonicSecret? mnemonicSecret;

  String get address => info.address;
  String get rootId => info.rootId;
  String? get derivationPath => info.derivationPath;
  String get privateKeyBase58 => secret.privateKeyBase58;
  List<String>? get mnemonic => mnemonicSecret?.mnemonic;
  String? get mnemonicPhrase => mnemonicSecret?.mnemonicPhrase;
}
