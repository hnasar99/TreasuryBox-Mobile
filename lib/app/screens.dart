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
import '../ui/theme.dart';
import 'controller.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.controller});
  final TreasuryController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final flavor = controller.flavor;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final report = controller.report();
        return Scaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(FxSpace.l),
              children: [
                Text(flavor.appName, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(controller.env.live ? l10n.liveMode : l10n.dryRun),
                const SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(labelText: l10n.watchHint),
                  onChanged: controller.setWatch,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: FilledButton(onPressed: controller.refresh, child: Text(l10n.refresh))),
                    const SizedBox(width: 8),
                    OutlinedButton(onPressed: controller.toggleView, child: Text(controller.view == ValuationView.home ? l10n.usdView : l10n.homeView)),
                  ],
                ),
                if (controller.busy) const LinearProgressIndicator(),
                if (controller.error != null) _note(controller.error!),
                const SizedBox(height: 16),
                Text(l10n.perChain, style: Theme.of(context).textTheme.titleMedium),
                Text(l10n.chainSeparated),
                const SizedBox(height: 8),
                if (controller.balances.isEmpty) Text(l10n.homeEmpty),
                for (final chain in flavor.ecosystem.chains) _chainCard(context, chain, l10n),
                const SizedBox(height: 16),
                _fxLine(l10n),
                const SizedBox(height: 12),
                Text(l10n.pnl, style: Theme.of(context).textTheme.titleMedium),
                Text(report.sufficient ? '${l10n.reportHold}: ${report.vsHold?.format() ?? '0'}' : l10n.insufficientData),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _chainCard(BuildContext context, ChainRef chain, AppLocalizations l10n) {
    final rows = controller.balances.where((row) => row.token.chain.caip2 == chain.caip2).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${chain.label}${chain.testnet ? ' · ${l10n.testnetBadge}' : ''}'),
            for (final row in rows)
              Text('${row.token.symbol}  ${row.amount.format()}'),
            if (rows.isEmpty) Text(l10n.homeEmpty),
          ],
        ),
      ),
    );
  }

  Widget _fxLine(AppLocalizations l10n) {
    final rate = controller.spot;
    final shown = FxRate.shown(
      base: rate?.base ?? '',
      quote: rate?.quote ?? '',
      rate: rate?.rate,
      source: rate?.source,
      at: rate?.at,
    );
    if (shown == null) return Text(l10n.noPrice);
    return Text(l10n.fxSource(shown.source, shown.at.toIso8601String()));
  }
}

class CajaPage extends StatelessWidget {
  const CajaPage({super.key, required this.controller});
  final TreasuryController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(FxSpace.l),
            children: [
              Text(l10n.navCaja, style: Theme.of(context).textTheme.headlineSmall),
              if (controller.status != null) Text(controller.status!),
              if (controller.error != null) _note(controller.error!),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton(onPressed: () => context.push('/caja/rotar'), child: Text(l10n.rotate)),
                  FilledButton(onPressed: () => context.push('/caja/pagar'), child: Text(l10n.pay)),
                  FilledButton(onPressed: () => context.push('/caja/cobrar'), child: Text(l10n.collect)),
                  FilledButton(onPressed: () => context.push('/caja/depositar'), child: Text(l10n.deposit)),
                ],
              ),
              if (controller.ecosystem is YieldActions) ...[
                const SizedBox(height: 16),
                Text(l10n.yieldReserve, style: Theme.of(context).textTheme.titleMedium),
                Text(l10n.yieldDisclaimer),
                _AmountAction(label: l10n.vaultDeposit, action: controller.vaultDeposit),
                _AmountAction(label: l10n.vaultRedeem, action: controller.vaultRedeem),
              ],
            ],
          ),
        ),
      ),
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!enabled) Text(l10n.featureOff),
          DropdownButton<TokenRef>(
            isExpanded: true,
            value: from,
            items: [for (final token in tokens) DropdownMenuItem(value: token, child: Text(_label(token)))],
            onChanged: (value) => setState(() => from = value ?? from),
          ),
          DropdownButton<TokenRef>(
            isExpanded: true,
            value: to,
            items: [for (final token in tokens) DropdownMenuItem(value: token, child: Text(_label(token)))],
            onChanged: (value) => setState(() => to = value ?? to),
          ),
          TextField(controller: amount, decoration: InputDecoration(labelText: l10n.amount)),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () async {
              final result = await widget.controller.quote(from, to, amount.text);
              setState(() => quote = result);
            },
            child: Text(l10n.quote),
          ),
          if (quote != null) ...[
            const SizedBox(height: 12),
            Text('${quote!.amountOut.format()} ${quote!.to.symbol}'),
            Text(quote!.executable ? quote!.venue : l10n.notExecutable),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () async {
                final ok = await widget.controller.confirmQuote(quote!);
                if (context.mounted) _toast(context, ok ? l10n.registerDryRun : l10n.guardBlocked);
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.disclaimerCrossBorder),
          TextField(controller: name, decoration: InputDecoration(labelText: l10n.beneficiary)),
          TextField(controller: address, decoration: InputDecoration(labelText: l10n.address)),
          TextField(controller: amount, decoration: InputDecoration(labelText: l10n.amount)),
          TextField(controller: memo, decoration: InputDecoration(labelText: l10n.memo)),
          DropdownButton<TokenRef>(
            isExpanded: true,
            value: token,
            items: [for (final item in tokens) DropdownMenuItem(value: item, child: Text(_label(item)))],
            onChanged: (value) => setState(() => token = value ?? token),
          ),
          const SizedBox(height: 12),
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
          if (plan != null) ...[
            const SizedBox(height: 12),
            Text('${l10n.costHome}: ${plan!.totalCostHome.format()}'),
            Text('${l10n.costUsd}: ${plan!.totalCostUsd.format()}'),
            Text(plan!.executable ? l10n.confirm : l10n.doubleConfirm),
            for (final leg in plan!.fxLegs) Text('${leg.from.symbol} → ${leg.to.symbol} ${leg.executable ? leg.venue : l10n.notExecutable}'),
            FilledButton(
              onPressed: () async {
                final ok = await widget.controller.confirmPayment(plan!);
                if (context.mounted) _toast(context, ok ? l10n.registerDryRun : l10n.guardBlocked);
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: amount, decoration: InputDecoration(labelText: l10n.amount)),
          const SizedBox(height: 12),
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
      body: ListView(
        padding: const EdgeInsets.all(16),
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
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(l10n.navAgente, style: Theme.of(context).textTheme.headlineSmall),
              Text(l10n.agentHint),
              const SizedBox(height: 12),
              FilledButton(onPressed: widget.controller.daily, child: Text(l10n.dailyReview)),
              for (final note in widget.controller.dailyNotes) Text(note),
              const SizedBox(height: 12),
              TextField(controller: prompt, decoration: InputDecoration(labelText: l10n.memo)),
              FilledButton(
                onPressed: () async {
                  final text = prompt.text.trim();
                  if (text.isEmpty) return;
                  await widget.controller.confirmQuote(_chatQuote(widget.controller, text));
                },
                child: Text(l10n.proposalTitle),
              ),
              const SizedBox(height: 12),
              Text(l10n.decisions),
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
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(l10n.navMas, style: Theme.of(context).textTheme.headlineSmall),
              Text(controller.env.live ? l10n.liveMode : l10n.dryRun),
              Text('${l10n.buffer}: ${controller.policy.liquidityBufferDays}'),
              Text('${controller.policy.homeCurrency} ${controller.policy.maxOpHome} / ${controller.policy.maxDailyHome}'),
              const SizedBox(height: 8),
              DropdownButton<Locale>(
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
                onPressed: () => controller.connect((uri) async {
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
                }),
                child: Text(l10n.connectWallet),
              ),
              Text(controller.signer.address ?? l10n.noWallet),
              const SizedBox(height: 12),
              TextField(controller: link, decoration: InputDecoration(labelText: l10n.companyLink)),
              OutlinedButton(onPressed: () => controller.redeemLink(link.text), child: Text(l10n.save)),
              Text(controller.session?.businessName ?? ''),
              const SizedBox(height: 12),
              Text(l10n.scheduled),
              TextField(controller: supplier, decoration: InputDecoration(labelText: l10n.supplier)),
              TextField(controller: due, decoration: InputDecoration(labelText: l10n.dueDate)),
              TextField(controller: amount, decoration: InputDecoration(labelText: l10n.amount)),
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
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: controller.ledger.toCsv()));
                  _toast(context, l10n.copied);
                },
                child: Text(l10n.decisions),
              ),
              Text('${l10n.agentId}: TODO(verify)'),
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
            SizedBox(
              height: 240,
              child: MobileScanner(
                onDetect: (capture) {
                  final raw = capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue;
                  if (raw != null) _take(raw);
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(controller: paste, decoration: InputDecoration(labelText: l10n.pasteCode)),
                const SizedBox(height: 8),
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
    return Row(
      children: [
        Expanded(child: TextField(controller: field)),
        const SizedBox(width: 8),
        FilledButton(onPressed: () => widget.action(field.text), child: Text(widget.label)),
      ],
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
