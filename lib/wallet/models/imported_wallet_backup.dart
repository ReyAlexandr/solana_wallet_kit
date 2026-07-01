import 'solana_derivation.dart';

class ImportedWalletBackup {
  const ImportedWalletBackup({
    required this.mnemonicPhrase,
    required this.address,
    required this.rootId,
    required this.privateKeyBase58,
    required this.derivation,
  });

  final String mnemonicPhrase;
  final String address;
  final String rootId;
  final String privateKeyBase58;
  final SolanaDerivation derivation;
}
