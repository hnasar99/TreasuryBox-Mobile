class AppEnv {
  const AppEnv({
    required this.mode,
    required this.homeCurrency,
    required this.maxOpAmount,
    required this.maxDailyAmount,
    required this.bufferDays,
    required this.inflationMonthlyPct,
    required this.timeZone,
    required this.eveUrl,
    required this.treasuryApiUrl,
    required this.walletConnectProjectId,
  });

  final String mode;
  final String homeCurrency;
  final String maxOpAmount;
  final String maxDailyAmount;
  final String bufferDays;
  final String inflationMonthlyPct;
  final String timeZone;
  final String eveUrl;
  final String treasuryApiUrl;
  final String walletConnectProjectId;

  bool get live => mode.toLowerCase() == 'live';

  static const current = AppEnv(
    mode: String.fromEnvironment('TREASURY_MODE', defaultValue: 'dry-run'),
    homeCurrency: String.fromEnvironment('HOME_CURRENCY', defaultValue: 'ARS'),
    maxOpAmount: String.fromEnvironment('MAX_OP_AMOUNT', defaultValue: '100000'),
    maxDailyAmount: String.fromEnvironment('MAX_DAILY_AMOUNT', defaultValue: '500000'),
    bufferDays: String.fromEnvironment('LIQUIDITY_BUFFER_DAYS', defaultValue: '7'),
    inflationMonthlyPct: String.fromEnvironment('INFLATION_MONTHLY_PCT', defaultValue: '2.5'),
    timeZone: String.fromEnvironment(
      'TREASURY_TIME_ZONE',
      defaultValue: 'America/Argentina/Buenos_Aires',
    ),
    eveUrl: String.fromEnvironment('EVE_URL'),
    treasuryApiUrl: String.fromEnvironment('TREASURY_API_URL'),
    walletConnectProjectId: String.fromEnvironment('WALLETCONNECT_PROJECT_ID'),
  );
}
