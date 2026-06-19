//
//
// ======================================================

import '../models/created_solana_wallet.dart';

// ======================================================
//
//

abstract class WalletSecretStore {
  //

  Future<void> saveCreatedSolanaWallet(
    CreatedSolanaWallet wallet, //
  );

  Future<List<String>?> readSolanaMnemonic({
    required String address, //
  });

  Future<void> deleteSolanaMnemonic({
    required String address, //
  });
}

// ======================================================
//
//
