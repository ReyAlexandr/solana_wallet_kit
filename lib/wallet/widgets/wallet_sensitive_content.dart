import 'package:flutter/material.dart';

const walletSensitiveContentObscurerKey = ValueKey(
  'walletSensitiveContentObscurer',
);

class WalletSensitiveContent extends StatefulWidget {
  const WalletSensitiveContent({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final Widget child;
  final bool enabled;

  @override
  State<WalletSensitiveContent> createState() => _WalletSensitiveContentState();
}

class _WalletSensitiveContentState extends State<WalletSensitiveContent>
    with WidgetsBindingObserver {
  bool _obscured = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.enabled) return;

    final obscured = state != AppLifecycleState.resumed;
    if (_obscured == obscured || !mounted) return;
    setState(() => _obscured = obscured);
  }

  @override
  void didUpdateWidget(WalletSensitiveContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled && !widget.enabled && _obscured) {
      _obscured = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return Stack(
      children: [
        widget.child,
        if (_obscured)
          Positioned.fill(
            key: walletSensitiveContentObscurerKey,
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surface,
              child: Center(
                child: Semantics(
                  label: 'Wallet content hidden while the app is inactive',
                  child: const Icon(Icons.lock_outline),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
