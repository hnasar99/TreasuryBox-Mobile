import 'model.dart';

abstract interface class TxSigner {
  String? get address;
  bool get connected;
  List<String> get chains;
  Future<void> configure(String projectId);
  Future<void> connect(List<String> chains, Future<void> Function(Uri uri) showPairing);
  Future<void> disconnect();
  Future<String> send(PreparedTx tx);
  Future<String> signTypedData({required String caip2, required String typedDataJson});
}

class UnavailableSigner implements TxSigner {
  @override
  String? get address => null;
  @override
  bool get connected => false;
  @override
  List<String> get chains => const [];

  @override
  Future<void> configure(String projectId) async {}

  @override
  Future<void> connect(List<String> chains, Future<void> Function(Uri uri) showPairing) async {
    throw StateError('WalletConnect is not available on this desktop build. Dry-run still records the proposal.');
  }

  @override
  Future<void> disconnect() async {}

  @override
  Future<String> send(PreparedTx tx) async {
    throw StateError('No external wallet is connected.');
  }

  @override
  Future<String> signTypedData({required String caip2, required String typedDataJson}) async {
    throw StateError('No external wallet is connected.');
  }
}
