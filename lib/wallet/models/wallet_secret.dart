//

import 'wallet_info.dart';

class WalletSecret {
  const WalletSecret({
    required this.info,
    required this.privateKeyBase58,
  });

  final WalletInfo info;
  final String privateKeyBase58;

  String get address => info.address;
  String get rootId => info.rootId;
  String? get derivationPath => info.derivationPath;
}
