import 'dart:async';

import 'package:flutter/material.dart';

import '../models/wallet_info.dart';
import '../models/wallet_ui_text.dart';
import '../services/wallet_backup_gateway.dart';
import '../services/wallet_registry_service.dart';
import 'create_solana_wallet_screen.dart';
import 'restore_solana_wallet_screen.dart';

typedef WalletReadyCallback = FutureOr<void> Function(WalletInfo walletInfo);

class WalletSetupScreen extends StatelessWidget {
  const WalletSetupScreen({
    super.key,
    required this.onWalletReady,
    this.text = const WalletUiText(),
    this.walletService,
    this.backupGateway,
    this.protectSensitiveContent = true,
  });

  final WalletReadyCallback onWalletReady;
  final WalletUiText text;
  final WalletRegistryService? walletService;
  final WalletBackupGateway? backupGateway;
  final bool protectSensitiveContent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(text.setupTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    text.setupMessage,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    key: const ValueKey('walletSetupCreate'),
                    onPressed: () => _openCreate(context),
                    icon: const Icon(Icons.add),
                    label: Text(text.createAction),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    key: const ValueKey('walletSetupRestore'),
                    onPressed: () => _openRestore(context),
                    icon: const Icon(Icons.restore),
                    label: Text(text.restoreAction),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openCreate(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CreateSolanaWalletScreen(
          onContinue: onWalletReady,
          text: text,
          walletService: walletService,
          backupGateway: backupGateway,
          protectSensitiveContent: protectSensitiveContent,
        ),
      ),
    );
  }

  Future<void> _openRestore(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => RestoreSolanaWalletScreen(
          onContinue: onWalletReady,
          text: text,
          walletService: walletService,
          backupGateway: backupGateway,
          protectSensitiveContent: protectSensitiveContent,
        ),
      ),
    );
  }
}
