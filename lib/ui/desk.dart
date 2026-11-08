import 'package:flutter/material.dart';

import '../core/amount.dart';
import '../core/model.dart';
import 'theme.dart';

/// Share of [spent] inside [cap], for a progress bar. Money stays in [Amount].
double spentShare(Amount spent, Amount cap) {
  if (cap.raw <= BigInt.zero || spent.raw <= BigInt.zero) return 0;
  if (spent.raw >= cap.raw) return 1;
  final millis = (spent.raw * BigInt.from(1000)) ~/ cap.raw;
  return millis.toInt() / 1000;
}

String shortAddress(String? address, String fallback) {
  if (address == null || address.length < 12) return fallback;
  return '${address.substring(0, 6)}…${address.substring(address.length - 4)}';
}

String glance(Amount amount) => amount.format(places: amount.decimals > 6 ? 6 : amount.decimals);

class DeskHeader extends StatelessWidget {
  const DeskHeader({
    super.key,
    required this.palette,
    required this.title,
    required this.badge,
    required this.testnet,
    required this.testnetLabel,
    required this.onRefresh,
  });

  final BrandPalette palette;
  final String title;
  final String badge;
  final bool testnet;
  final String testnetLabel;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        Row(
          children: [
            _chip(badge, palette.accentText, palette.surfaceHigh),
            if (testnet) ...[
              const SizedBox(width: 6),
              _chip(testnetLabel, palette.onAccent, palette.accent),
            ],
            const Spacer(),
            IconButton(
              tooltip: MaterialLocalizations.of(context).refreshIndicatorSemanticLabel,
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ],
    );
  }

  Widget _chip(String text, Color foreground, Color background) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: foreground),
      ),
    );
  }
}

class DeskContext extends StatelessWidget {
  const DeskContext({
    super.key,
    required this.palette,
    required this.layerLabel,
    required this.layer,
    required this.networkLabel,
    required this.network,
    required this.networkOk,
    required this.walletLabel,
    required this.wallet,
    this.onWallet,
  });

  final BrandPalette palette;
  final String layerLabel;
  final String layer;
  final String networkLabel;
  final String network;
  final bool networkOk;
  final String walletLabel;
  final String wallet;
  final VoidCallback? onWallet;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.outline),
      ),
      child: Row(
        children: [
          Expanded(child: _cell(context, layerLabel, layer, valueColor: palette.accentText)),
          const SizedBox(width: 6),
          Expanded(child: _cell(context, networkLabel, network, dot: networkOk)),
          const SizedBox(width: 6),
          Expanded(
            child: _cell(context, walletLabel, wallet, onTap: onWallet),
          ),
        ],
      ),
    );
  }

  Widget _cell(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
    bool? dot,
    VoidCallback? onTap,
  }) {
    final body = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: palette.surfaceHigh,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 9, letterSpacing: 0.4, color: palette.textLow),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              if (dot != null) ...[
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: dot ? palette.accent : palette.textLow,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? palette.textHi,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (onTap == null) return body;
    return GestureDetector(onTap: onTap, child: body);
  }
}

class BalanceHero extends StatelessWidget {
  const BalanceHero({
    super.key,
    required this.palette,
    required this.title,
    required this.amount,
    required this.symbol,
    required this.empty,
    required this.usdLine,
    required this.capLabel,
    required this.remaining,
    required this.cap,
    required this.progress,
  });

  final BrandPalette palette;
  final String title;
  final Amount? amount;
  final String symbol;
  final String empty;
  final String? usdLine;
  final String capLabel;
  final Amount remaining;
  final Amount cap;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(FxSpace.l),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(FxRadius.card),
        border: Border.all(color: palette.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 13, color: palette.textMid)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  amount == null ? '—' : glance(amount!),
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: palette.textHi,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                symbol,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: palette.accentText),
              ),
            ],
          ),
          if (amount == null) ...[
            const SizedBox(height: 4),
            Text(empty, style: TextStyle(color: palette.textLow, fontSize: 12)),
          ],
          if (usdLine != null) ...[
            const SizedBox(height: 4),
            Text(usdLine!, style: TextStyle(color: palette.textMid, fontSize: 13)),
          ],
          const SizedBox(height: 12),
          Text(
            '$capLabel  ${glance(remaining)} / ${cap.format(places: 0)}',
            style: TextStyle(fontSize: 12, color: palette.textLow),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: palette.outline,
              color: palette.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class DeskAction {
  const DeskAction({required this.icon, required this.label, required this.onTap, this.hint});

  final IconData icon;
  final String label;
  final String? hint;
  final VoidCallback onTap;
}

class OperationGrid extends StatelessWidget {
  const OperationGrid({super.key, required this.palette, required this.actions});

  final BrandPalette palette;
  final List<DeskAction> actions;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < actions.length; i += 2) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 8));
      final right = i + 1 < actions.length ? actions[i + 1] : null;
      rows.add(
        Row(
          children: [
            Expanded(child: _tile(context, actions[i])),
            const SizedBox(width: 8),
            Expanded(child: right == null ? const SizedBox.shrink() : _tile(context, right)),
          ],
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _tile(BuildContext context, DeskAction action) {
    return Material(
      color: palette.surfaceHigh,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              Icon(action.icon, color: palette.accentText),
              const SizedBox(height: 8),
              Text(action.label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class OperationList extends StatelessWidget {
  const OperationList({super.key, required this.palette, required this.actions});

  final BrandPalette palette;
  final List<DeskAction> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final action in actions) ...[
          Material(
            color: palette.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(FxRadius.card),
              side: BorderSide(color: palette.outline),
            ),
            child: ListTile(
              leading: Icon(action.icon, color: palette.accentText),
              title: Text(action.label),
              subtitle: action.hint == null ? null : Text(action.hint!),
              trailing: Icon(Icons.chevron_right, color: palette.textLow),
              onTap: action.onTap,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class ChainBooks extends StatelessWidget {
  const ChainBooks({
    super.key,
    required this.palette,
    required this.chains,
    required this.balances,
    required this.empty,
    required this.testnetBadge,
    required this.note,
  });

  final BrandPalette palette;
  final List<ChainRef> chains;
  final List<BalanceRow> balances;
  final String empty;
  final String testnetBadge;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(note, style: TextStyle(color: palette.textLow, fontSize: 12)),
        const SizedBox(height: 8),
        for (final chain in chains) ...[
          _card(context, chain),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _card(BuildContext context, ChainRef chain) {
    final rows = balances.where((row) {
      if (row.token.chain.caip2 != chain.caip2) return false;
      if (row.token.kind == TokenKind.gas && row.amount.raw == BigInt.zero) return false;
      return true;
    }).toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(FxRadius.card),
        border: Border.all(color: palette.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${chain.label}${chain.testnet ? ' · $testnetBadge' : ''}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          if (rows.isEmpty)
            Text(empty, style: TextStyle(color: palette.textLow, fontSize: 13))
          else
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(row.token.symbol)),
                    Text(
                      glance(row.amount),
                      style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
