//
//
// ======================================================

import '../models/wallet_secret.dart';

// ======================================================
//
//

abstract class WalletSecretStore {
  //

  Future<void> saveWalletSecret(
    WalletSecret wallet, //
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
