// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get navInicio => 'Início';

  @override
  String get navCaja => 'Caixa';

  @override
  String get navAgente => 'Agente';

  @override
  String get navMas => 'Mais';

  @override
  String get scanAction => 'Escanear';

  @override
  String get balances => 'Saldos';

  @override
  String get quote => 'Cotar';

  @override
  String get rotate => 'Girar';

  @override
  String get collect => 'Cobrar';

  @override
  String get pay => 'Pagar';

  @override
  String get pnl => 'Resultado';

  @override
  String get dryRun => 'Simulação';

  @override
  String get liveMode => 'Ao vivo';

  @override
  String get buffer => 'Reserva';

  @override
  String get rotable => 'Girável';

  @override
  String get decisions => 'Decisões';

  @override
  String get yieldReserve => 'Posição com rendimento';

  @override
  String get yieldDisclaimer =>
      'É rendimento sobre o ativo local. Não há taxa verificada.';

  @override
  String get noPrice => 'Sem preço';

  @override
  String fxSource(String source, String at) {
    return 'Fonte $source · $at';
  }

  @override
  String get perChain => 'Por rede';

  @override
  String get proposalTitle => 'Proposta';

  @override
  String get confirm => 'Confirmar';

  @override
  String get reject => 'Recusar';

  @override
  String get costHome => 'Custo na moeda local';

  @override
  String get costUsd => 'Custo em USD';

  @override
  String get notExecutable => 'Sem cotação executável';

  @override
  String get guardBlocked => 'O movimento não passa nos controles';

  @override
  String get connectWallet => 'Conectar carteira';

  @override
  String get dailyReview => 'Revisão diária';

  @override
  String get deposit => 'Depositar';

  @override
  String get beneficiary => 'Beneficiário';

  @override
  String get disclaimerCrossBorder =>
      'A empresa assina com a própria carteira. Este app não custodia fundos nem é aconselhamento regulatório.';

  @override
  String get modeLocal => 'Modo local';

  @override
  String get insufficientData => 'Sem dados suficientes';

  @override
  String get doubleConfirm =>
      'Primeiro pagamento a este beneficiário: confirme outra vez.';

  @override
  String get testnetBadge => 'TESTNET';

  @override
  String get contextLayer => 'Camada';

  @override
  String get contextNetwork => 'Rede';

  @override
  String get contextRail => 'Trilho';

  @override
  String get contextWallet => 'Carteira';

  @override
  String get usdView => 'USD';

  @override
  String get homeView => 'Local';

  @override
  String get agentHint => 'O agente propõe. Não assina nem aprova.';

  @override
  String get refresh => 'Atualizar';

  @override
  String get amount => 'Valor';

  @override
  String get address => 'Endereço';

  @override
  String get watchHint => 'Endereço para ler saldos';

  @override
  String get registerDryRun => 'Registrar simulação';

  @override
  String get signSend => 'Assinar e enviar';

  @override
  String get language => 'Idioma';

  @override
  String get pasteCode => 'Colar código';

  @override
  String get openLink => 'Abrir link';

  @override
  String get noWallet => 'Sem carteira';

  @override
  String get homeEmpty => 'Ainda não há saldos lidos.';

  @override
  String get scheduled => 'Pagamentos agendados';

  @override
  String get addScheduled => 'Agendar pagamento';

  @override
  String get supplier => 'Fornecedor';

  @override
  String get dueDate => 'Vencimento';

  @override
  String get memo => 'Nota';

  @override
  String get invoiceRef => 'Comprovante';

  @override
  String get country => 'País';

  @override
  String get verified => 'Verificado';

  @override
  String get save => 'Salvar';

  @override
  String get close => 'Fechar';

  @override
  String get slippage => 'Deslizamento';

  @override
  String get expires => 'Vence';

  @override
  String get warnings => 'Avisos';

  @override
  String get steps => 'Passos';

  @override
  String get agentId => 'Identidade do agente';

  @override
  String get companyLink => 'Vínculo da empresa';

  @override
  String get clearSession => 'Encerrar sessão da empresa';

  @override
  String get projectId => 'Project ID da carteira';

  @override
  String get rampOut => 'Sair com um provedor';

  @override
  String get onRamp => 'Entrar com um provedor';

  @override
  String get otcOnly =>
      'Só instruções do operador. Este app não integra essa API.';

  @override
  String get featureOff => 'Esta ação está desligada neste build.';

  @override
  String get copied => 'Pronto para compartilhar';

  @override
  String get reportHold => 'Contra não ter movido';

  @override
  String get reportInflation => 'Contra a inflação';

  @override
  String get chainSeparated => 'Os totais não se somam entre redes.';

  @override
  String get vaultDeposit => 'Apartar';

  @override
  String get vaultRedeem => 'Retirar';
}
