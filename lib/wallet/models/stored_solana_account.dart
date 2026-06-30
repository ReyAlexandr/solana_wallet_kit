class StoredSolanaAccount {
  const StoredSolanaAccount({
    required this.address,
    required this.rootId,
    required this.derivationPath,
    required this.source,
  });

  final String address;
  final String rootId; // primary derived Solana address
  final String derivationPath;
  final String source;
}
