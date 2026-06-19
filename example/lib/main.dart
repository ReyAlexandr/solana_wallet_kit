import 'package:flutter/material.dart';
import 'package:solana_wallet_kit/solana_wallet_kit.dart';

void main() {
  runApp(const WalletKitExampleApp());
}

class WalletKitExampleApp extends StatelessWidget {
  const WalletKitExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Solana Wallet Kit example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      ),
      home: const WalletExampleHome(),
    );
  }
}

class WalletExampleHome extends StatelessWidget {
  const WalletExampleHome({super.key});

  @override
  Widget build(BuildContext context) {
    return WalletSetupScreen(
      onWalletReady: (account) {
        return Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => WalletReadyScreen(account: account),
          ),
        );
      },
    );
  }
}

class WalletReadyScreen extends StatelessWidget {
  const WalletReadyScreen({super.key, required this.account});

  final WalletAccount account;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet ready')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SelectableText(account.address),
      ),
    );
  }
}
