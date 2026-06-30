import 'dart:async';

import 'package:flutter/material.dart';

import '../models/mnemonic_strength.dart';
import '../models/solana_derivation.dart';
import '../models/wallet_info.dart';
import '../models/wallet_exception.dart';
import '../models/wallet_phrase_file.dart';
import '../models/wallet_ui_text.dart';
import '../services/wallet_backup_gateway.dart';
import '../services/wallet_clipboard_service.dart';
import '../services/wallet_phrase_import_service.dart';
import '../services/wallet_registry_service.dart';
import '../widgets/mnemonic_input_grid.dart';
import '../widgets/mnemonic_strength_selector.dart';
import '../widgets/wallet_sensitive_content.dart';

typedef WalletRestoredCallback =
    FutureOr<void> Function(
      WalletInfo walletInfo,
    );
typedef WalletImportCallback = Future<WalletPhraseFile?> Function();

class RestoreSolanaWalletScreen extends StatefulWidget {
  const RestoreSolanaWalletScreen({
    super.key,
    required this.onContinue,
    this.onImportRequested,
    this.phraseColumns = 2,
    this.strengthOptions = MnemonicStrength.values,
    this.initialStrength = MnemonicStrength.words12,
    this.title,
    this.text = const WalletUiText(),
    this.walletService,
    this.clipboardService,
    this.importService,
    this.backupGateway,
    this.protectSensitiveContent = true,
  }) : assert(phraseColumns > 0),
       assert(strengthOptions.length > 0);

  final WalletRestoredCallback onContinue;
  final WalletImportCallback? onImportRequested;
  final int phraseColumns;
  final List<MnemonicStrength> strengthOptions;
  final MnemonicStrength initialStrength;
  final String? title;
  final WalletUiText text;
  final WalletRegistryService? walletService;
  final WalletClipboardService? clipboardService;
  final WalletPhraseImportService? importService;
  final WalletBackupGateway? backupGateway;
  final bool protectSensitiveContent;

  @override
  State<RestoreSolanaWalletScreen> createState() => _RestoreSolanaWalletScreenState();
}

class _RestoreSolanaWalletScreenState extends State<RestoreSolanaWalletScreen> {
  late final WalletRegistryService _walletService;
  late final WalletClipboardService _clipboardService;
  late final WalletPhraseImportService _importService;
  late final WalletBackupGateway _backupGateway;
  late MnemonicStrength _strength;
  late List<TextEditingController> _controllers;
  SolanaDerivation _derivation = SolanaDerivation.primary;

  String? _errorMessage;
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();
    _walletService = widget.walletService ?? const WalletRegistryService();
    _clipboardService = widget.clipboardService ?? const WalletClipboardService();
    _importService = widget.importService ?? const WalletPhraseImportService();
    _backupGateway = widget.backupGateway ?? const DefaultWalletBackupGateway();
    _strength = widget.strengthOptions.contains(widget.initialStrength)
        ? widget.initialStrength
        : widget.strengthOptions.first;
    _controllers = _createControllers(_strength.wordCount);
  }

  @override
  void dispose() {
    _disposeControllers(_controllers);
    super.dispose();
  }

  void _changeStrength(MnemonicStrength strength) {
    if (_strength == strength || _isRestoring) return;

    final previousWords = _controllers.map((item) => item.text).toList();
    final nextControllers = _createControllers(strength.wordCount);

    for (var index = 0; index < previousWords.length && index < nextControllers.length; index++) {
      nextControllers[index].text = previousWords[index];
    }

    final oldControllers = _controllers;
    setState(() {
      _strength = strength;
      _controllers = nextControllers;
      _derivation = SolanaDerivation.primary;
      _errorMessage = null;
    });
    _disposeControllers(oldControllers);
  }

  Future<void> _pastePhrase() async {
    try {
      final phrase = await _clipboardService.pastePhrase();
      if (!mounted || phrase == null) return;
      _fillPhrase(phrase);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Could not read the clipboard.');
    }
  }

  Future<void> _importPhrase() async {
    final callback = widget.onImportRequested;

    try {
      final file = callback != null ? await callback() : await _backupGateway.importBackup();
      if (!mounted || file == null) return;
      final backup = await _importService.readBackup(file);
      if (!mounted) return;
      _fillPhrase(
        backup.mnemonicPhrase,
        derivation: backup.derivation,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _messageFor(
          error,
          'Could not import the wallet backup.',
        );
      });
    }
  }

  void _fillPhrase(
    String phrase, {
    SolanaDerivation derivation = SolanaDerivation.primary,
  }) {
    final words = _normalizePhrase(phrase).split(' ');
    final strength = _strengthForWordCount(words.length);

    if (strength == null) {
      setState(() {
        _errorMessage =
            'Use a supported recovery phrase containing '
            '${widget.strengthOptions.map((item) => item.wordCount).join(', ')} '
            'words.';
      });
      return;
    }

    final nextControllers = _createControllers(words.length);
    for (var index = 0; index < words.length; index++) {
      nextControllers[index].text = words[index];
    }

    final oldControllers = _controllers;
    setState(() {
      _strength = strength;
      _controllers = nextControllers;
      _derivation = derivation;
      _errorMessage = null;
    });
    _disposeControllers(oldControllers);
  }

  Future<void> _continue() async {
    if (_isRestoring) return;

    if (_controllers.any((controller) => controller.text.trim().isEmpty)) {
      setState(() => _errorMessage = 'Enter every recovery phrase word.');
      return;
    }

    final mnemonicPhrase = _controllers.map((controller) => controller.text.trim()).join(' ');

    setState(() {
      _isRestoring = true;
      _errorMessage = null;
    });

    late final WalletInfo walletInfo;
    try {
      walletInfo = await _walletService.restoreAndSaveSolanaWallet(
        mnemonicPhrase: mnemonicPhrase,
        derivation: _derivation,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _messageFor(
          error,
          'Could not restore this wallet.',
        );
      });
      setState(() => _isRestoring = false);
      return;
    }

    try {
      await widget.onContinue(walletInfo);
      if (mounted) _clearControllers();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = widget.text.hostCompletionError;
      });
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  MnemonicStrength? _strengthForWordCount(int wordCount) {
    for (final option in widget.strengthOptions) {
      if (option.wordCount == wordCount) return option;
    }
    return null;
  }

  static List<TextEditingController> _createControllers(int count) {
    return List.generate(count, (_) => TextEditingController());
  }

  static void _disposeControllers(List<TextEditingController> controllers) {
    for (final controller in controllers) {
      controller.dispose();
    }
  }

  static String _normalizePhrase(String value) {
    return value.trim().toLowerCase().split(RegExp(r'\s+')).join(' ');
  }

  void _clearControllers() {
    for (final controller in _controllers) {
      controller.clear();
    }
  }

  static String _messageFor(Object error, String fallback) {
    return error is WalletException ? error.message : fallback;
  }

  @override
  Widget build(BuildContext context) {
    return WalletSensitiveContent(
      enabled: widget.protectSensitiveContent,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.title ?? widget.text.restoreTitle)),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 840),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.text.recoveryPhraseLengthLabel,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      Tooltip(
                        message: widget.text.pastePhraseTooltip,
                        child: IconButton(
                          onPressed: _isRestoring ? null : _pastePhrase,
                          icon: const Icon(Icons.content_paste_go_outlined),
                        ),
                      ),
                      Tooltip(
                        message: widget.text.importPhraseTooltip,
                        child: IconButton(
                          onPressed: _isRestoring ? null : _importPhrase,
                          icon: const Icon(Icons.file_open_outlined),
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
                      onChanged: _changeStrength,
                    ),
                  ),
                  const SizedBox(height: 20),
                  MnemonicInputGrid(
                    controllers: _controllers,
                    columns: widget.phraseColumns,
                    enabled: !_isRestoring,
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const ValueKey('walletRestoreContinue'),
                    onPressed: _isRestoring ? null : _continue,
                    child: _isRestoring
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(widget.text.restoreContinueAction),
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
