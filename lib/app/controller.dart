import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/company_link.dart';
import '../core/amount.dart';
import '../core/app_env.dart';
import '../core/daily_job.dart';
import '../core/decimal.dart';
import '../core/guards.dart';
import '../core/ledger.dart';
import '../core/model.dart';
import '../core/qr/qr_intent.dart';
import '../core/report.dart';
import '../core/session_api.dart';
import '../core/signer.dart';
import '../core/treasury_api.dart';
import '../flavors/flavor_config.dart';

class TreasuryController extends ChangeNotifier {
  TreasuryController({
    required this.flavor,
    required this.env,
    required this.signer,
    required this.store,
    SessionApi? sessionApi,
    DateTime Function()? clock,
  })  : _sessions = sessionApi ?? SessionApi(),
        _clock = clock ?? DateTime.now {
    policy = TreasuryPolicy(
      homeCurrency: env.homeCurrency,
      maxOpHome: Decimal.parse(env.maxOpAmount),
      maxDailyHome: Decimal.parse(env.maxDailyAmount),
      liquidityBufferDays: int.parse(env.bufferDays),
      timeZone: env.timeZone,
      inflationMonthlyPct: Decimal.parse(env.inflationMonthlyPct),
    );
    day = DayLedger.empty(artDayKey(_clock().toUtc()));
    agent = _publishedIdentity(flavor.ecosystem);
  }

  final FlavorConfig flavor;
  final AppEnv env;
  final TxSigner signer;
  final KvStore store;
  final SessionApi _sessions;
  final DateTime Function() _clock;
  final Ledger ledger = Ledger();

  late TreasuryPolicy policy;
  late DayLedger day;

  TreasuryEcosystem get ecosystem => flavor.ecosystem;

  String watchAddress = '';
  List<BalanceRow> balances = [];
  List<ScheduledPayment> scheduled = [];
  List<Beneficiary> book = [];
  ValuationView view = ValuationView.home;
  FxRate? spot;
  String? error;
  String? status;
  bool busy = false;
  bool localMode = true;
  Locale? locale;
  EcosystemSession? session;
  List<String> dailyNotes = [];
  Amount? vStart;
  AgentIdentity? agent;
  String? lastAttribution;

  String? get address {
    final signed = signer.address;
    if (signed != null && signed.isNotEmpty) return signed;
    final watch = watchAddress.trim();
    return watch.isEmpty ? null : watch;
  }

  Amount? get homeBalance => _homeBalance();

  Amount? get usdBalance {
    final rows = balances.where((row) => row.token.key == ecosystem.usdLeg.key).toList();
    return sumSameBook(rows);
  }

  Amount get dailyCap => policy.maxDailyRaw(ecosystem.homeStable.decimals);

  Amount get dailySpent {
    final today = day.forDay(artDayKey(_clock().toUtc()));
    final raw = env.live ? today.liveSpent : today.dryRunIntended;
    return Amount(raw: raw, decimals: ecosystem.homeStable.decimals);
  }

  Future<void> load() async {
    final raw = await store.read(DayLedger.storageKey);
    if (raw != null) {
      try {
        day = DayLedger.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        day = DayLedger.empty(artDayKey(_clock().toUtc()));
      }
    }
    agent = await _loadIdentity(ecosystem);
    notifyListeners();
  }

  void setLocale(Locale? next) {
    locale = next;
    notifyListeners();
  }

  void setWatch(String value) {
    watchAddress = value;
  }

  void toggleView() {
    view = view == ValuationView.home ? ValuationView.usd : ValuationView.home;
    notifyListeners();
  }

  Future<void> refresh() async {
    await _work(() async {
      final account = address;
      if (account == null) {
        balances = [];
        error = 'Pegá una dirección o conectá la wallet.';
        return;
      }
      final map = {for (final chain in ecosystem.chains) chain.caip2: account};
      final panel = await TreasuryPanel(baseUrl: env.treasuryApiUrl).balances(ecosystem.tokens);
      localMode = panel.localMode || panel.rows.isEmpty;
      balances = localMode ? await ecosystem.getBalances(map) : panel.rows;
      spot = await ecosystem.rate(ecosystem.homeStable, ecosystem.usdLeg);
      vStart ??= _homeBalance();
      status = localMode ? 'Modo local' : 'Panel';
    });
  }

  Future<FxQuote> quote(TokenRef from, TokenRef to, String human) async {
    final amount = Amount.parse(human, from.decimals);
    final result = await ecosystem.quote(from, to, amount);
    ledger.add(LedgerEvent(
      at: _clock().toUtc(),
      kind: LedgerKind.quote,
      flavor: flavor.id,
      ecosystemId: ecosystem.id,
      dryRun: !env.live,
      caip2: from.chain.caip2,
      raw: amount.raw,
      decimals: amount.decimals,
      rate: result.rate,
      venue: result.venue,
      reason: result.executable ? 'executable' : 'not-executable',
    ));
    notifyListeners();
    return result;
  }

  Future<bool> confirmQuote(FxQuote quote) async {
    final home = _homeCost(quote.from, quote.amountIn);
    if (home == null) {
      error = 'Sin precio';
      notifyListeners();
      return false;
    }
    final guard = _guard(home, executable: quote.executable, human: true);
    if (!guard.ok) return _blocked(guard);
    if (!quote.executable || !flavor.features.contains(Feature.fxSwap)) {
      return _propose('Cotización no ejecutable', guard);
    }
    final steps = await ecosystem.prepareExecute(quote);
    if (!env.live) {
      return _propose(
        'Simulación de rotación ${quote.amountIn.format()} ${quote.from.symbol}',
        guard,
        home: home,
        steps: steps,
      );
    }
    return _sign(steps, home, 'rotación');
  }

  Future<bool> transfer(TokenRef token, String human, String to) async {
    final amount = Amount.parse(human, token.decimals);
    final home = _homeCost(token, amount);
    if (home == null) {
      error = 'Sin precio';
      notifyListeners();
      return false;
    }
    final guard = _guard(home, executable: true, human: true);
    if (!guard.ok) return _blocked(guard);
    final steps = await ecosystem.prepareTransfer(token, amount, to);
    if (!env.live) {
      return _propose(
        'Simulación de envío ${amount.format()} ${token.symbol}',
        guard,
        home: home,
        steps: steps,
      );
    }
    return _sign(steps, home, 'envío');
  }

  Future<bool> vaultDeposit(String human) async {
    final yieldBox = ecosystem;
    if (yieldBox is! YieldActions) return false;
    final amount = Amount.parse(human, ecosystem.homeStable.decimals);
    final guard = _guard(amount, executable: true, human: true);
    if (!guard.ok) return _blocked(guard);
    final steps = await (yieldBox as YieldActions).prepareVaultDeposit(amount, address ?? ecosystem.homeStable.address);
    if (!env.live) return _propose('Simulación: apartar ${amount.format()} en la posición', guard, home: amount);
    return _sign(steps, amount, 'depósito');
  }

  Future<bool> vaultRedeem(String human) async {
    final yieldBox = ecosystem;
    if (yieldBox is! YieldActions) return false;
    final shares = Amount.parse(human, 18);
    final owner = address;
    if (owner == null) {
      error = 'Falta la dirección que firma.';
      notifyListeners();
      return false;
    }
    final steps = await (yieldBox as YieldActions).prepareVaultRedeem(shares, owner, owner);
    if (!env.live) {
      return _propose('Simulación: retirar ${shares.format()} de la posición', _guard(Amount.zero(18), executable: true, human: true));
    }
    return _sign(steps, Amount.zero(18), 'retiro');
  }

  Future<PaymentPlan> draftPayment(PaymentIntent intent) async {
    final drafted = await ecosystem.plan(intent);
    final home = intent.token.symbol == ecosystem.homeStable.symbol
        ? intent.amount
        : _homeCost(intent.token, intent.amount);
    final guard = home == null
        ? GuardResult.blocked('no_price', buffer: Amount.zero(0), rotable: Amount.zero(0))
        : _guard(home, executable: drafted.fxLegs.every((leg) => leg.executable) || drafted.fxLegs.isEmpty, human: intent.to.confirmations >= 1);
    return PaymentPlan(
      intent: intent,
      fxLegs: drafted.fxLegs,
      steps: drafted.steps,
      totalCostHome: home ?? Amount.zero(ecosystem.homeStable.decimals),
      totalCostUsd: drafted.totalCostUsd,
      expiresAt: drafted.expiresAt,
      guardOk: guard.ok && drafted.guardOk && home != null,
      now: _clock(),
    );
  }

  Future<bool> confirmPayment(PaymentPlan plan) async {
    if (!plan.executable) {
      final next = plan.intent.to.confirmations + 1;
      final index = book.indexWhere((item) => item.id == plan.intent.to.id);
      if (index >= 0) book[index] = plan.intent.to.copyWith(confirmations: next);
      return _propose(
        next < 2 && !plan.intent.to.verified ? 'Primera confirmación del beneficiario' : 'Pago no ejecutable',
        GuardResult.blocked(plan.guardOk ? 'needs_second' : 'blocked', buffer: Amount.zero(plan.totalCostHome.decimals), rotable: Amount.zero(plan.totalCostHome.decimals)),
      );
    }
    if (!env.live) {
      var steps = plan.steps;
      if (steps.isEmpty) {
        try {
          steps = await ecosystem.prepare(plan);
        } catch (_) {}
      }
      return _propose(
        'Simulación de pago a ${plan.intent.to.name}',
        GuardResult.ok(buffer: Amount.zero(0), rotable: Amount.zero(0)),
        home: plan.totalCostHome,
        steps: steps,
      );
    }
    final steps = await ecosystem.prepare(plan);
    return _sign(steps, plan.totalCostHome, 'pago');
  }

  Future<PaymentRequest> collect(String human) => ecosystem.paymentRequest(Amount.parse(human, ecosystem.homeStable.decimals));

  PaymentRequest? collectTracked() {
    final tracked = ecosystem;
    if (tracked is! TrackedInvoice || !flavor.features.contains(Feature.x402Collect)) return null;
    return (tracked as TrackedInvoice).collectTracked();
  }

  Future<void> daily() async {
    final review = runDailyReview(
      flavor: flavor.id,
      ecosystemId: ecosystem.id,
      homeBalance: _homeBalance() ?? Amount.zero(ecosystem.homeStable.decimals),
      scheduled: scheduled,
      policy: policy,
      nowUtc: _clock().toUtc(),
      liveMode: env.live,
    );
    dailyNotes = review.notes;
    ledger.add(review.proposal);
    status = review.notes.join('\n');
    notifyListeners();
  }

  TreasuryReport report() {
    final end = _homeBalance();
    return TreasuryReport.build(
      vStart: vStart,
      vEnd: end,
      flows: const [],
      inflationMonthlyPct: policy.inflationMonthlyPct,
      periodStart: DateTime.utc(_clock().toUtc().year, _clock().toUtc().month),
      periodEnd: _clock().toUtc(),
    );
  }

  Future<void> connect(Future<void> Function(Uri uri) showPairing) async {
    await _work(() async {
      final projectId = env.walletConnectProjectId.trim();
      if (projectId.isEmpty) {
        throw StateError('Falta WALLETCONNECT_PROJECT_ID. Reconstruí la app con el Project ID de Reown.');
      }
      await signer.configure(projectId);
      await signer.connect(flavor.walletChains, showPairing);
      status = signer.address;
    });
  }

  Future<void> redeemLink(String raw) async {
    final intent = parseQrPayload(raw);
    if (intent is! QrCompany) {
      error = 'El código no es un vínculo de empresa.';
      notifyListeners();
      return;
    }
    await _work(() async {
      session = await _sessions.redeem(intent.link);
      final remote = ecosystem;
      if (remote is CompanyBound) (remote as CompanyBound).companySession = session;
      status = session?.businessName;
    });
  }

  void addScheduled(ScheduledPayment payment) {
    scheduled = [...scheduled, payment];
    notifyListeners();
  }

  void addBeneficiary(Beneficiary beneficiary) {
    book = [...book.where((item) => item.id != beneficiary.id), beneficiary];
    notifyListeners();
  }

  Amount? _homeBalance() {
    final rows = balances.where((row) => row.token.key == ecosystem.homeStable.key).toList();
    return sumSameBook(rows);
  }

  Amount? _homeCost(TokenRef token, Amount amount) {
    if (token.key == ecosystem.homeStable.key) return amount;
    final rate = spot;
    if (rate == null) return null;
    if (token.kind == TokenKind.usdStable && view == ValuationView.usd) {
      return convertAtRate(amount: amount, rate: rate.rate, quoteDecimals: ecosystem.homeStable.decimals, ceil: true);
    }
    if (token.kind == TokenKind.usdStable) {
      return convertAtRate(amount: amount, rate: rate.rate, quoteDecimals: ecosystem.homeStable.decimals, ceil: true);
    }
    return null;
  }

  GuardResult _guard(Amount home, {required bool executable, required bool human}) {
    return evaluateMovement(
      policy: policy,
      homeBalance: _homeBalance() ?? Amount.zero(home.decimals),
      amountHome: home,
      scheduled: scheduled,
      ledger: day,
      nowUtc: _clock().toUtc(),
      liveMode: env.live,
      quoteExecutable: executable,
      humanConfirmed: human,
    );
  }

  Future<bool> _blocked(GuardResult guard) {
    ledger.add(LedgerEvent(
      at: _clock().toUtc(),
      kind: LedgerKind.guardBlock,
      flavor: flavor.id,
      ecosystemId: ecosystem.id,
      dryRun: !env.live,
      guardResult: guard.code,
      reason: 'Reserva ${guard.buffer.format()} · rotable ${guard.rotable.format()}',
    ));
    error = 'Control ${guard.code}';
    notifyListeners();
    return Future.value(false);
  }

  Future<bool> _propose(String reason, GuardResult guard, {Amount? home, List<PreparedTx>? steps}) async {
    lastAttribution = _attributionCode(steps);
    final tagged = _withAttribution(reason, steps);
    if (home != null && home.raw > BigInt.zero) {
      day = day.recordDryRun(dayKey: artDayKey(_clock().toUtc()), raw: home.raw);
      await store.write(DayLedger.storageKey, jsonEncode(day.toJson()));
    }
    ledger.add(LedgerEvent(
      at: _clock().toUtc(),
      kind: LedgerKind.propose,
      flavor: flavor.id,
      ecosystemId: ecosystem.id,
      dryRun: true,
      raw: home?.raw,
      decimals: home?.decimals,
      reason: tagged,
      guardResult: guard.code,
    ));
    status = tagged;
    notifyListeners();
    return true;
  }

  String? _attributionCode(List<PreparedTx>? steps) {
    for (final step in steps ?? const <PreparedTx>[]) {
      final code = step.attributionCode;
      if (code != null && code.isNotEmpty) return code;
    }
    return flavor.attributionCode;
  }

  String _withAttribution(String reason, List<PreparedTx>? steps) {
    final code = _attributionCode(steps);
    if (code == null) return reason;
    if (code.isEmpty) return '$reason · atribución pendiente';
    return '$reason · ERC-8021 $code';
  }

  AgentIdentity? _publishedIdentity(TreasuryEcosystem eco) {
    if (eco is! AgentDirectory) return null;
    return (eco as AgentDirectory).published;
  }

  Future<AgentIdentity?> _loadIdentity(TreasuryEcosystem eco) async {
    if (eco is! AgentDirectory) return null;
    return (eco as AgentDirectory).loadIdentity();
  }

  Future<bool> _sign(List<PreparedTx> steps, Amount home, String reason) async {
    if (signer.address == null) {
      error = 'Conectá la wallet. La app no firma sola.';
      notifyListeners();
      return false;
    }
    for (final step in steps) {
      final hash = await signer.send(step);
      day = day.recordLive(
        dayKey: artDayKey(_clock().toUtc()),
        caip2: step.chain.caip2,
        txHash: hash,
        raw: home.raw,
      );
      ledger.add(LedgerEvent(
        at: _clock().toUtc(),
        kind: LedgerKind.sign,
        flavor: flavor.id,
        ecosystemId: ecosystem.id,
        dryRun: false,
        caip2: step.chain.caip2,
        txHash: hash,
        raw: home.raw,
        decimals: home.decimals,
        reason: reason,
      ));
    }
    await store.write(DayLedger.storageKey, jsonEncode(day.toJson()));
    status = 'Firmado';
    notifyListeners();
    return true;
  }

  Future<void> _work(Future<void> Function() body) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      await body();
    } catch (error) {
      this.error = error.toString();
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
