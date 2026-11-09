import '../signer.dart';

/// This preview never signs or broadcasts transactions.
/// Native WalletConnect and OpenHuman are not claimed to run in the browser.
class WebPreviewSigner extends UnavailableSigner {
  @override
  Future<void> connect(
    List<String> chains,
    Future<void> Function(Uri uri) showPairing,
  ) async {
    throw StateError(
      'Web preview: wallet signing is disabled. Treasury proposals run in '
      'dry-run mode. Use the mobile app for native WalletConnect.',
    );
  }
}
