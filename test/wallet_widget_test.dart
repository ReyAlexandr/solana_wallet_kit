import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solana_wallet_kit/solana_wallet_kit.dart';

void main() {
  const mnemonic = 'nothing steak step patient peasant assist add coral tone harsh hint dilemma';
  late WalletMaterial wallet;

  setUpAll(() async {
    wallet = await const SolanaWalletCreationService().restoreFromMnemonic(
      mnemonic,
    );
  });

  testWidgets('setup screen opens create and restore flows', (tester) async {
    final service = _FakeWalletRegistryService(wallet);

    await tester.pumpWidget(
      MaterialApp(
        home: WalletSetupScreen(
          walletService: service,
          backupGateway: const _FakeBackupGateway(),
          onWalletReady: (_) {},
        ),
      ),
    );

    expect(find.text('Create wallet'), findsOneWidget);
    expect(find.text('Restore wallet'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('walletSetupCreate')));
    await tester.pumpAndSettle();
    expect(find.byType(CreateSolanaWalletScreen), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('walletSetupRestore')));
    await tester.pumpAndSettle();
    expect(find.byType(RestoreSolanaWalletScreen), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(12));
  });

  testWidgets('privacy overlay follows lifecycle without SensitiveContent', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WalletSensitiveContent(child: Text('secret')),
      ),
    );

    expect(find.byKey(walletSensitiveContentObscurerKey), findsNothing);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(find.byKey(walletSensitiveContentObscurerKey), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.byKey(walletSensitiveContentObscurerKey), findsNothing);
  });

  testWidgets('disabled privacy leaves content visible while paused', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WalletSensitiveContent(enabled: false, child: Text('secret')),
      ),
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    expect(find.text('secret'), findsOneWidget);
    expect(find.byKey(walletSensitiveContentObscurerKey), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  testWidgets('mnemonic inputs become one column on narrow screens', (
    tester,
  ) async {
    final controllers = List.generate(12, (_) => TextEditingController());
    addTearDown(() {
      for (final controller in controllers) {
        controller.dispose();
      }
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: MnemonicInputGrid(controllers: controllers),
          ),
        ),
      ),
    );

    final narrowGrid = tester.widget<GridView>(find.byType(GridView));
    expect(
      (narrowGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount).crossAxisCount,
      1,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 700,
            child: MnemonicInputGrid(controllers: controllers),
          ),
        ),
      ),
    );

    final wideGrid = tester.widget<GridView>(find.byType(GridView));
    expect(
      (wideGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount).crossAxisCount,
      2,
    );
  });

  testWidgets('create persists before returning only the public wallet info', (
    tester,
  ) async {
    final events = <String>[];
    final service = _FakeWalletRegistryService(wallet, events: events);
    WalletInfo? callbackInfo;

    await tester.pumpWidget(
      MaterialApp(
        home: CreateSolanaWalletScreen(
          walletService: service,
          backupGateway: const _FakeBackupGateway(),
          requireBackupConfirmation: false,
          onContinue: (walletInfo) {
            events.add('callback');
            callbackInfo = walletInfo;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pumpAndSettle();
    final continueButton = find.byKey(const ValueKey('walletCreateContinue'));
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(events, ['saved', 'callback']);
    expect(callbackInfo, same(wallet.info));
    expect(callbackInfo?.address, wallet.address);
  });

  testWidgets('restore persists before returning only the public wallet info', (
    tester,
  ) async {
    final events = <String>[];
    final service = _FakeWalletRegistryService(wallet, events: events);
    WalletInfo? callbackInfo;

    await tester.pumpWidget(
      MaterialApp(
        home: RestoreSolanaWalletScreen(
          walletService: service,
          backupGateway: const _FakeBackupGateway(),
          onContinue: (walletInfo) {
            events.add('callback');
            callbackInfo = walletInfo;
          },
        ),
      ),
    );

    final mnemonic = wallet.mnemonic!;
    for (var index = 0; index < mnemonic.length; index++) {
      await tester.enterText(
        find.byKey(ValueKey('mnemonicWordInput${index + 1}')),
        mnemonic[index],
      );
    }

    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('walletRestoreContinue')));
    await tester.pumpAndSettle();

    expect(events, ['saved', 'callback']);
    expect(callbackInfo, same(wallet.info));
  });

  testWidgets('wallet secrets screen shows address, private key, and phrase', (
    tester,
  ) async {
    final service = _FakeWalletRegistryService(wallet);

    await tester.pumpWidget(
      MaterialApp(
        home: WalletSecretsScreen(
          address: wallet.address,
          walletService: service,
          protectSensitiveContent: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Wallet secrets'), findsOneWidget);
    expect(find.byKey(const ValueKey('walletSecretsAddress')), findsOneWidget);
    expect(find.byKey(const ValueKey('walletSecretsPrivateKey')), findsOneWidget);
    expect(find.text(wallet.address), findsOneWidget);
    expect(find.text(wallet.privateKeyBase58), findsOneWidget);
    expect(find.byKey(const ValueKey('walletSecretsMnemonic')), findsOneWidget);
    expect(find.text(wallet.mnemonic!.first), findsOneWidget);
  });

  testWidgets('wallet secrets screen handles missing local material', (
    tester,
  ) async {
    final service = _FakeWalletRegistryService(wallet, materialToRead: null);

    await tester.pumpWidget(
      MaterialApp(
        home: WalletSecretsScreen(
          address: wallet.address,
          walletService: service,
          protectSensitiveContent: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Wallet secrets are not available on this device.'),
      findsOneWidget,
    );
  });

  testWidgets('wallet secrets screen allows a private-key-only wallet', (
    tester,
  ) async {
    final privateKeyOnly = WalletMaterial(
      info: wallet.info,
      secret: wallet.secret,
    );
    final service = _FakeWalletRegistryService(wallet, materialToRead: privateKeyOnly);

    await tester.pumpWidget(
      MaterialApp(
        home: WalletSecretsScreen(
          address: wallet.address,
          walletService: service,
          protectSensitiveContent: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(wallet.privateKeyBase58), findsOneWidget);
    expect(
      find.text('Recovery phrase is not available on this device.'),
      findsOneWidget,
    );
  });
}

class _FakeWalletRegistryService extends WalletRegistryService {
  _FakeWalletRegistryService(
    this.wallet, {
    this.events,
    Object? materialToRead = _defaultMaterial,
  }) : materialToRead = identical(materialToRead, _defaultMaterial)
           ? wallet
           : materialToRead as WalletMaterial?;

  static const _defaultMaterial = Object();

  final WalletMaterial wallet;
  final List<String>? events;
  final WalletMaterial? materialToRead;

  @override
  Future<WalletMaterial> createWalletMaterialForBackup({
    MnemonicStrength mnemonicStrength = MnemonicStrength.words12,
    SolanaDerivation derivation = SolanaDerivation.primary,
  }) async {
    return wallet;
  }

  @override
  Future<void> saveBackedUpWalletMaterial(WalletMaterial material) async {
    events?.add('saved');
  }

  @override
  Future<WalletInfo> restoreAndSaveSolanaWallet({
    required String mnemonicPhrase,
    SolanaDerivation derivation = SolanaDerivation.primary,
  }) async {
    events?.add('saved');
    return wallet.info;
  }

  @override
  Future<WalletMaterial?> readWalletMaterial({
    required String address,
  }) async {
    return materialToRead;
  }
}

class _FakeBackupGateway implements WalletBackupGateway {
  const _FakeBackupGateway();

  @override
  Future<bool> exportBackup(WalletPhraseFile file) async => true;

  @override
  Future<WalletPhraseFile?> importBackup() async => null;
}
