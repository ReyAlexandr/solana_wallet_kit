import '../models/mnemonic_secret.dart';
import '../models/wallet_info.dart';
import '../models/wallet_material.dart';
import '../models/wallet_secret.dart';

abstract class WalletStore {
  Future<void> saveWalletMaterial(WalletMaterial material);

  Future<void> saveWalletInfo(WalletInfo info);

  Future<void> saveWalletAddresses({
    required String rootId,
    required List<String> addresses,
  });

  Future<void> addWalletAddress({
    required String rootId,
    required String address,
  });

  Future<void> saveWalletSecret(WalletSecret secret);

  Future<void> saveMnemonicSecret(MnemonicSecret secret);

  Future<List<WalletInfo>> readWalletInfos({required String rootId});

  Future<WalletInfo?> readWalletInfo({required String address});

  Future<WalletSecret?> readWalletSecret({required String address});

  Future<MnemonicSecret?> readMnemonicSecret({required String rootId});

  Future<void> deleteWallet({required String address});

  Future<void> deleteMnemonicSecret({required String rootId});
}
