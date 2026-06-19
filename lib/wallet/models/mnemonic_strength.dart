enum MnemonicStrength {
  words12(bits: 128, wordCount: 12),
  words15(bits: 160, wordCount: 15),
  words18(bits: 192, wordCount: 18),
  words21(bits: 224, wordCount: 21),
  words24(bits: 256, wordCount: 24);

  const MnemonicStrength({required this.bits, required this.wordCount});

  final int bits;
  final int wordCount;

  String get label => '$wordCount words';
}
