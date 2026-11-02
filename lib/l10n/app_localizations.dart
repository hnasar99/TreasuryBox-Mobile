import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt'),
  ];

  /// No description provided for @navInicio.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get navInicio;

  /// No description provided for @navCaja.
  ///
  /// In es, this message translates to:
  /// **'Caja'**
  String get navCaja;

  /// No description provided for @navAgente.
  ///
  /// In es, this message translates to:
  /// **'Agente'**
  String get navAgente;

  /// No description provided for @navMas.
  ///
  /// In es, this message translates to:
  /// **'Más'**
  String get navMas;

  /// No description provided for @scanAction.
  ///
  /// In es, this message translates to:
  /// **'Escanear'**
  String get scanAction;

  /// No description provided for @balances.
  ///
  /// In es, this message translates to:
  /// **'Saldos'**
  String get balances;

  /// No description provided for @quote.
  ///
  /// In es, this message translates to:
  /// **'Cotizar'**
  String get quote;

  /// No description provided for @rotate.
  ///
  /// In es, this message translates to:
  /// **'Rotar'**
  String get rotate;

  /// No description provided for @collect.
  ///
  /// In es, this message translates to:
  /// **'Cobrar'**
  String get collect;

  /// No description provided for @pay.
  ///
  /// In es, this message translates to:
  /// **'Pagar'**
  String get pay;

  /// No description provided for @pnl.
  ///
  /// In es, this message translates to:
  /// **'Resultado'**
  String get pnl;

  /// No description provided for @dryRun.
  ///
  /// In es, this message translates to:
  /// **'Simulación'**
  String get dryRun;

  /// No description provided for @liveMode.
  ///
  /// In es, this message translates to:
  /// **'En vivo'**
  String get liveMode;

  /// No description provided for @buffer.
  ///
  /// In es, this message translates to:
  /// **'Reserva'**
  String get buffer;

  /// No description provided for @rotable.
  ///
  /// In es, this message translates to:
  /// **'Rotable'**
  String get rotable;

  /// No description provided for @decisions.
  ///
  /// In es, this message translates to:
  /// **'Decisiones'**
  String get decisions;

  /// No description provided for @yieldReserve.
  ///
  /// In es, this message translates to:
  /// **'Posición con rendimiento'**
  String get yieldReserve;

  /// No description provided for @yieldDisclaimer.
  ///
  /// In es, this message translates to:
  /// **'Es rendimiento sobre el activo local. No hay una tasa verificada.'**
  String get yieldDisclaimer;

  /// No description provided for @noPrice.
  ///
  /// In es, this message translates to:
  /// **'Sin precio'**
  String get noPrice;

  /// No description provided for @fxSource.
  ///
  /// In es, this message translates to:
  /// **'Fuente {source} · {at}'**
  String fxSource(String source, String at);

  /// No description provided for @perChain.
  ///
  /// In es, this message translates to:
  /// **'Por red'**
  String get perChain;

  /// No description provided for @proposalTitle.
  ///
  /// In es, this message translates to:
  /// **'Propuesta'**
  String get proposalTitle;

  /// No description provided for @confirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get confirm;

  /// No description provided for @reject.
  ///
  /// In es, this message translates to:
  /// **'Rechazar'**
  String get reject;

  /// No description provided for @costHome.
  ///
  /// In es, this message translates to:
  /// **'Costo en moneda local'**
  String get costHome;

  /// No description provided for @costUsd.
  ///
  /// In es, this message translates to:
  /// **'Costo en USD'**
  String get costUsd;

  /// No description provided for @notExecutable.
  ///
  /// In es, this message translates to:
  /// **'Sin cotización ejecutable'**
  String get notExecutable;

  /// No description provided for @guardBlocked.
  ///
  /// In es, this message translates to:
  /// **'El movimiento no pasa los controles'**
  String get guardBlocked;

  /// No description provided for @connectWallet.
  ///
  /// In es, this message translates to:
  /// **'Conectar wallet'**
  String get connectWallet;

  /// No description provided for @dailyReview.
  ///
  /// In es, this message translates to:
  /// **'Repaso diario'**
  String get dailyReview;

  /// No description provided for @deposit.
  ///
  /// In es, this message translates to:
  /// **'Depositar'**
  String get deposit;

  /// No description provided for @beneficiary.
  ///
  /// In es, this message translates to:
  /// **'Beneficiario'**
  String get beneficiary;

  /// No description provided for @disclaimerCrossBorder.
  ///
  /// In es, this message translates to:
  /// **'La empresa firma con su wallet. Esta app no custodia fondos ni es asesoramiento regulatorio.'**
  String get disclaimerCrossBorder;

  /// No description provided for @modeLocal.
  ///
  /// In es, this message translates to:
  /// **'Modo local'**
  String get modeLocal;

  /// No description provided for @insufficientData.
  ///
  /// In es, this message translates to:
  /// **'Sin datos suficientes'**
  String get insufficientData;

  /// No description provided for @doubleConfirm.
  ///
  /// In es, this message translates to:
  /// **'Primer pago a este beneficiario: confirmá otra vez.'**
  String get doubleConfirm;

  /// No description provided for @testnetBadge.
  ///
  /// In es, this message translates to:
  /// **'TESTNET'**
  String get testnetBadge;

  /// No description provided for @contextLayer.
  ///
  /// In es, this message translates to:
  /// **'Capa'**
  String get contextLayer;

  /// No description provided for @contextNetwork.
  ///
  /// In es, this message translates to:
  /// **'Red'**
  String get contextNetwork;

  /// No description provided for @contextRail.
  ///
  /// In es, this message translates to:
  /// **'Riel'**
  String get contextRail;

  /// No description provided for @contextWallet.
  ///
  /// In es, this message translates to:
  /// **'Wallet'**
  String get contextWallet;

  /// No description provided for @usdView.
  ///
  /// In es, this message translates to:
  /// **'USD'**
  String get usdView;

  /// No description provided for @homeView.
  ///
  /// In es, this message translates to:
  /// **'Local'**
  String get homeView;

  /// No description provided for @agentHint.
  ///
  /// In es, this message translates to:
  /// **'El agente propone. No firma ni aprueba.'**
  String get agentHint;

  /// No description provided for @refresh.
  ///
  /// In es, this message translates to:
  /// **'Actualizar'**
  String get refresh;

  /// No description provided for @amount.
  ///
  /// In es, this message translates to:
  /// **'Monto'**
  String get amount;

  /// No description provided for @address.
  ///
  /// In es, this message translates to:
  /// **'Dirección'**
  String get address;

  /// No description provided for @watchHint.
  ///
  /// In es, this message translates to:
  /// **'Dirección para leer saldos'**
  String get watchHint;

  /// No description provided for @registerDryRun.
  ///
  /// In es, this message translates to:
  /// **'Registrar simulación'**
  String get registerDryRun;

  /// No description provided for @signSend.
  ///
  /// In es, this message translates to:
  /// **'Firmar y enviar'**
  String get signSend;

  /// No description provided for @language.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get language;

  /// No description provided for @pasteCode.
  ///
  /// In es, this message translates to:
  /// **'Pegar código'**
  String get pasteCode;

  /// No description provided for @openLink.
  ///
  /// In es, this message translates to:
  /// **'Abrir enlace'**
  String get openLink;

  /// No description provided for @noWallet.
  ///
  /// In es, this message translates to:
  /// **'Sin wallet'**
  String get noWallet;

  /// No description provided for @homeEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay saldos leídos.'**
  String get homeEmpty;

  /// No description provided for @scheduled.
  ///
  /// In es, this message translates to:
  /// **'Pagos agendados'**
  String get scheduled;

  /// No description provided for @addScheduled.
  ///
  /// In es, this message translates to:
  /// **'Agendar pago'**
  String get addScheduled;

  /// No description provided for @supplier.
  ///
  /// In es, this message translates to:
  /// **'Proveedor'**
  String get supplier;

  /// No description provided for @dueDate.
  ///
  /// In es, this message translates to:
  /// **'Vencimiento'**
  String get dueDate;

  /// No description provided for @memo.
  ///
  /// In es, this message translates to:
  /// **'Nota'**
  String get memo;

  /// No description provided for @invoiceRef.
  ///
  /// In es, this message translates to:
  /// **'Comprobante'**
  String get invoiceRef;

  /// No description provided for @country.
  ///
  /// In es, this message translates to:
  /// **'País'**
  String get country;

  /// No description provided for @verified.
  ///
  /// In es, this message translates to:
  /// **'Verificado'**
  String get verified;

  /// No description provided for @save.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get save;

  /// No description provided for @close.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get close;

  /// No description provided for @slippage.
  ///
  /// In es, this message translates to:
  /// **'Deslizamiento'**
  String get slippage;

  /// No description provided for @expires.
  ///
  /// In es, this message translates to:
  /// **'Vence'**
  String get expires;

  /// No description provided for @warnings.
  ///
  /// In es, this message translates to:
  /// **'Avisos'**
  String get warnings;

  /// No description provided for @steps.
  ///
  /// In es, this message translates to:
  /// **'Pasos'**
  String get steps;

  /// No description provided for @agentId.
  ///
  /// In es, this message translates to:
  /// **'Identidad del agente'**
  String get agentId;

  /// No description provided for @companyLink.
  ///
  /// In es, this message translates to:
  /// **'Vínculo de empresa'**
  String get companyLink;

  /// No description provided for @clearSession.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión de empresa'**
  String get clearSession;

  /// No description provided for @projectId.
  ///
  /// In es, this message translates to:
  /// **'Project ID de la wallet'**
  String get projectId;

  /// No description provided for @rampOut.
  ///
  /// In es, this message translates to:
  /// **'Salir con un proveedor'**
  String get rampOut;

  /// No description provided for @onRamp.
  ///
  /// In es, this message translates to:
  /// **'Entrar con un proveedor'**
  String get onRamp;

  /// No description provided for @otcOnly.
  ///
  /// In es, this message translates to:
  /// **'Solo instrucciones del operador. Esta app no integra esa API.'**
  String get otcOnly;

  /// No description provided for @featureOff.
  ///
  /// In es, this message translates to:
  /// **'Esta acción está apagada en este armado.'**
  String get featureOff;

  /// No description provided for @copied.
  ///
  /// In es, this message translates to:
  /// **'Listo para compartir'**
  String get copied;

  /// No description provided for @reportHold.
  ///
  /// In es, this message translates to:
  /// **'Contra no haber movido'**
  String get reportHold;

  /// No description provided for @reportInflation.
  ///
  /// In es, this message translates to:
  /// **'Contra inflación'**
  String get reportInflation;

  /// No description provided for @chainSeparated.
  ///
  /// In es, this message translates to:
  /// **'Los totales no se suman entre redes.'**
  String get chainSeparated;

  /// No description provided for @vaultDeposit.
  ///
  /// In es, this message translates to:
  /// **'Apartar'**
  String get vaultDeposit;

  /// No description provided for @vaultRedeem.
  ///
  /// In es, this message translates to:
  /// **'Retirar'**
  String get vaultRedeem;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
