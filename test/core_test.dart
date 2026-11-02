import 'package:flutter_test/flutter_test.dart';
import 'package:treasurybox_mobile/core/amount.dart';
import 'package:treasurybox_mobile/core/company_link.dart';
import 'package:treasurybox_mobile/core/decimal.dart';
import 'package:treasurybox_mobile/core/eve_client.dart';
import 'package:treasurybox_mobile/core/guards.dart';
import 'package:treasurybox_mobile/core/model.dart';
import 'package:treasurybox_mobile/core/report.dart';

void main() {
  test('amounts keep 18 and 6 places as integers', () {
    final local = Amount.parse('1.5', 18);
    final usd = Amount.parse('1.5', 6);
    expect(local.format(), '1.5');
    expect(usd.format(), '1.5');
    expect(local.raw, BigInt.parse('1500000000000000000'));
    expect(usd.raw, BigInt.parse('1500000'));
    final home = convertAtRate(
      amount: Amount.parse('1', 6),
      rate: Decimal.parse('1000'),
      quoteDecimals: 18,
    );
    expect(home.format(), '1000');
    expect(() => Amount.parse('1e2', 6), throwsFormatException);
  });

  test('guards use the ART day, the buffer and deduped receipts', () {
    expect(artDayKey(DateTime.utc(2026, 11, 3, 2, 59)), '2026-11-02');
    expect(artDayKey(DateTime.utc(2026, 11, 3, 3)), '2026-11-03');
    final policy = TreasuryPolicy(
      homeCurrency: 'ARS',
      maxOpHome: Decimal.parse('1000'),
      maxDailyHome: Decimal.parse('1500'),
      liquidityBufferDays: 7,
      timeZone: 'America/Argentina/Buenos_Aires',
      inflationMonthlyPct: Decimal.parse('2.5'),
    );
    final now = DateTime.utc(2026, 11, 3, 15);
    final balance = Amount.parse('1000', 18);
    final scheduled = [
      ScheduledPayment(
        id: '1',
        supplier: 'a',
        amountHome: Amount.parse('400', 18),
        due: DateTime.utc(2026, 11, 4),
      ),
    ];
    final blocked = evaluateMovement(
      policy: policy,
      homeBalance: balance,
      amountHome: Amount.parse('700', 18),
      scheduled: scheduled,
      ledger: DayLedger.empty(artDayKey(now)),
      nowUtc: now,
      liveMode: false,
      quoteExecutable: true,
      humanConfirmed: false,
    );
    expect(blocked.ok, isFalse);
    expect(blocked.code, 'buffer');
    expect(blocked.rotable.format(), '600');

    final day = DayLedger.empty(artDayKey(now))
        .recordLive(dayKey: artDayKey(now), caip2: 'eip155:1', txHash: '0x${'ab' * 32}', raw: Amount.parse('1000', 18).raw)
        .recordLive(dayKey: artDayKey(now), caip2: 'eip155:1', txHash: '0x${'ab' * 32}', raw: Amount.parse('1000', 18).raw);
    expect(day.liveSpent, Amount.parse('1000', 18).raw);
    final dry = day.recordDryRun(dayKey: artDayKey(now), raw: Amount.parse('200', 18).raw);
    expect(dry.dryRunIntended, Amount.parse('200', 18).raw);
    expect(dry.liveSpent, day.liveSpent);
  });

  test('quotes and capped swaps are executable only inside the rules', () {
    final chain = ChainRef(namespace: 'eip155', reference: '1', testnet: false, label: '1');
    final token = TokenRef(symbol: 'LOCAL', address: '0x${'11' * 20}', decimals: 18, kind: TokenKind.localStable, chain: chain);
    FxQuote quote(QuotePayload payload, {DateTime? expires}) => FxQuote(
          id: 'q',
          ecosystemId: 'demo',
          venue: 'demo',
          from: token,
          to: token,
          amountIn: Amount.parse('1', 18),
          amountOut: Amount.parse('1', 18),
          rate: '1',
          payload: payload,
          dryRun: false,
          expiresAt: expires,
          clock: DateTime.utc(2026, 11, 2),
        );
    expect(quote(const NonExecutablePayload('preview')).executable, isFalse);
    expect(quote(const NonExecutablePayload('uniswap-stub')).executable, isFalse);
    expect(quote(const NonExecutablePayload('twin-fx-otc')).executable, isFalse);
    final inside = CappedSwapPayload(
      notionalUsd: Amount.parse('500', 6),
      spentTodayUsd: Amount.zero(6),
      slippageBps: 150,
      poolTvlUsd: Amount.parse('15000', 6),
    );
    expect(inside.executable, isTrue);
    expect(quote(inside).executable, isTrue);
    expect(
      CappedSwapPayload(
        notionalUsd: Amount.parse('500.000001', 6),
        spentTodayUsd: Amount.zero(6),
        slippageBps: 150,
        poolTvlUsd: Amount.parse('15000', 6),
      ).executable,
      isFalse,
    );
    expect(
      quote(inside, expires: DateTime.utc(2026, 11, 1)).executable,
      isFalse,
    );
    final leg = quote(const NonExecutablePayload('preview'));
    expect(quote(RoutePayload([leg])).executable, isFalse);
  });

  test('a payment plan fails closed and a collection rule never builds a transaction', () {
    final chain = ChainRef(namespace: 'eip155', reference: '1', testnet: false, label: '1');
    final token = TokenRef(symbol: 'LOCAL', address: '0x${'22' * 20}', decimals: 18, kind: TokenKind.localStable, chain: chain);
    final person = Beneficiary(
      id: '1',
      name: 'Ada',
      chain: chain,
      address: '0x${'33' * 20}',
      preferredToken: token,
      verified: false,
    );
    final intent = PaymentIntent(to: person, amount: Amount.parse('1', 18), token: token);
    final open = PaymentPlan(
      intent: intent,
      fxLegs: const [],
      steps: const [],
      totalCostHome: Amount.parse('1', 18),
      totalCostUsd: Amount.zero(6),
      expiresAt: DateTime.utc(2026, 11, 3),
      guardOk: true,
      now: DateTime.utc(2026, 11, 2),
    );
    expect(open.executable, isFalse);
    final confirmed = PaymentPlan(
      intent: PaymentIntent(to: person.copyWith(confirmations: 2), amount: intent.amount, token: token),
      fxLegs: const [],
      steps: const [],
      totalCostHome: Amount.parse('1', 18),
      totalCostUsd: Amount.zero(6),
      expiresAt: DateTime.utc(2026, 11, 3),
      guardOk: true,
      now: DateTime.utc(2026, 11, 2),
    );
    expect(confirmed.executable, isTrue);
    final expired = PaymentPlan(
      intent: PaymentIntent(to: person.copyWith(verified: true), amount: intent.amount, token: token),
      fxLegs: const [],
      steps: const [],
      totalCostHome: Amount.parse('1', 18),
      totalCostUsd: Amount.zero(6),
      expiresAt: DateTime.utc(2026, 11, 1),
      guardOk: true,
      now: DateTime.utc(2026, 11, 2),
    );
    expect(expired.executable, isFalse);
    final proposal = proposeAutoConvert(
      invoice: Invoice(
        id: 'inv',
        amount: Amount.parse('10', 6),
        token: token,
        link: Uri.parse('https://example.test/collect'),
        qr: Uri.parse('https://example.test/collect'),
      ),
      rule: const AutoConvertRule(pctBps: 3000),
    );
    expect(proposal.summary.contains('30%'), isTrue);
    expect(proposal.summary.contains('No se firma'), isTrue);
  });

  test('holding still is zero against hold, and a rate without a source is hidden', () {
    final start = Amount.parse('100', 18);
    final report = TreasuryReport.build(
      vStart: start,
      vEnd: start,
      flows: const [],
      inflationMonthlyPct: Decimal.parse('2.5'),
      periodStart: DateTime.utc(2026, 11, 1),
      periodEnd: DateTime.utc(2026, 11, 30),
    );
    expect(report.sufficient, isTrue);
    expect(report.vsHold!.raw, BigInt.zero);
    final moved = TreasuryReport.build(
      vStart: start,
      vEnd: Amount.parse('110', 18),
      flows: [FlowPoint(at: DateTime.utc(2026, 11, 15), amount: Amount.parse('10', 18))],
      inflationMonthlyPct: Decimal.parse('2.5'),
      periodStart: DateTime.utc(2026, 11, 1),
      periodEnd: DateTime.utc(2026, 11, 30),
    );
    expect(moved.vsHold!.raw, BigInt.zero);
    expect(TreasuryReport.build(vStart: null, vEnd: start, flows: const [], inflationMonthlyPct: Decimal.zero, periodStart: DateTime.utc(2026), periodEnd: DateTime.utc(2026, 2)).sufficient, isFalse);
    expect(FxRate.shown(base: 'LOCAL', quote: 'USD', rate: Decimal.parse('1'), source: '', at: DateTime.utc(2026)), isNull);
    expect(FxRate.shown(base: 'LOCAL', quote: 'USD', rate: Decimal.parse('1'), source: 'desk', at: null), isNull);
  });

  test('ndjson and company links parse only what the service sends', () {
    final events = parseNdjson('{"type":"text","text":"hola"}\n\n{"interactionId":"1"}\n');
    expect(events, hasLength(2));
    expect(events.first.text, 'hola');
    final link = parseCompanyLinkMap({
      'type': 'fluuix_company_link',
      'token': 'abcdabcdabcdabcd',
      'api_base': 'https://fluuix.com/functions/v1/ecosystem-api',
    });
    expect(link, isNotNull);
    expect(parseCompanyLinkMap({'type': 'fluuix_company_link', 'token': 'short', 'api_base': 'https://evil.test/functions/v1/ecosystem-api'}), isNull);
    expect(isAllowedEcosystemBase('http://localhost:54321/functions/v1/ecosystem-api'), isTrue);
    expect(isAllowedEcosystemBase('https://example.com/functions/v1/ecosystem-api'), isFalse);
  });

  test('books from different networks are not added', () {
    final mainnet = ChainRef(namespace: 'eip155', reference: '1', testnet: false, label: '1');
    final testnet = ChainRef(namespace: 'eip155', reference: '2', testnet: true, label: '2');
    TokenRef token(ChainRef chain) => TokenRef(symbol: 'LOCAL', address: '0x${'44' * 20}', decimals: 18, kind: TokenKind.localStable, chain: chain);
    final rows = [
      BalanceRow(token: token(mainnet), amount: Amount.parse('1', 18)),
      BalanceRow(token: token(testnet), amount: Amount.parse('2', 18)),
    ];
    expect(sumSameBook(rows), isNull);
    expect(sumSameBook([rows.first]), Amount.parse('1', 18));
  });
}
