class WalletException implements Exception {
  const WalletException(this.message);

  final String message;

  @override
  String toString() => message;
}
