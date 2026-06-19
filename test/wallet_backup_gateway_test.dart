import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solana_wallet_kit/solana_wallet_kit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('solana_wallet_kit/backup');
  const file = WalletPhraseFile(
    fileName: 'solana-wallet-test.json',
    contents: '{"format":"solana-wallet-backup"}',
  );

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      null,
    );
  });

  test('Android export sends the expected document payload', () async {
    MethodCall? receivedCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async {
        receivedCall = call;
        return true;
      },
    );

    const gateway = DefaultWalletBackupGateway(
      channel: channel,
      targetPlatform: TargetPlatform.android,
    );

    expect(await gateway.exportBackup(file), isTrue);
    expect(receivedCall?.method, 'exportBackup');
    expect(receivedCall?.arguments, {
      'fileName': file.fileName,
      'contents': file.contents,
      'mimeType': 'application/json',
    });
  });

  test('Android export reports document-picker cancellation', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (_) async => false,
    );

    const gateway = DefaultWalletBackupGateway(
      channel: channel,
      targetPlatform: TargetPlatform.android,
    );

    expect(await gateway.exportBackup(file), isFalse);
  });
}
