//

class WalletAccount {
  const WalletAccount({
    required this.chain,
    required this.address,
    required this.label,
    required this.source,
    this.derivationPath,
  });

  static const solanaChain = 'solana';
  static const createdInAppSource = 'created_in_app';
  static const importedMnemonicSource = 'imported_mnemonic';

  final String chain;
  final String address;
  final String label;
  final String source;
  final String? derivationPath;

  factory WalletAccount.solana({
    required String address,
    String label = 'Main Wallet',
    String source = createdInAppSource,
    String? derivationPath,
  }) {
    return WalletAccount(
      chain: solanaChain,
      address: address,
      label: label,
      source: source,
      derivationPath: derivationPath,
    );
  }

  Map<String, dynamic> toJson() => {
    'chain': chain,
    'address': address,
    'label': label,
    'source': source,

    if (derivationPath != null) //
      'derivation_path': derivationPath,
  };

  //
}
