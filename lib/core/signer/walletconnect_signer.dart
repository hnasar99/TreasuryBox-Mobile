import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:reown_core/reown_core.dart';
import 'package:reown_sign/reown_sign.dart';

import '../evm/abi.dart';
import '../model.dart';
import '../signer.dart';

class WalletConnectSigner extends ChangeNotifier implements TxSigner {
  ReownSignClient? _client;
  String? _configuredProjectId;
  SessionData? _session;
  String? _address;
  List<String> _chains = const [];
  Future<String>? _pending;

  @override
  String? get address => _address;

  @override
  bool get connected => _session != null && _address != null;

  @override
  List<String> get chains => _chains;

  @override
  Future<void> configure(String projectId) async {
    final id = projectId.trim();
    if (!RegExp(r'^[a-fA-F0-9]{32}$').hasMatch(id)) {
      throw const FormatException('WalletConnect Project ID inválido. Debe tener 32 caracteres hexadecimales.');
    }
    if (_client != null && _configuredProjectId == id) return;

    final client = await ReownSignClient.createInstance(
      projectId: id,
      memoryStore: true,
      logLevel: LogLevel.nothing,
      metadata: const PairingMetadata(
        name: 'TreasuryBox',
        description: 'Tesorería. La wallet externa firma.',
        url: 'https://github.com/hnasar99/treasurybox-mobile',
        icons: [],
        redirect: Redirect(native: 'treasurybox://callback'),
      ),
    ).timeout(const Duration(seconds: 30));
    _client = client;
    _configuredProjectId = id;
    notifyListeners();
  }

  @override
  Future<void> connect(List<String> chains, Future<void> Function(Uri uri) showPairing) async {
    final client = _client;
    if (client == null) {
      throw StateError('WalletConnect no está inicializado. Verificá WALLETCONNECT_PROJECT_ID en el build.');
    }
    if (chains.isEmpty) throw StateError('This build has no chains to approve.');
    final response = await client.connect(
      optionalNamespaces: {
        'eip155': RequiredNamespace(
          chains: chains,
          methods: ['eth_sendTransaction', 'eth_signTypedData_v4', 'wallet_addEthereumChain'],
          events: ['accountsChanged', 'chainChanged'],
        ),
      },
    );
    final approval = response.session.future;
    unawaited(approval.then<void>((_) {}, onError: (Object error, StackTrace stack) {}));
    if (response.uri != null) await showPairing(response.uri!);
    final session = await approval.timeout(const Duration(minutes: 3));
    _select(session);
    notifyListeners();
  }

  void _select(SessionData session) {
    final accounts = session.namespaces.values.expand((ns) => ns.accounts).toList();
    if (accounts.isEmpty) throw StateError('The wallet did not approve an account.');
    final parts = accounts.first.split(':');
    if (parts.length != 3) throw const FormatException('Invalid wallet account.');
    _address = validateAddress(parts[2]);
    _chains = accounts.map((account) => account.split(':').take(2).join(':')).toSet().toList();
    _session = session;
  }

  bool _permitted(String caip2) {
    final session = _session;
    final address = _address;
    if (session == null || address == null) return false;
    final account = '$caip2:${address.toLowerCase()}';
    return session.namespaces.entries.any(
      (entry) =>
          entry.value.methods.contains('eth_sendTransaction') &&
          entry.value.accounts.any((item) => item.toLowerCase() == account),
    );
  }

  @override
  Future<String> send(PreparedTx tx) async {
    if (_pending != null) throw StateError('Another wallet request is unresolved.');
    final client = _client;
    final session = _session;
    final address = _address;
    if (client == null || session == null || address == null) {
      throw StateError('Reconnect the wallet.');
    }
    if (!_permitted(tx.chain.caip2)) {
      throw StateError('The wallet has not approved ${tx.chain.caip2} for this account.');
    }
    final pending = client
        .request(
          topic: session.topic,
          chainId: tx.chain.caip2,
          request: SessionRequestParams(
            method: 'eth_sendTransaction',
            params: [tx.transaction(address)],
          ),
        )
        .then(_hash);
    _pending = pending;
    notifyListeners();
    try {
      return await pending.timeout(const Duration(minutes: 2));
    } finally {
      _pending = null;
      notifyListeners();
    }
  }

  @override
  Future<String> signTypedData({required String caip2, required String typedDataJson}) async {
    final client = _client;
    final session = _session;
    final address = _address;
    if (client == null || session == null || address == null) {
      throw StateError('Reconnect the wallet.');
    }
    final signature = await client.request(
      topic: session.topic,
      chainId: caip2,
      request: SessionRequestParams(
        method: 'eth_signTypedData_v4',
        params: [address, typedDataJson],
      ),
    );
    if (signature is! String || !signature.startsWith('0x')) {
      throw const FormatException('The wallet returned an invalid typed-data signature.');
    }
    return signature;
  }

  @override
  Future<void> disconnect() async {
    final client = _client;
    final session = _session;
    _session = null;
    _address = null;
    _chains = const [];
    if (client != null && session != null) {
      await client.disconnect(
        topic: session.topic,
        reason: const ReownSignError(code: 6000, message: 'User disconnected'),
      );
    }
    notifyListeners();
  }
}

String _hash(Object? value) {
  if (value is! String || !RegExp(r'^0x[0-9a-fA-F]{64}$').hasMatch(value)) {
    throw const FormatException('The wallet returned an invalid transaction hash.');
  }
  return value;
}
