import 'dart:async';

import 'package:flutter/material.dart';

import '../models/solana_derivation.dart';
import '../models/wallet_exception.dart';
import '../models/wallet_info.dart';
import '../services/wallet_registry_service.dart';
import '../widgets/wallet_sensitive_content.dart';

typedef WalletSelectedCallback =
    FutureOr<void> Function(
      WalletInfo walletInfo,
    );

class AddSolanaAddressScreen extends StatefulWidget {
  const AddSolanaAddressScreen({
    super.key,
    required this.selectedAddress,
    required this.onWalletSelected,
    this.changeIndex = 0,
    this.title = 'Wallet addresses',
    this.walletService,
    this.protectSensitiveContent = true,
  }) : assert(changeIndex >= 0);

  final String selectedAddress;
  final WalletSelectedCallback onWalletSelected;
  final int changeIndex;
  final String title;
  final WalletRegistryService? walletService;
  final bool protectSensitiveContent;

  @override
  State<AddSolanaAddressScreen> createState() => _AddSolanaAddressScreenState();
}

class _AddSolanaAddressScreenState extends State<AddSolanaAddressScreen> {
  late final WalletRegistryService _walletService;
  late Future<_WalletAddressListData> _walletsFuture;

  String? _selectedAddress;
  String? _errorMessage;
  bool _isAdding = false;
  bool _isSelecting = false;

  @override
  void initState() {
    super.initState();
    _walletService = widget.walletService ?? const WalletRegistryService();
    _selectedAddress = widget.selectedAddress;
    _walletsFuture = _readWallets();
  }

  @override
  void didUpdateWidget(covariant AddSolanaAddressScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedAddress != widget.selectedAddress) {
      _selectedAddress = widget.selectedAddress;
      _walletsFuture = _readWallets();
    }
  }

  Future<_WalletAddressListData> _readWallets() async {
    final selectedWallet = await _walletService.readWalletInfo(
      address: widget.selectedAddress,
    );
    if (selectedWallet == null) {
      throw const WalletException('Wallet is not available on this device.');
    }

    final wallets = await _walletService.readWalletInfos(
      rootId: selectedWallet.rootId,
    );
    final selectedWalletIsListed = wallets.any(
      (wallet) => wallet.address == selectedWallet.address,
    );

    return _WalletAddressListData(
      selectedWallet: selectedWallet,
      wallets: selectedWalletIsListed ? wallets : [selectedWallet, ...wallets],
    );
  }

  Future<void> _refreshWallets() async {
    setState(() {
      _walletsFuture = _readWallets();
    });
  }

  Future<void> _selectWallet(WalletInfo wallet) async {
    if (_isAdding || _isSelecting) return;

    setState(() {
      _isSelecting = true;
      _selectedAddress = wallet.address;
      _errorMessage = null;
    });

    try {
      await widget.onWalletSelected(wallet);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'The wallet was selected, but the app could not finish setup.';
      });
    } finally {
      if (mounted) setState(() => _isSelecting = false);
    }
  }

  Future<void> _addWallet(_WalletAddressListData data) async {
    if (_isAdding || _isSelecting) return;

    final source = _sourceWallet(data);
    final accountIndex = _nextAccountIndex(data.wallets, data.rootId);
    if (accountIndex > SolanaDerivation.maxHardenedIndex) {
      setState(() {
        _errorMessage = 'No more account indexes are available for this wallet.';
      });
      return;
    }

    setState(() {
      _isAdding = true;
      _errorMessage = null;
    });

    late final WalletInfo walletInfo;
    try {
      walletInfo = await _walletService.deriveAndSaveSolanaAddress(
        sourceAddress: source.address,
        accountIndex: accountIndex,
        changeIndex: widget.changeIndex,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _messageFor(
          error,
          'Could not add this address.',
        );
      });
      setState(() => _isAdding = false);
      return;
    }

    if (!mounted) return;
    setState(() {
      _selectedAddress = walletInfo.address;
      _walletsFuture = _readWallets();
    });

    try {
      await widget.onWalletSelected(walletInfo);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'The address was saved, but the app could not finish setup.';
      });
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  WalletInfo _sourceWallet(_WalletAddressListData data) {
    final selectedAddress = _selectedAddress;
    if (selectedAddress != null) {
      for (final wallet in data.wallets) {
        if (wallet.address == selectedAddress) return wallet;
      }
    }

    return data.selectedWallet;
  }

  int _nextAccountIndex(List<WalletInfo> wallets, String rootId) {
    var nextIndex = 0;

    for (final wallet in wallets) {
      if (wallet.rootId != rootId) continue;

      final derivation = SolanaDerivation.tryParse(wallet.derivationPath);
      if (derivation == null || derivation.changeIndex != widget.changeIndex) {
        continue;
      }

      if (derivation.accountIndex >= nextIndex) {
        nextIndex = derivation.accountIndex + 1;
      }
    }

    return nextIndex;
  }

  static String _messageFor(Object error, String fallback) {
    return error is WalletException ? error.message : fallback;
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
              constraints: const BoxConstraints(maxWidth: 720),
              child: FutureBuilder<_WalletAddressListData>(
                future: _walletsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return _MessageState(
                      message: _messageFor(snapshot.error!, 'Could not load wallets.'),
                    );
                  }

                  final data = snapshot.data!;
                  final wallets = data.wallets;

                  return RefreshIndicator(
                    onRefresh: _refreshWallets,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (wallets.isEmpty)
                          const _MessageTile(
                            message: 'No saved wallet addresses are available on this device.',
                          )
                        else
                          for (final wallet in wallets) ...[
                            _WalletAddressTile(
                              wallet: wallet,
                              selected: wallet.address == _selectedAddress,
                              busy: _isAdding || _isSelecting,
                              onTap: () => _selectWallet(wallet),
                            ),
                            const SizedBox(height: 8),
                          ],
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          key: const ValueKey('walletAddAddressButton'),
                          onPressed: _isAdding || _isSelecting ? null : () => _addWallet(data),
                          icon: _isAdding
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.add),
                          label: const Text('Add address'),
                        ),
                      ],
                    ),
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

class _WalletAddressListData {
  const _WalletAddressListData({
    required this.selectedWallet,
    required this.wallets,
  });

  final WalletInfo selectedWallet;
  final List<WalletInfo> wallets;

  String get rootId => selectedWallet.rootId;
}

class _WalletAddressTile extends StatelessWidget {
  const _WalletAddressTile({
    required this.wallet,
    required this.selected,
    required this.busy,
    required this.onTap,
  });

  final WalletInfo wallet;
  final bool selected;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: selected ? theme.colorScheme.primaryContainer : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: busy ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.account_balance_wallet_outlined,
                color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wallet.label,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      wallet.address,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                    if (wallet.derivationPath != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        wallet.derivationPath!,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageTile extends StatelessWidget {
  const _MessageTile({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge,
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
