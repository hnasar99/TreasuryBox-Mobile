// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navInicio => 'Home';

  @override
  String get navCaja => 'Treasury';

  @override
  String get navAgente => 'Agent';

  @override
  String get navMas => 'More';

  @override
  String get scanAction => 'Scan';

  @override
  String get balances => 'Balances';

  @override
  String get quote => 'Quote';

  @override
  String get rotate => 'Rotate';

  @override
  String get collect => 'Collect';

  @override
  String get pay => 'Pay';

  @override
  String get pnl => 'Result';

  @override
  String get dryRun => 'Dry run';

  @override
  String get liveMode => 'Live';

  @override
  String get buffer => 'Buffer';

  @override
  String get rotable => 'Rotable';

  @override
  String get decisions => 'Decisions';

  @override
  String get yieldReserve => 'Yield position';

  @override
  String get yieldDisclaimer =>
      'This yield is on the local asset. There is no verified rate.';

  @override
  String get noPrice => 'No price';

  @override
  String fxSource(String source, String at) {
    return 'Source $source · $at';
  }

  @override
  String get perChain => 'By network';

  @override
  String get proposalTitle => 'Proposal';

  @override
  String get confirm => 'Confirm';

  @override
  String get reject => 'Reject';

  @override
  String get costHome => 'Cost in local currency';

  @override
  String get costUsd => 'Cost in USD';

  @override
  String get notExecutable => 'No executable quote';

  @override
  String get guardBlocked => 'The movement fails the controls';

  @override
  String get connectWallet => 'Connect wallet';

  @override
  String get dailyReview => 'Daily review';

  @override
  String get deposit => 'Deposit';

  @override
  String get beneficiary => 'Beneficiary';

  @override
  String get disclaimerCrossBorder =>
      'The company signs with its wallet. This app does not custody funds and is not regulatory advice.';

  @override
  String get modeLocal => 'Local mode';

  @override
  String get insufficientData => 'Not enough data';

  @override
  String get doubleConfirm =>
      'First payment to this beneficiary: confirm once more.';

  @override
  String get testnetBadge => 'TESTNET';

  @override
  String get contextLayer => 'Layer';

  @override
  String get contextNetwork => 'Network';

  @override
  String get contextRail => 'Rail';

  @override
  String get contextWallet => 'Wallet';

  @override
  String get usdView => 'USD';

  @override
  String get homeView => 'Local';

  @override
  String get agentHint => 'The agent proposes. It does not sign or approve.';

  @override
  String get refresh => 'Refresh';

  @override
  String get amount => 'Amount';

  @override
  String get address => 'Address';

  @override
  String get watchHint => 'Address used to read balances';

  @override
  String get registerDryRun => 'Record dry run';

  @override
  String get signSend => 'Sign and send';

  @override
  String get language => 'Language';

  @override
  String get pasteCode => 'Paste code';

  @override
  String get openLink => 'Open link';

  @override
  String get noWallet => 'No wallet';

  @override
  String get homeEmpty => 'No balances read yet.';

  @override
  String get scheduled => 'Scheduled payments';

  @override
  String get addScheduled => 'Schedule payment';

  @override
  String get supplier => 'Supplier';

  @override
  String get dueDate => 'Due date';

  @override
  String get memo => 'Note';

  @override
  String get invoiceRef => 'Invoice';

  @override
  String get country => 'Country';

  @override
  String get verified => 'Verified';

  @override
  String get save => 'Save';

  @override
  String get close => 'Close';

  @override
  String get slippage => 'Slippage';

  @override
  String get expires => 'Expires';

  @override
  String get warnings => 'Warnings';

  @override
  String get steps => 'Steps';

  @override
  String get agentId => 'Agent identity';

  @override
  String get agentUnregistered => 'Not registered on-chain';

  @override
  String agentOnChain(String id) {
    return 'agentId $id';
  }

  @override
  String attributionTagged(String code) {
    return 'ERC-8021 $code';
  }

  @override
  String get attributionMissing => 'Attribution code is missing';

  @override
  String get companyLink => 'Company link';

  @override
  String get clearSession => 'Sign out of the company';

  @override
  String get projectId => 'Wallet project ID';

  @override
  String get rampOut => 'Cash out with a provider';

  @override
  String get onRamp => 'Cash in with a provider';

  @override
  String get otcOnly =>
      'Operator instructions only. This app does not call that API.';

  @override
  String get featureOff => 'This action is off in this build.';

  @override
  String get copied => 'Ready to share';

  @override
  String get reportHold => 'Versus holding';

  @override
  String get reportInflation => 'Versus inflation';

  @override
  String get chainSeparated => 'Totals are not added across networks.';

  @override
  String get vaultDeposit => 'Set aside';

  @override
  String get vaultRedeem => 'Withdraw';

  @override
  String get homeBalanceTitle => 'Balance';

  @override
  String get dailyCapLeft => 'Left today';

  @override
  String get opsTitle => 'Operations';

  @override
  String get opPay => 'Send to a beneficiary';

  @override
  String get opCollect => 'Collect with a QR';

  @override
  String get opRotate => 'Move between local and USD';

  @override
  String get opDeposit => 'Show the address and bring funds in';
}
