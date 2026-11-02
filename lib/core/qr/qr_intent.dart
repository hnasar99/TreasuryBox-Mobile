import 'dart:convert';

import '../company_link.dart';

enum QrRejectReason { unknown, walletConnect, companyLink }

sealed class QrIntent {
  const QrIntent();
}

class QrPay extends QrIntent {
  const QrPay({
    required this.address,
    this.token,
    this.chainReference,
    this.amount,
    this.rawUnits = false,
  });

  final String address;
  final String? token;
  final String? chainReference;
  final String? amount;
  final bool rawUnits;
}

class QrCompany extends QrIntent {
  const QrCompany(this.link);
  final CompanyLinkPayload link;
}

class QrRejected extends QrIntent {
  const QrRejected(this.reason);
  final QrRejectReason reason;
}

QrIntent parseQrPayload(String raw) {
  final text = raw.trim();
  if (text.isEmpty || text.length > 2048) return const QrRejected(QrRejectReason.unknown);
  if (text.toLowerCase().startsWith('wc:')) {
    return const QrRejected(QrRejectReason.walletConnect);
  }
  if (text.startsWith('{')) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map) {
        final link = parseCompanyLinkMap(decoded);
        if (link != null) return QrCompany(link);
        final type = decoded['type']?.toString().toLowerCase();
        if (type == companyLinkType || type == 'company_link') {
          return const QrRejected(QrRejectReason.companyLink);
        }
      }
    } on FormatException {
      return const QrRejected(QrRejectReason.unknown);
    }
  }
  final uri = Uri.tryParse(text);
  if (uri != null && uri.scheme.toLowerCase() == 'ethereum') {
    return _eip681(text);
  }
  if (RegExp(r'^0x[0-9a-fA-F]{40}$').hasMatch(text)) {
    return QrPay(address: text);
  }
  return const QrRejected(QrRejectReason.unknown);
}

QrIntent _eip681(String raw) {
  final body = raw.substring('ethereum:'.length);
  final parts = body.split('?');
  final head = parts.first;
  final at = head.split('@');
  final token = at.first;
  final chain = at.length == 2 ? at[1].split('/').first : null;
  if (!RegExp(r'^0x[0-9a-fA-F]{40}$').hasMatch(token)) {
    return const QrRejected(QrRejectReason.unknown);
  }
  final query = parts.length == 2 ? Uri.splitQueryString(parts[1]) : const <String, String>{};
  final address = query['address'] ?? query['to'];
  if (address == null || !RegExp(r'^0x[0-9a-fA-F]{40}$').hasMatch(address)) {
    return const QrRejected(QrRejectReason.unknown);
  }
  final units = query['uint256'];
  return QrPay(
    address: address,
    token: token,
    chainReference: chain,
    amount: units ?? query['value'],
    rawUnits: units != null,
  );
}

Uri eip681Transfer({
  required String token,
  required String chainReference,
  required String to,
  required BigInt raw,
}) {
  return Uri.parse(
    'ethereum:$token@$chainReference/transfer?address=$to&uint256=$raw',
  );
}
