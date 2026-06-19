class WalletUiText {
  const WalletUiText({
    this.setupTitle = 'Set up your wallet',
    this.setupMessage = 'Create a new wallet or restore one using an existing recovery phrase.',
    this.createAction = 'Create wallet',
    this.restoreAction = 'Restore wallet',
    this.createTitle = 'Create wallet',
    this.restoreTitle = 'Restore wallet',
    this.securityMessage =
        'You can copy or download your recovery phrase, but we recommend '
        'writing it down on paper and storing it somewhere safe.',
    this.walletAddressLabel = 'Wallet address',
    this.recoveryPhraseLengthLabel = 'Recovery phrase length',
    this.continueAction = 'Continue',
    this.restoreContinueAction = 'Restore and continue',
    this.copyAddressTooltip = 'Copy wallet address',
    this.copyPhraseTooltip = 'Copy recovery phrase',
    this.downloadPhraseTooltip = 'Download recovery phrase',
    this.generatePhraseTooltip = 'Generate a new phrase',
    this.pastePhraseTooltip = 'Paste recovery phrase',
    this.importPhraseTooltip = 'Import recovery phrase file',
    this.addressCopiedMessage = 'Wallet address copied',
    this.phraseCopiedMessage = 'Recovery phrase copied for 1 minute',
    this.backupSavedMessage = 'Recovery phrase backup saved',
    this.hostCompletionError =
        'The wallet was securely saved, but the host app could not finish '
        'setup. You can safely try continuing again.',
  });

  final String setupTitle;
  final String setupMessage;
  final String createAction;
  final String restoreAction;
  final String createTitle;
  final String restoreTitle;
  final String securityMessage;
  final String walletAddressLabel;
  final String recoveryPhraseLengthLabel;
  final String continueAction;
  final String restoreContinueAction;
  final String copyAddressTooltip;
  final String copyPhraseTooltip;
  final String downloadPhraseTooltip;
  final String generatePhraseTooltip;
  final String pastePhraseTooltip;
  final String importPhraseTooltip;
  final String addressCopiedMessage;
  final String phraseCopiedMessage;
  final String backupSavedMessage;
  final String hostCompletionError;
}
