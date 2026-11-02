/// Ids only. Each entrypoint constructs its own ecosystem so the other
/// flavor is not imported into that build.
const flavorEcosystemIds = <String, List<String>>{
  'celo': ['ripio-celo'],
  'twin': ['twin-arc'],
};
