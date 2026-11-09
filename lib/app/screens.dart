import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/amount.dart';
import '../core/guards.dart';
import '../core/model.dart';
import '../core/qr/qr_intent.dart';
import '../flavors/flavor_config.dart';
import '../l10n/app_localizations.dart';
import '../ui/desk.dart';
import '../ui/forms.dart';
import '../ui/theme.dart';
import 'controller.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.controller});
  final TreasuryController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final flavor = controller.flavor;
    final palette = flavor.palette;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final report = controller.report();
        final home = controller.ecosystem.homeStable;
        final usd = controller.usdBalance;
        final cap = controller.dailyCap;
        final spent = controller.dailySpent;
        final leftRaw = cap.raw - spent.raw;
        final remaining = Amount(raw: leftRaw < BigInt.zero ? BigInt.zero : leftRaw, decimals: cap.decimals);
        return SafeArea(
          child: RefreshIndicator(
            onRefresh: controller.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(FxSpace.l, FxSpace.s, FxSpace.l, FxSpace.xl),
              children: [
                DeskHeader(
                  palette: palette,
                  title: flavor.appName,
                  badge: controller.env.live ? l10n.liveMode : l10n.dryRun,
                  testnet: flavor.ecosystem.chains.any((chain) => chain.testnet),
                  testnetLabel: l10n.testnetBadge,
                  onRefresh: controller.refresh,
                ),
                const SizedBox(height: 10),
                DeskContext(
                  palette: palette,
                  layerLabel: l10n.contextLayer,
                  layer: l10n.navInicio,
                  networkLabel: l10n.contextNetwork,
                  network: home.chain.label,
                  networkOk: controller.error == null && controller.balances.isNotEmpty,
                  walletLabel: l10n.contextWallet,
                  wallet: shortAddress(controller.address, l10n.noWallet),
                  onWallet: controller.signer.address == null ? () => connectTreasuryWallet(context, controller) : null,
                ),
                if (controller.busy) const LinearProgressIndicator(),
                if (controller.error != null) _note(controller.error!),
                const SizedBox(height: 14),
                BalanceHero(
                  palette: palette,
                  title: l10n.homeBalanceTitle,
                  amount: controller.homeBalance,
                  symbol: home.symbol,
                  empty: l10n.homeEmpty,
                  usdLine: usd == null ? null : '${glance(usd)} ${controller.ecosystem.usdLeg.symbol}',
                  capLabel: l10n.dailyCapLeft,
                  remaining: remaining,
                  cap: cap,
                  progress: spentShare(spent, cap),
                ),
                const SizedBox(height: 14),
                Text(l10n.opsTitle, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                OperationGrid(palette: palette, actions: _deskActions(context, l10n)),
                const SizedBox(height: 16),
                Text(l10n.perChain, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ChainBooks(
                  palette: palette,
                  chains: flavor.ecosystem.chains,
                  balances: controller.balances,
                  empty: l10n.homeEmpty,
                  testnetBadge: l10n.testnetBadge,
                  note: l10n.chainSeparated,
                ),
                const SizedBox(height: 8),
                _WatchField(label: l10n.watchHint, initial: controller.watchAddress, onChanged: controller.setWatch),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(onPressed: controller.toggleView, child: Text(controller.view == ValuationView.home ? l10n.usdView : l10n.homeView)),
                ),
                _fxLine(l10n, palette),
                const SizedBox(height: 8),
                Text(l10n.pnl, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  report.sufficient ? '${l10n.reportHold}: ${report.vsHold?.format() ?? '0'}' : l10n.insufficientData,
                  style: TextStyle(color: palette.textMid),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<DeskAction> _deskActions(BuildContext context, AppLocalizations l10n) {
    return [
      DeskAction(icon: Icons.north_east, label: l10n.pay, hint: l10n.opPay, onTap: () => context.push('/caja/pagar')),
      DeskAction(icon: Icons.qr_code, label: l10n.collect, hint: l10n.opCollect, onTap: () => context.push('/caja/cobrar')),
      DeskAction(icon: Icons.swap_horiz, label: l10n.rotate, hint: l10n.opRotate, onTap: () => context.push('/caja/rotar')),
      DeskAction(icon: Icons.south_west, label: l10n.deposit, hint: l10n.opDeposit, onTap: () => context.push('/caja/depositar')),
    ];
  }

  Widget _fxLine(AppLocalizations l10n, BrandPalette palette) {
    final rate = controller.spot;
    final shown = FxRate.shown(
      base: rate?.base ?? '',
      quote: rate?.quote ?? '',
      rate: rate?.rate,
      source: rate?.source,
      at: rate?.at,
    );
    final text = shown == null ? l10n.noPrice : l10n.fxSource(shown.source, shown.at.toIso8601String());
    return Text(text, style: TextStyle(color: palette.textLow, fontSize: 12));
  }
}

class _WatchField extends StatefulWidget {
  const _WatchField({required this.label, required this.initial, required this.onChanged});

  final String label;
  final String initial;
  final ValueChanged<String> onChanged;

  @override
  State<_WatchField> createState() => _WatchFieldState();
}

class _WatchFieldState extends State<_WatchField> {
  late final TextEditingController field = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TreasuryTextField(
      label: widget.label,
      controller: field,
      onChanged: widget.onChanged,
    );
  }
}

class CajaPage extends StatelessWidget {
  const CajaPage({super.key, required this.controller});
  final TreasuryController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = controller.flavor.palette;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(FxSpace.l, FxSpace.s, FxSpace.l, FxSpace.xl),
            children: [
              DeskHeader(
                palette: palette,
                title: l10n.navCaja,
                badge: controller.env.live ? l10n.liveMode : l10n.dryRun,
                testnet: controller.flavor.ecosystem.chains.any((chain) => chain.testnet),
                testnetLabel: l10n.testnetBadge,
                onRefresh: controller.refresh,
              ),
              if (controller.status != null) ...[
                const SizedBox(height: 8),
                Text(controller.status!, style: TextStyle(color: palette.textMid)),
              ],
              if (controller.error != null) _note(controller.error!),
              const SizedBox(height: 14),
              Text(l10n.opsTitle, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              OperationList(
                palette: palette,
                actions: [
                  DeskAction(icon: Icons.north_east, label: l10n.pay, hint: l10n.opPay, onTap: () => context.push('/caja/pagar')),
                  DeskAction(icon: Icons.qr_code, label: l10n.collect, hint: l10n.opCollect, onTap: () => context.push('/caja/cobrar')),
                  DeskAction(icon: Icons.swap_horiz, label: l10n.rotate, hint: l10n.opRotate, onTap: () => context.push('/caja/rotar')),
                  DeskAction(icon: Icons.south_west, label: l10n.deposit, hint: l10n.opDeposit, onTap: () => context.push('/caja/depositar')),
                ],
              ),
              if (controller.ecosystem is YieldActions) ...[
                const SizedBox(height: 8),
                Text(l10n.yieldReserve, style: Theme.of(context).textTheme.titleMedium),
                Text(l10n.yieldDisclaimer, style: TextStyle(color: palette.textLow, fontSize: 12)),
                const SizedBox(height: 8),
                _AmountAction(label: l10n.vaultDeposit, action: controller.vaultDeposit),
                const SizedBox(height: 8),
                _AmountAction(label: l10n.vaultRedeem, action: controller.vaultRedeem),
              ],
              if (controller.ledger.events.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(l10n.decisions, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final event in controller.ledger.events.reversed.take(6))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '${event.kind.name} · ${event.reason ?? ''}',
                      style: TextStyle(color: palette.textMid),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class RotatePage extends StatefulWidget {
  const RotatePage({super.key, required this.controller});
  final TreasuryController controller;
  @override
  State<RotatePage> createState() => _RotatePageState();
}

class _RotatePageState extends State<RotatePage> {
  late TokenRef from;
  late TokenRef to;
  final amount = TextEditingController(text: '1');
  FxQuote? quote;

  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final eco = widget.controller.ecosystem;
    from = eco.homeStable;
    to = eco.usdLeg;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = widget.controller.ecosystem.tokens.where((token) => token.kind != TokenKind.gas).toList();
    final enabled = widget.controller.flavor.features.contains(Feature.fxSwap);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.rotate)),
      body: TreasuryFormBody(
        children: [
          if (!enabled) Text(l10n.featureOff),
          DropdownButton<TokenRef>(
            isExpanded: true,
            value: from,
            items: [for (final token in tokens) DropdownMenuItem(value: token, child: Text(_label(token)))],
            onChanged: (value) => setState(() => from = value ?? from),
          ),
          const SizedBox(height: FxSpace.xl),
          DropdownButton<TokenRef>(
            isExpanded: true,
            value: to,
            items: [for (final token in tokens) DropdownMenuItem(value: token, child: Text(_label(token)))],
            onChanged: (value) => setState(() => to = value ?? to),
          ),
          const SizedBox(height: FxSpace.xl),
          TreasuryTextField(
            label: l10n.amount,
            controller: amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: FxSpace.xxl),
          FilledButton(
            onPressed: () async {
              final result = await widget.controller.quote(from, to, amount.text);
              setState(() => quote = result);
            },
            child: Text(l10n.quote),
          ),
          _attributionLine(widget.controller, l10n),
          if (quote != null) ...[
            const SizedBox(height: 12),
            Text('${quote!.amountOut.format()} ${quote!.to.symbol}'),
            Text(quote!.executable ? quote!.venue : l10n.notExecutable),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () async {
                final ok = await widget.controller.confirmQuote(quote!);
                if (!context.mounted) return;
                setState(() {});
                _toast(context, ok ? l10n.registerDryRun : l10n.guardBlocked);
              },
              child: Text(widget.controller.env.live ? l10n.signSend : l10n.registerDryRun),
            ),
          ],
        ],
      ),
    );
  }
}

class PayPage extends StatefulWidget {
  const PayPage({super.key, required this.controller});
  final TreasuryController controller;
  @override
  State<PayPage> createState() => _PayPageState();
}

class _PayPageState extends State<PayPage> {
  final name = TextEditingController();
  final address = TextEditingController();
  final amount = TextEditingController(text: '1');
  final memo = TextEditingController();
  late TokenRef token;
  PaymentPlan? plan;

  @override
  void dispose() {
    name.dispose();
    address.dispose();
    amount.dispose();
    memo.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    token = widget.controller.ecosystem.usdLeg;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = widget.controller.ecosystem.tokens.where((item) => item.kind != TokenKind.gas && item.kind != TokenKind.yieldShare).toList();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.pay)),
      body: TreasuryFormBody(
        children: [
          Text(l10n.disclaimerCrossBorder),
          const SizedBox(height: FxSpace.xxl),
          TreasuryTextField(label: l10n.beneficiary, controller: name, textInputAction: TextInputAction.next),
          const SizedBox(height: FxSpace.xl),
          TreasuryTextField(label: l10n.address, controller: address, textInputAction: TextInputAction.next),
          const SizedBox(height: FxSpace.xl),
          TreasuryTextField(
            label: l10n.amount,
            controller: amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: FxSpace.xl),
          TreasuryTextField(label: l10n.memo, controller: memo),
          const SizedBox(height: FxSpace.xl),
          DropdownButton<TokenRef>(
            isExpanded: true,
            value: token,
            items: [for (final item in tokens) DropdownMenuItem(value: item, child: Text(_label(item)))],
            onChanged: (value) => setState(() => token = value ?? token),
          ),
          const SizedBox(height: FxSpace.xxl),
          FilledButton(
            onPressed: () async {
              final beneficiary = Beneficiary(
                id: address.text.trim().toLowerCase(),
                name: name.text.trim().isEmpty ? address.text.trim() : name.text.trim(),
                chain: token.chain,
                address: address.text.trim(),
                preferredToken: token,
                verified: false,
              );
              widget.controller.addBeneficiary(beneficiary);
              final drafted = await widget.controller.draftPayment(PaymentIntent(
                to: beneficiary,
                amount: Amount.parse(amount.text, token.decimals),
                token: token,
                memo: memo.text,
              ));
              setState(() => plan = drafted);
            },
            child: Text(l10n.quote),
          ),
          _attributionLine(widget.controller, l10n),
          if (plan != null) ...[
            const SizedBox(height: 12),
            Text('${l10n.costHome}: ${plan!.totalCostHome.format()}'),
            Text('${l10n.costUsd}: ${plan!.totalCostUsd.format()}'),
            Text(plan!.executable ? l10n.confirm : l10n.doubleConfirm),
            for (final leg in plan!.fxLegs) Text('${leg.from.symbol} → ${leg.to.symbol} ${leg.executable ? leg.venue : l10n.notExecutable}'),
            FilledButton(
              onPressed: () async {
                final ok = await widget.controller.confirmPayment(plan!);
                if (!context.mounted) return;
                setState(() {});
                _toast(context, ok ? l10n.registerDryRun : l10n.guardBlocked);
              },
              child: Text(widget.controller.env.live ? l10n.signSend : l10n.registerDryRun),
            ),
          ],
        ],
      ),
    );
  }
}

class CollectPage extends StatefulWidget {
  const CollectPage({super.key, required this.controller});
  final TreasuryController controller;
  @override
  State<CollectPage> createState() => _CollectPageState();
}

class _CollectPageState extends State<CollectPage> {
  final amount = TextEditingController(text: '1');
  PaymentRequest? request;

  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tracked = widget.controller.collectTracked();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.collect)),
      body: TreasuryFormBody(
        children: [
          TreasuryTextField(
            label: l10n.amount,
            controller: amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: FxSpace.xxl),
          FilledButton(
            onPressed: () async {
              final next = await widget.controller.collect(amount.text);
              setState(() => request = next);
            },
            child: Text(l10n.collect),
          ),
          if (request != null) _qr(request!.qrPayload),
          if (tracked != null) ...[
            const SizedBox(height: 12),
            Text(tracked.token.symbol),
            _qr(tracked.qrPayload),
          ],
        ],
      ),
    );
  }
}

class DepositPage extends StatelessWidget {
  const DepositPage({super.key, required this.controller});
  final TreasuryController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final account = controller.address ?? l10n.noWallet;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.deposit)),
      body: TreasuryFormBody(
        children: [
          Text(account),
          if (controller.address != null) _qr(controller.address!),
          const SizedBox(height: 12),
          for (final token in [controller.ecosystem.homeStable, controller.ecosystem.usdLeg])
            if (controller.address != null)
              ListTile(
                title: Text(_label(token)),
                subtitle: Text(eip681Transfer(
                  token: token.address,
                  chainReference: token.chain.reference,
                  to: controller.address!,
                  raw: BigInt.zero,
                ).toString()),
              ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () async {
              final option = (await controller.ecosystem.options(RampDirection.onRamp, controller.env.homeCurrency)).first;
              if (option.url != null) {
                await launchUrl(option.url!, mode: LaunchMode.externalApplication);
              } else if (context.mounted) {
                _toast(context, l10n.otcOnly);
              }
            },
            child: Text(l10n.onRamp),
          ),
        ],
      ),
    );
  }
}

class AgentPage extends StatefulWidget {
  const AgentPage({super.key, required this.controller});
  final TreasuryController controller;
  @override
  State<AgentPage> createState() => _AgentPageState();
}

class _AgentPageState extends State<AgentPage> {
  final prompt = TextEditingController();

  @override
  void dispose() {
    prompt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) => Scaffold(
        body: SafeArea(
          child: TreasuryFormBody(
            children: [
              Text(l10n.navAgente, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: FxSpace.s),
              Text(l10n.agentHint),
              _identityBlock(widget.controller, l10n),
              const SizedBox(height: 12),
              FilledButton(onPressed: widget.controller.daily, child: Text(l10n.dailyReview)),
              for (final note in widget.controller.dailyNotes) Text(note),
              const SizedBox(height: FxSpace.xxl),
              TreasuryTextField(label: l10n.memo, controller: prompt, minLines: 3, maxLines: 6),
              const SizedBox(height: FxSpace.xxl),
              FilledButton(
                onPressed: () async {
                  final text = prompt.text.trim();
                  if (text.isEmpty) return;
                  await widget.controller.confirmQuote(_chatQuote(widget.controller, text));
                },
                child: Text(l10n.proposalTitle),
              ),
              const SizedBox(height: FxSpace.xxl),
              Text(l10n.decisions, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: FxSpace.s),
              for (final event in widget.controller.ledger.events.reversed.take(12))
                Text('${event.kind.name} · ${event.reason ?? ''}'),
            ],
          ),
        ),
      ),
    );
  }
}

class MorePage extends StatefulWidget {
  const MorePage({super.key, required this.controller});
  final TreasuryController controller;

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  final link = TextEditingController();
  final supplier = TextEditingController();
  final due = TextEditingController(text: '2026-11-06');
  final amount = TextEditingController(text: '1000');

  TreasuryController get controller => widget.controller;

  @override
  void dispose() {
    link.dispose();
    supplier.dispose();
    due.dispose();
    amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Scaffold(
        body: SafeArea(
          child: TreasuryFormBody(
            children: [
              Text(l10n.navMas, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: FxSpace.s),
              Text(controller.env.live ? l10n.liveMode : l10n.dryRun),
              Text('${l10n.buffer}: ${controller.policy.liquidityBufferDays}'),
              Text('${controller.policy.homeCurrency} ${controller.policy.maxOpHome} / ${controller.policy.maxDailyHome}'),
              const SizedBox(height: 8),
              DropdownButton<Locale>(
                isExpanded: true,
                value: controller.locale ?? Localizations.localeOf(context),
                items: const [
                  DropdownMenuItem(value: Locale('es'), child: Text('Español')),
                  DropdownMenuItem(value: Locale('en'), child: Text('English')),
                  DropdownMenuItem(value: Locale('pt'), child: Text('Português')),
                ],
                onChanged: controller.setLocale,
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => connectTreasuryWallet(context, controller),
                child: Text(l10n.connectWallet),
              ),
              const SizedBox(height: FxSpace.s),
              Text(controller.signer.address ?? l10n.noWallet),
              const SizedBox(height: FxSpace.xxl),
              TreasuryTextField(label: l10n.companyLink, controller: link),
              const SizedBox(height: FxSpace.xxl),
              OutlinedButton(onPressed: () => controller.redeemLink(link.text), child: Text(l10n.save)),
              if (controller.session != null) ...[
                const SizedBox(height: FxSpace.s),
                Text(controller.session!.businessName),
              ],
              const SizedBox(height: 32),
              Text(l10n.scheduled, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: FxSpace.xl),
              TreasuryTextField(label: l10n.supplier, controller: supplier, textInputAction: TextInputAction.next),
              const SizedBox(height: FxSpace.xl),
              TreasuryTextField(
                label: l10n.dueDate,
                controller: due,
                keyboardType: TextInputType.datetime,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: FxSpace.xl),
              TreasuryTextField(
                label: l10n.amount,
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: FxSpace.xxl),
              OutlinedButton(
                onPressed: () {
                  controller.addScheduled(ScheduledPayment(
                    id: due.text,
                    supplier: supplier.text,
                    amountHome: Amount.parse(amount.text, controller.ecosystem.homeStable.decimals),
                    due: DateTime.parse(due.text),
                  ));
                },
                child: Text(l10n.addScheduled),
              ),
              const SizedBox(height: 32),
              OutlinedButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: controller.ledger.toCsv()));
                  _toast(context, l10n.copied);
                },
                child: Text(l10n.decisions),
              ),
              _identityBlock(controller, l10n),
            ],
          ),
        ),
      ),
    );
  }
}

class ScanPage extends StatefulWidget {
  const ScanPage({super.key, required this.controller});
  final TreasuryController controller;
  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final paste = TextEditingController();
  String? message;

  @override
  void dispose() {
    paste.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final platform = Theme.of(context).platform;
    final camera = platform == TargetPlatform.android || platform == TargetPlatform.iOS;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.scanAction)),
      body: Column(
        children: [
          if (camera)
            Expanded(
              child: MobileScanner(
                onDetect: (capture) {
                  final raw = capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue;
                  if (raw != null) _take(raw);
                },
              ),
            )
          else
            const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                TreasuryTextField(label: l10n.pasteCode, controller: paste),
                const SizedBox(height: FxSpace.xxl),
                FilledButton(onPressed: () => _take(paste.text), child: Text(l10n.save)),
                if (message != null) Text(message!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _take(String raw) {
    final intent = parseQrPayload(raw);
    if (intent is QrCompany) {
      widget.controller.redeemLink(raw);
      setState(() => message = intent.link.businessName ?? intent.link.apiBase);
      return;
    }
    if (intent is QrPay) {
      setState(() => message = intent.address);
      return;
    }
    setState(() => message = AppLocalizations.of(context).guardBlocked);
  }
}

Widget _attributionLine(TreasuryController controller, AppLocalizations l10n) {
  final code = controller.lastAttribution ?? controller.flavor.attributionCode;
  if (code == null) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text(code.isEmpty ? l10n.attributionMissing : l10n.attributionTagged(code)),
  );
}

Widget _identityBlock(TreasuryController controller, AppLocalizations l10n) {
  final identity = controller.agent;
  return Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (identity != null) ...[
          Text(
            identity.onChain
                ? '${l10n.agentId}: ${l10n.agentOnChain(identity.agentId!)}'
                : '${l10n.agentId}: ${l10n.agentUnregistered}',
          ),
          Text(identity.name),
          Text(identity.description),
          if (identity.agentUri != null && identity.agentUri!.isNotEmpty) Text(identity.agentUri!),
        ],
        _attributionLine(controller, l10n),
      ],
    ),
  );
}

Widget _qr(String data) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(child: QrImageView(data: data, size: 180, backgroundColor: Colors.white)),
    );

Widget _note(String text) => Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(text),
    );

String _label(TokenRef token) => '${token.symbol} · ${token.chain.label}';

void _toast(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

Future<void> connectTreasuryWallet(BuildContext context, TreasuryController controller) {
  final l10n = AppLocalizations.of(context);
  return controller.connect((uri) async {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.connectWallet),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(uri.toString()),
            QrImageView(data: uri.toString(), size: 180),
          ],
        ),
        actions: [
          TextButton(onPressed: () => launchUrl(uri, mode: LaunchMode.externalApplication), child: Text(l10n.openLink)),
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.close)),
        ],
      ),
    );
  });
}

class _AmountAction extends StatefulWidget {
  const _AmountAction({required this.label, required this.action});

  final String label;
  final Future<bool> Function(String human) action;

  @override
  State<_AmountAction> createState() => _AmountActionState();
}

class _AmountActionState extends State<_AmountAction> {
  final field = TextEditingController(text: '1');

  @override
  void dispose() {
    field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TreasuryTextField(
              label: AppLocalizations.of(context).amount,
              controller: field,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: FxSpace.xxl),
            FilledButton(onPressed: () => widget.action(field.text), child: Text(widget.label)),
          ],
        ),
      ),
    );
  }
}

FxQuote _chatQuote(TreasuryController controller, String text) {
  final home = controller.ecosystem.homeStable;
  final amount = Amount.zero(home.decimals);
  return FxQuote(
    id: 'chat',
    ecosystemId: controller.ecosystem.id,
    venue: 'chat',
    from: home,
    to: home,
    amountIn: amount,
    amountOut: amount,
    rate: '0',
    payload: NonExecutablePayload(text),
    dryRun: true,
  );
}
