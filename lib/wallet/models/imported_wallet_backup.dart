import 'solana_derivation.dart';

class ImportedWalletBackup {
  const ImportedWalletBackup({
    required this.mnemonicPhrase,
    required this.address,
    required this.derivation,
  });

  final String mnemonicPhrase;
  final String address;
  final SolanaDerivation derivation;
}
