import 'package:flutter/material.dart';

import '../models/wallet_exception.dart';
import '../models/wallet_material.dart';
import '../services/wallet_clipboard_service.dart';
import '../services/wallet_registry_service.dart';
import '../widgets/mnemonic_grid.dart';
import '../widgets/wallet_security_notice.dart';
import '../widgets/wallet_sensitive_content.dart';

class WalletSecretsScreen extends StatefulWidget {
  const WalletSecretsScreen({
    super.key,
    required this.address,
    this.title = 'Wallet secrets',
    this.securityMessage =
        'Only view this in private. Anyone with your recovery phrase or private key can control this wallet.',
    this.phraseColumns = 2,
    this.walletService,
    this.clipboardService,
    this.protectSensitiveContent = true,
  }) : assert(phraseColumns > 0);

  final String address;
  final String title;
  final String securityMessage;
  final int phraseColumns;
  final WalletRegistryService? walletService;
  final WalletClipboardService? clipboardService;
  final bool protectSensitiveContent;

  @override
  State<WalletSecretsScreen> createState() => _WalletSecretsScreenState();
}

class _WalletSecretsScreenState extends State<WalletSecretsScreen> {
  late final WalletRegistryService _walletService;
  late final WalletClipboardService _clipboardService;
  late Future<WalletMaterial?> _walletFuture;

  @override
  void initState() {
    super.initState();
    _walletService = widget.walletService ?? const WalletRegistryService();
    _clipboardService = widget.clipboardService ?? const WalletClipboardService();
    _walletFuture = _readWallet();
  }

  @override
  void didUpdateWidget(covariant WalletSecretsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.address != widget.address) {
      _walletFuture = _readWallet();
    }
  }

  Future<WalletMaterial?> _readWallet() {
    return _walletService.readWalletMaterial(address: widget.address);
  }

  Future<void> _copyAddress(WalletMaterial wallet) async {
    try {
      await _clipboardService.copyAddress(wallet.address);
      if (!mounted) return;
      _showMessage('Wallet address copied');
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not copy the wallet address.');
    }
  }

  Future<void> _copyPrivateKey(WalletMaterial wallet) async {
    try {
      await _clipboardService.copyPrivateKey(wallet.privateKeyBase58);
      if (!mounted) return;
      _showMessage('Private key copied for 1 minute');
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not copy the private key.');
    }
  }

  Future<void> _copyPhrase(WalletMaterial wallet) async {
    final phrase = wallet.mnemonicPhrase;
    if (phrase == null || phrase.isEmpty) {
      _showMessage('Recovery phrase is not available on this device.');
      return;
    }

    try {
      await _clipboardService.copyPhrase(phrase);
      if (!mounted) return;
      _showMessage('Recovery phrase copied for 1 minute');
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not copy the recovery phrase.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  static String _messageFor(Object error) {
    return error is WalletException ? error.message : 'Could not load wallet secrets.';
  }

  @override
  Widget build(BuildContext context) {
    return WalletSensitiveContent(
      enabled: widget.protectSensitiveContent,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 840),
              child: FutureBuilder<WalletMaterial?>(
                future: _walletFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return _MessageState(message: _messageFor(snapshot.error!));
                  }

                  final wallet = snapshot.data;
                  if (wallet == null) {
                    return const _MessageState(
                      message: 'Wallet secrets are not available on this device.',
                    );
                  }

                  return _WalletSecretsContent(
                    wallet: wallet,
                    securityMessage: widget.securityMessage,
                    phraseColumns: widget.phraseColumns,
                    onCopyAddress: () => _copyAddress(wallet),
                    onCopyPrivateKey: () => _copyPrivateKey(wallet),
                    onCopyPhrase: () => _copyPhrase(wallet),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WalletSecretsContent extends StatelessWidget {
  const _WalletSecretsContent({
    required this.wallet,
    required this.securityMessage,
    required this.phraseColumns,
    required this.onCopyAddress,
    required this.onCopyPrivateKey,
    required this.onCopyPhrase,
  });

  final WalletMaterial wallet;
  final String securityMessage;
  final int phraseColumns;
  final VoidCallback onCopyAddress;
  final VoidCallback onCopyPrivateKey;
  final VoidCallback onCopyPhrase;

  @override
  Widget build(BuildContext context) {
    final mnemonic = wallet.mnemonic;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        WalletSecurityNotice(message: securityMessage),
        const SizedBox(height: 20),
        _SecretSection(
          title: 'Wallet address',
          copyTooltip: 'Copy wallet address',
          onCopy: onCopyAddress,
          child: SelectableText(
            wallet.address,
            key: const ValueKey('walletSecretsAddress'),
          ),
        ),
        const SizedBox(height: 16),
        _SecretSection(
          title: 'Private key',
          copyTooltip: 'Copy private key',
          onCopy: onCopyPrivateKey,
          child: SelectableText(
            wallet.privateKeyBase58,
            key: const ValueKey('walletSecretsPrivateKey'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(height: 16),
        _SecretSection(
          title: 'Recovery phrase',
          copyTooltip: 'Copy recovery phrase',
          onCopy: mnemonic == null || mnemonic.isEmpty ? null : onCopyPhrase,
          child: mnemonic == null || mnemonic.isEmpty
              ? const Text('Recovery phrase is not available on this device.')
              : MnemonicGrid(
                  key: const ValueKey('walletSecretsMnemonic'),
                  words: mnemonic,
                  columns: phraseColumns,
                ),
        ),
      ],
    );
  }
}

class _SecretSection extends StatelessWidget {
  const _SecretSection({
    required this.title,
    required this.copyTooltip,
    required this.onCopy,
    required this.child,
  });

  final String title;
  final String copyTooltip;
  final VoidCallback? onCopy;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                Tooltip(
                  message: copyTooltip,
                  child: IconButton(
                    onPressed: onCopy,
                    icon: const Icon(Icons.copy_outlined),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
