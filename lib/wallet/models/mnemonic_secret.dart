class MnemonicSecret {
  MnemonicSecret({
    required this.rootId,
    required List<String> mnemonic,
  }) : mnemonic = List.unmodifiable(mnemonic);

  final String rootId;
  final List<String> mnemonic;

  String get mnemonicPhrase => mnemonic.join(' ');
}
