const companyLinkType = 'fluuix_company_link';

abstract interface class CompanyBound {
  set companySession(EcosystemSession? value);
}

class CompanyLinkPayload {
  const CompanyLinkPayload({
    required this.token,
    required this.apiBase,
    this.businessId,
    this.businessName,
    this.portal,
    this.expiresAt,
  });

  final String token;
  final String apiBase;
  final String? businessId;
  final String? businessName;
  final String? portal;
  final DateTime? expiresAt;
}

class EcosystemSession {
  const EcosystemSession({
    required this.apiBase,
    required this.supabaseUrl,
    required this.anonKey,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.businessId,
    required this.businessName,
    this.email,
    this.portal,
  });

  final String apiBase;
  final String supabaseUrl;
  final String anonKey;
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final String businessId;
  final String businessName;
  final String? email;
  final String? portal;

  bool get expired => DateTime.now().isAfter(expiresAt.subtract(const Duration(seconds: 30)));

  EcosystemSession copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
  }) {
    return EcosystemSession(
      apiBase: apiBase,
      supabaseUrl: supabaseUrl,
      anonKey: anonKey,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
      businessId: businessId,
      businessName: businessName,
      email: email,
      portal: portal,
    );
  }

  Map<String, dynamic> toJson() => {
        'api_base': apiBase,
        'supabase_url': supabaseUrl,
        'anon_key': anonKey,
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'expires_at': expiresAt.toIso8601String(),
        'business_id': businessId,
        'business_name': businessName,
        'email': email,
        'portal': portal,
      };

  factory EcosystemSession.fromJson(Map<String, dynamic> json) {
    final apiBase = json['api_base']?.toString() ?? '';
    final supabaseUrl = json['supabase_url']?.toString() ?? '';
    final anonKey = json['anon_key']?.toString() ?? '';
    final access = json['access_token']?.toString() ?? '';
    final refresh = json['refresh_token']?.toString() ?? '';
    final businessId = json['business_id']?.toString() ?? '';
    if (!isAllowedEcosystemBase(apiBase) ||
        !isAllowedSupabaseUrl(supabaseUrl) ||
        access.isEmpty ||
        refresh.isEmpty ||
        businessId.isEmpty) {
      throw const FormatException('Stored company session is invalid.');
    }
    return EcosystemSession(
      apiBase: apiBase,
      supabaseUrl: supabaseUrl,
      anonKey: anonKey,
      accessToken: access,
      refreshToken: refresh,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      businessId: businessId,
      businessName: json['business_name']?.toString() ?? '',
      email: json['email']?.toString(),
      portal: json['portal']?.toString(),
    );
  }
}

bool isAllowedEcosystemBase(String raw) {
  final uri = Uri.tryParse(raw.trim());
  if (uri == null || uri.userInfo.isNotEmpty || uri.hasFragment) return false;
  final path = uri.path.replaceAll(RegExp(r'/+$'), '');
  if (path != '/functions/v1/ecosystem-api') return false;
  return _allowedHost(uri);
}

bool isAllowedSupabaseUrl(String raw) {
  final uri = Uri.tryParse(raw.trim());
  if (uri == null || uri.userInfo.isNotEmpty || uri.hasFragment) return false;
  if (uri.path.isNotEmpty && uri.path != '/') return false;
  return _allowedHost(uri);
}

bool _allowedHost(Uri uri) {
  final host = uri.host.toLowerCase();
  if (host == '127.0.0.1' || host == 'localhost') {
    return uri.scheme == 'http' && (!uri.hasPort || uri.port == 54321);
  }
  if (uri.scheme != 'https') return false;
  if (host == 'fluuix.com' || host.endsWith('.fluuix.com')) return true;
  return host.endsWith('.supabase.co');
}

bool isCompanyLinkToken(String token) => RegExp(r'^[a-fA-F0-9]{16,128}$').hasMatch(token.trim());

CompanyLinkPayload? parseCompanyLinkMap(Map<dynamic, dynamic> json) {
  final type = json['type']?.toString().trim().toLowerCase();
  if (type != companyLinkType && type != 'company_link') return null;
  final token = json['token']?.toString().trim() ?? '';
  final apiBase = json['api_base']?.toString().trim() ?? '';
  if (!isCompanyLinkToken(token) || !isAllowedEcosystemBase(apiBase)) return null;
  DateTime? expires;
  final rawExpires = json['expires_at']?.toString();
  if (rawExpires != null && rawExpires.isNotEmpty) expires = DateTime.tryParse(rawExpires);
  return CompanyLinkPayload(
    token: token,
    apiBase: apiBase,
    businessId: json['business_id']?.toString(),
    businessName: json['business_name']?.toString(),
    portal: json['portal']?.toString(),
    expiresAt: expires,
  );
}
