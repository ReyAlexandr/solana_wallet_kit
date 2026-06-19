import 'package:solana/solana.dart' as solana;

class SolanaWalletValidator {
  const SolanaWalletValidator._();

  static String normalizeAddress(String value) {
    return value.trim();
  }

  static bool isValidAddress(String value) {
    final address = normalizeAddress(value);

    if (address.isEmpty) return false;

    return solana.isValidAddress(address);
  }

  static String? addressError(String? value) {
    final address = normalizeAddress(value ?? '');

    if (address.isEmpty) return "Wallet address is required";

    if (!isValidAddress(address)) return 'Enter a valid solana wallet address';

    return null;
  }
}
