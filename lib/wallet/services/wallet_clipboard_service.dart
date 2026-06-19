import 'dart:async';

import 'package:flutter/services.dart';

class WalletClipboardService {
  const WalletClipboardService();

  Future<void> copyText(String text) {
    return Clipboard.setData(ClipboardData(text: text.trim()));
  }

  Future<void> copyPhrase(
    String mnemonicPhrase, {
    Duration clearAfter = const Duration(minutes: 1),
  }) async {
    final phrase = mnemonicPhrase.trim();
    await copyText(phrase);

    if (clearAfter > Duration.zero) {
      unawaited(_clearIfUnchanged(phrase, clearAfter));
    }
  }

  Future<void> copyAddress(String address) {
    return copyText(address);
  }

  Future<String?> pastePhrase() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();

    if (text == null || text.isEmpty) return null;

    return text;
  }

  Future<void> _clearIfUnchanged(String expected, Duration delay) async {
    try {
      await Future<void>.delayed(delay);

      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text == expected) {
        await Clipboard.setData(const ClipboardData(text: ''));
      }
    } catch (_) {
      // Clipboard cleanup is best-effort and must not surface asynchronously.
    }
  }
}
