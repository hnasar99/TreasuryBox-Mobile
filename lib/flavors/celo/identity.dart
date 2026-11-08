import '../../core/evm/abi.dart';
import '../../core/evm/json_rpc.dart';
import '../../core/model.dart';
import 'tokens.dart';

class CeloIdentity {
  CeloIdentity({EvmReadClient? reads, this.registry = CeloTokens.identityRegistry, this.rpcUrl = CeloTokens.rpc})
      : _reads = reads ?? EvmReadClient();

  final EvmReadClient _reads;
  final String registry;
  final String rpcUrl;

  static AgentIdentity unpublished() {
    final registration = localRegistration();
    return AgentIdentity(
      name: registration['name'] as String,
      description: registration['description'] as String,
      registration: registration,
      registry: 'eip155:${celoChain.reference}:$registryAddress',
    );
  }

  static const registryAddress = CeloTokens.identityRegistry;

  static Map<String, Object?> localRegistration({String? agentId}) {
    final file = <String, Object?>{
      'type': 'https://eips.ethereum.org/EIPS/eip-8004#registration-v1',
      'name': 'TreasuryBox',
      'description': 'Tesorería LatAm con ancla en USD. El agente propone; la wallet externa firma.',
      'services': [
        {'name': 'wallet', 'endpoint': 'eip155:${celoChain.reference}'},
      ],
      'x402Support': false,
      'active': true,
    };
    if (agentId != null && agentId.isNotEmpty) {
      file['registrations'] = [
        {
          'agentId': agentId,
          'agentRegistry': 'eip155:${celoChain.reference}:$registryAddress',
        },
      ];
    }
    return file;
  }

  Future<AgentIdentity> read(String agentId) async {
    final tokenId = BigInt.parse(agentId);
    final uri = await _reads.readString(
      rpcUrl: rpcUrl,
      to: registry,
      data: encodeTokenUri(tokenId),
    );
    final ownerWord = await _reads.call(rpcUrl, 'eth_call', [
      {'to': validateAddress(registry), 'data': encodeOwnerOf(tokenId)},
      'latest',
    ]);
    final registration = localRegistration(agentId: agentId);
    return AgentIdentity(
      name: registration['name'] as String,
      description: registration['description'] as String,
      registration: registration,
      agentId: agentId,
      agentUri: uri,
      owner: decodeAddressWord(ownerWord),
      registry: 'eip155:${celoChain.reference}:$registry',
    );
  }
}
