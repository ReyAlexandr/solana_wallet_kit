//

class WalletInfo {
  const WalletInfo({
    required this.chain,
    required this.address,
    required this.rootId,
    required this.label,
    required this.source,
    this.derivationPath,
  });

  static const solanaChain = 'solana';
  static const createdInAppSource = 'created_in_app';
  static const importedMnemonicSource = 'imported_mnemonic';
  static const importedPrivateKeySource = 'imported_private_key';

  final String chain;
  final String address;
  final String rootId;
  final String label;
  final String source;
  final String? derivationPath;

  factory WalletInfo.solana({
    required String address,
    required String rootId,
    String label = 'Main Wallet',
    String source = createdInAppSource,
    String? derivationPath,
  }) {
    return WalletInfo(
      chain: solanaChain,
      address: address,
      rootId: rootId,
      label: label,
      source: source,
      derivationPath: derivationPath,
    );
  }

  factory WalletInfo.fromJson(Map<String, dynamic> json) {
    final chain = json['chain'];
    final address = json['address'];
    final rootId = json['root_id'];
    final label = json['label'];
    final source = json['source'];
    final derivationPath = json['derivation_path'];

    if (chain is! String ||
        address is! String ||
        rootId is! String ||
        label is! String ||
        source is! String ||
        (derivationPath != null && derivationPath is! String)) {
      throw const FormatException('Invalid wallet info.');
    }

    return WalletInfo(
      chain: chain,
      address: address,
      rootId: rootId,
      label: label,
      source: source,
      derivationPath: derivationPath,
    );
  }

  Map<String, dynamic> toJson() => {
    'chain': chain,
    'address': address,
    'root_id': rootId,
    'label': label,
    'source': source,

    if (derivationPath != null) //
      'derivation_path': derivationPath,
  };

  //
}
