class SolanaDerivation {
  const SolanaDerivation._({
    required this.accountIndex,
    required this.changeIndex,
  });

  static const primary = SolanaDerivation._(accountIndex: 0, changeIndex: 0);

  static const maxHardenedIndex = 0x7fffffff;

  final int accountIndex;
  final int changeIndex;

  factory SolanaDerivation({int accountIndex = 0, int changeIndex = 0}) {
    if (accountIndex < 0 || accountIndex > maxHardenedIndex) {
      throw ArgumentError.value(
        accountIndex,
        'accountIndex',
        'Account index must be between 0 and $maxHardenedIndex.',
      );
    }

    if (changeIndex < 0 || changeIndex > maxHardenedIndex) {
      throw ArgumentError.value(
        changeIndex,
        'changeIndex',
        'Change index must be between 0 and $maxHardenedIndex.',
      );
    }

    return SolanaDerivation._(
      accountIndex: accountIndex,
      changeIndex: changeIndex,
    );
  }

  String get path {
    return "m/44'/501'/$accountIndex'/$changeIndex'";
  }

  static SolanaDerivation? tryParse(String? value) {
    //

    if (value == null) return null;

    final match = RegExp(r"^m/44'/501'/([0-9]+)'/([0-9]+)'$").firstMatch(value.trim());

    if (match == null) return null;

    final accountIndex = int.tryParse(match.group(1)!);
    final changeIndex = int.tryParse(match.group(2)!);

    if (accountIndex == null || changeIndex == null) return null;

    if (accountIndex > maxHardenedIndex || changeIndex > maxHardenedIndex) {
      return null;
    }

    return SolanaDerivation(
      accountIndex: accountIndex,
      changeIndex: changeIndex,
    );
  }
}
