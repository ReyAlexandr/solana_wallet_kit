import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/wallet_exception.dart';
import '../models/wallet_phrase_file.dart';

abstract interface class WalletBackupGateway {
  Future<bool> exportBackup(WalletPhraseFile file);

  Future<WalletPhraseFile?> importBackup();
}

class DefaultWalletBackupGateway implements WalletBackupGateway {
  const DefaultWalletBackupGateway({
    this.channel = const MethodChannel(_channelName),
    this.targetPlatform,
  });

  static const _channelName = 'solana_wallet_kit/backup';
  static const _mimeType = 'application/json';

  final MethodChannel channel;
  final TargetPlatform? targetPlatform;

  TargetPlatform get _platform => targetPlatform ?? defaultTargetPlatform;

  @override
  Future<bool> exportBackup(WalletPhraseFile file) async {
    if (kIsWeb) {
      throw const WalletException(
        'Wallet backup export is not supported on web.',
      );
    }

    if (_platform == TargetPlatform.android) {
      try {
        return await channel.invokeMethod<bool>('exportBackup', {
              'fileName': file.fileName,
              'contents': file.contents,
              'mimeType': _mimeType,
            }) ??
            false;
      } on PlatformException catch (error) {
        throw WalletException(
          error.message ?? 'Could not export the recovery phrase.',
        );
      } on MissingPluginException {
        throw const WalletException(
          'Wallet backup export is unavailable. Rebuild the Android app after '
          'adding solana_wallet_kit.',
        );
      }
    }

    if (_platform == TargetPlatform.linux ||
        _platform == TargetPlatform.macOS ||
        _platform == TargetPlatform.windows) {
      final location = await getSaveLocation(
        suggestedName: file.fileName,
        acceptedTypeGroups: const [_jsonTypeGroup],
      );
      if (location == null) return false;

      final output = XFile.fromData(
        Uint8List.fromList(utf8.encode(file.contents)),
        mimeType: _mimeType,
        name: file.fileName,
      );
      await output.saveTo(location.path);
      return true;
    }

    throw const WalletException(
      'Wallet backup export is currently supported only on Android and desktop.',
    );
  }

  @override
  Future<WalletPhraseFile?> importBackup() async {
    if (kIsWeb) {
      throw const WalletException(
        'Wallet backup import is not supported on web.',
      );
    }

    final file = await openFile(
      acceptedTypeGroups: const [_jsonTypeGroup],
    );
    if (file == null) return null;

    if (!file.name.toLowerCase().endsWith('.json')) {
      throw const WalletException('Select a JSON wallet backup file.');
    }

    return WalletPhraseFile(
      fileName: file.name,
      contents: await file.readAsString(),
    );
  }
}

const _jsonTypeGroup = XTypeGroup(
  label: 'Solana wallet backup',
  extensions: ['json'],
  mimeTypes: ['application/json'],
);
