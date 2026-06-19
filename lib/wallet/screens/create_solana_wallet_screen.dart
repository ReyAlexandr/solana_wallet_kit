import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/created_solana_wallet.dart';
import '../models/mnemonic_strength.dart';
import '../models/wallet_account.dart';
import '../models/wallet_exception.dart';
import '../models/wallet_phrase_file.dart';
import '../models/wallet_ui_text.dart';
import '../services/wallet_backup_gateway.dart';
import '../services/wallet_clipboard_service.dart';
import '../services/wallet_phrase_export_service.dart';
import '../services/wallet_registry_service.dart';
import '../widgets/mnemonic_grid.dart';
import '../widgets/mnemonic_strength_selector.dart';
import '../widgets/wallet_security_notice.dart';
import '../widgets/wallet_sensitive_content.dart';

typedef WalletCreatedCallback =
    FutureOr<void> Function(
      WalletAccount account,
    );
typedef WalletDownloadCallback =
    FutureOr<void> Function(
      WalletPhraseFile file,
    );

class CreateSolanaWalletScreen extends StatefulWidget {
  const CreateSolanaWalletScreen({
    super.key,
    required this.onContinue,
    this.onDownloadRequested,
    this.phraseColumns = 2,
    this.strengthOptions = MnemonicStrength.values,
    this.initialStrength = MnemonicStrength.words12,
    this.title,
    this.text = const WalletUiText(),
    this.securityMessage,
    this.walletService,
    this.clipboardService,
    this.exportService,
    this.backupGateway,
    this.requireBackupConfirmation = true,
    this.protectSensitiveContent = true,
  }) : assert(phraseColumns > 0),
       assert(strengthOptions.length > 0);

  final WalletCreatedCallback onContinue;
  final WalletDownloadCallback? onDownloadRequested;
  final int phraseColumns;
  final List<MnemonicStrength> strengthOptions;
  final MnemonicStrength initialStrength;
  final String? title;
  final WalletUiText text;
  final String? securityMessage;
  final WalletRegistryService? walletService;
  final WalletClipboardService? clipboardService;
  final WalletPhraseExportService? exportService;
  final WalletBackupGateway? backupGateway;
  final bool requireBackupConfirmation;
  final bool protectSensitiveContent;

  @override
  State<CreateSolanaWalletScreen> createState() => _CreateSolanaWalletScreenState();
}

class _CreateSolanaWalletScreenState extends State<CreateSolanaWalletScreen> {
  late final WalletRegistryService _walletService;
  late final WalletClipboardService _clipboardService;
  late final WalletPhraseExportService _exportService;
  late final WalletBackupGateway _backupGateway;
  late MnemonicStrength _strength;

  CreatedSolanaWallet? _wallet;
  String? _errorMessage;
  bool _isGenerating = false;
  bool _isContinuing = false;
  int _generationId = 0;

  @override
  void initState() {
    super.initState();
    _walletService = widget.walletService ?? const WalletRegistryService();
    _clipboardService = widget.clipboardService ?? const WalletClipboardService();
    _exportService = widget.exportService ?? const WalletPhraseExportService();
    _backupGateway = widget.backupGateway ?? const DefaultWalletBackupGateway();
    _strength = widget.strengthOptions.contains(widget.initialStrength)
        ? widget.initialStrength
        : widget.strengthOptions.first;
    _generateWallet();
  }

  Future<void> _generateWallet() async {
    final generationId = ++_generationId;
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _wallet = null;
    });

    try {
      final wallet = await _walletService.createSolanaWalletForBackup(
        mnemonicStrength: _strength,
      );

      if (!mounted || generationId != _generationId) return;
      setState(() => _wallet = wallet);
    } catch (error) {
      if (!mounted || generationId != _generationId) return;
      setState(() {
        _errorMessage = _messageFor(
          error,
          'Could not create a wallet. Please try again.',
        );
      });
    } finally {
      if (mounted && generationId == _generationId) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _changeStrength(MnemonicStrength strength) async {
    if (_strength == strength) return;
    setState(() => _strength = strength);
    await _generateWallet();
  }

  Future<void> _copyPhrase() async {
    final wallet = _wallet;
    if (wallet == null) return;

    try {
      await _clipboardService.copyPhrase(wallet.mnemonicPhrase);
      if (!mounted) return;
      _showMessage(widget.text.phraseCopiedMessage);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Could not copy the recovery phrase.');
    }
  }

  Future<void> _copyAddress() async {
    final wallet = _wallet;
    if (wallet == null) return;

    try {
      await _clipboardService.copyAddress(wallet.address);
      if (!mounted) return;
      _showMessage(widget.text.addressCopiedMessage);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Could not copy the wallet address.');
    }
  }

  Future<void> _downloadPhrase() async {
    final wallet = _wallet;
    final callback = widget.onDownloadRequested;
    if (wallet == null) return;

    try {
      final confirmed = await _confirmPlaintextExport();
      if (!confirmed) return;
      final file = _exportService.createFile(wallet);
      final saved = callback != null
          ? await _exportWithCallback(callback, file)
          : await _backupGateway.exportBackup(file);
      if (saved && mounted) {
        _showMessage(widget.text.backupSavedMessage);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _messageFor(
          error,
          'Could not export the recovery phrase.',
        );
      });
    }
  }

  static Future<bool> _exportWithCallback(
    WalletDownloadCallback callback,
    WalletPhraseFile file,
  ) async {
    await callback(file);
    return true;
  }

  Future<void> _continue() async {
    final wallet = _wallet;
    if (wallet == null || _isContinuing) return;

    if (widget.requireBackupConfirmation) {
      final confirmed = await _confirmRecoveryPhrase(wallet);
      if (!confirmed || !mounted) return;
    }

    setState(() {
      _isContinuing = true;
      _errorMessage = null;
    });

    try {
      await _walletService.saveBackedUpSolanaWallet(wallet);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _messageFor(
          error,
          'Could not securely save the wallet.',
        );
      });
      setState(() => _isContinuing = false);
      return;
    }

    try {
      await widget.onContinue(wallet.account);
      if (mounted) setState(() => _wallet = null);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = widget.text.hostCompletionError;
      });
    } finally {
      if (mounted) setState(() => _isContinuing = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _confirmPlaintextExport() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Download unencrypted backup?'),
              content: const Text(
                'The JSON file contains your recovery phrase in plain text. '
                'Anyone who gets the file can control this wallet.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Download'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<bool> _confirmRecoveryPhrase(CreatedSolanaWallet wallet) async {
    final indexes = List.generate(wallet.mnemonic.length, (index) => index)
      ..shuffle(Random.secure());
    final selected = indexes.take(2).toList()..sort();
    final controllers = [
      TextEditingController(),
      TextEditingController(),
    ];

    try {
      return await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              var showError = false;

              return StatefulBuilder(
                builder: (context, setDialogState) {
                  return AlertDialog(
                    title: const Text('Confirm your recovery phrase'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Enter the requested words from your written backup.',
                        ),
                        const SizedBox(height: 16),
                        for (var index = 0; index < selected.length; index++) ...[
                          TextField(
                            controller: controllers[index],
                            autocorrect: false,
                            enableSuggestions: false,
                            enableIMEPersonalizedLearning: false,
                            smartDashesType: SmartDashesType.disabled,
                            smartQuotesType: SmartQuotesType.disabled,
                            keyboardType: TextInputType.visiblePassword,
                            decoration: InputDecoration(
                              labelText: 'Word ${selected[index] + 1}',
                            ),
                          ),
                          if (index != selected.length - 1) const SizedBox(height: 12),
                        ],
                        if (showError) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Those words do not match.',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () {
                          final matches = List.generate(
                            selected.length,
                            (index) =>
                                controllers[index].text.trim().toLowerCase() ==
                                wallet.mnemonic[selected[index]],
                          ).every((value) => value);

                          if (matches) {
                            Navigator.of(context).pop(true);
                          } else {
                            setDialogState(() => showError = true);
                          }
                        },
                        child: const Text('Confirm'),
                      ),
                    ],
                  );
                },
              );
            },
          ) ??
          false;
    } finally {
      for (final controller in controllers) {
        controller.clear();
        controller.dispose();
      }
    }
  }

  static String _messageFor(Object error, String fallback) {
    return error is WalletException ? error.message : fallback;
  }

  @override
  Widget build(BuildContext context) {
    final wallet = _wallet;
    final busy = _isGenerating || _isContinuing;

    return WalletSensitiveContent(
      enabled: widget.protectSensitiveContent,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.title ?? widget.text.createTitle)),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 840),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  WalletSecurityNotice(
                    message: widget.securityMessage ?? widget.text.securityMessage,
                  ),
                  const SizedBox(height: 20),
                  if (wallet != null) ...[
                    Row(
                      children: [
                        Text(
                          widget.text.walletAddressLabel,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(width: 4),
                        Tooltip(
                          message: widget.text.copyAddressTooltip,
                          child: IconButton(
                            onPressed: busy ? null : _copyAddress,
                            iconSize: 18,
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            padding: const EdgeInsets.all(6),
                            icon: const Icon(Icons.copy_outlined),
                          ),
                        ),
                      ],
                    ),
                    SelectableText(wallet.address),
                    const SizedBox(height: 20),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.text.recoveryPhraseLengthLabel,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      Tooltip(
                        message: widget.text.copyPhraseTooltip,
                        child: IconButton(
                          onPressed: wallet == null || busy ? null : _copyPhrase,
                          icon: const Icon(Icons.copy_outlined),
                        ),
                      ),
                      Tooltip(
                        message: widget.text.downloadPhraseTooltip,
                        child: IconButton(
                          onPressed: wallet == null || busy ? null : _downloadPhrase,
                          icon: const Icon(Icons.download_outlined),
                        ),
                      ),
                      Tooltip(
                        message: widget.text.generatePhraseTooltip,
                        child: IconButton(
                          onPressed: busy ? null : _generateWallet,
                          icon: const Icon(Icons.refresh),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: MnemonicStrengthSelector(
                      value: _strength,
                      options: widget.strengthOptions,
                      onChanged: busy ? (_) {} : _changeStrength,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_isGenerating)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (wallet != null) ...[
                    MnemonicGrid(
                      words: wallet.mnemonic,
                      columns: widget.phraseColumns,
                    ),
                  ],
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const ValueKey('walletCreateContinue'),
                    onPressed: wallet == null || busy ? null : _continue,
                    child: _isContinuing
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(widget.text.continueAction),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
