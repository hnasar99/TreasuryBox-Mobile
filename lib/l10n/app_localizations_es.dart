// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get navInicio => 'Inicio';

  @override
  String get navCaja => 'Caja';

  @override
  String get navAgente => 'Agente';

  @override
  String get navMas => 'Más';

  @override
  String get scanAction => 'Escanear';

  @override
  String get balances => 'Saldos';

  @override
  String get quote => 'Cotizar';

  @override
  String get rotate => 'Rotar';

  @override
  String get collect => 'Cobrar';

  @override
  String get pay => 'Pagar';

  @override
  String get pnl => 'Resultado';

  @override
  String get dryRun => 'Simulación';

  @override
  String get liveMode => 'En vivo';

  @override
  String get buffer => 'Reserva';

  @override
  String get rotable => 'Rotable';

  @override
  String get decisions => 'Decisiones';

  @override
  String get yieldReserve => 'Posición con rendimiento';

  @override
  String get yieldDisclaimer =>
      'Es rendimiento sobre el activo local. No hay una tasa verificada.';

  @override
  String get noPrice => 'Sin precio';

  @override
  String fxSource(String source, String at) {
    return 'Fuente $source · $at';
  }

  @override
  String get perChain => 'Por red';

  @override
  String get proposalTitle => 'Propuesta';

  @override
  String get confirm => 'Confirmar';

  @override
  String get reject => 'Rechazar';

  @override
  String get costHome => 'Costo en moneda local';

  @override
  String get costUsd => 'Costo en USD';

  @override
  String get notExecutable => 'Sin cotización ejecutable';

  @override
  String get guardBlocked => 'El movimiento no pasa los controles';

  @override
  String get connectWallet => 'Conectar wallet';

  @override
  String get dailyReview => 'Repaso diario';

  @override
  String get deposit => 'Depositar';

  @override
  String get beneficiary => 'Beneficiario';

  @override
  String get disclaimerCrossBorder =>
      'La empresa firma con su wallet. Esta app no custodia fondos ni es asesoramiento regulatorio.';

  @override
  String get modeLocal => 'Modo local';

  @override
  String get insufficientData => 'Sin datos suficientes';

  @override
  String get doubleConfirm =>
      'Primer pago a este beneficiario: confirmá otra vez.';

  @override
  String get testnetBadge => 'TESTNET';

  @override
  String get contextLayer => 'Capa';

  @override
  String get contextNetwork => 'Red';

  @override
  String get contextRail => 'Riel';

  @override
  String get contextWallet => 'Wallet';

  @override
  String get usdView => 'USD';

  @override
  String get homeView => 'Local';

  @override
  String get agentHint => 'El agente propone. No firma ni aprueba.';

  @override
  String get refresh => 'Actualizar';

  @override
  String get amount => 'Monto';

  @override
  String get address => 'Dirección';

  @override
  String get watchHint => 'Dirección para leer saldos';

  @override
  String get registerDryRun => 'Registrar simulación';

  @override
  String get signSend => 'Firmar y enviar';

  @override
  String get language => 'Idioma';

  @override
  String get pasteCode => 'Pegar código';

  @override
  String get openLink => 'Abrir enlace';

  @override
  String get noWallet => 'Sin wallet';

  @override
  String get homeEmpty => 'Todavía no hay saldos leídos.';

  @override
  String get scheduled => 'Pagos agendados';

  @override
  String get addScheduled => 'Agendar pago';

  @override
  String get supplier => 'Proveedor';

  @override
  String get dueDate => 'Vencimiento';

  @override
  String get memo => 'Nota';

  @override
  String get invoiceRef => 'Comprobante';

  @override
  String get country => 'País';

  @override
  String get verified => 'Verificado';

  @override
  String get save => 'Guardar';

  @override
  String get close => 'Cerrar';

  @override
  String get slippage => 'Deslizamiento';

  @override
  String get expires => 'Vence';

  @override
  String get warnings => 'Avisos';

  @override
  String get steps => 'Pasos';

  @override
  String get agentId => 'Identidad del agente';

  @override
  String get companyLink => 'Vínculo de empresa';

  @override
  String get clearSession => 'Cerrar sesión de empresa';

  @override
  String get projectId => 'Project ID de la wallet';

  @override
  String get rampOut => 'Salir con un proveedor';

  @override
  String get onRamp => 'Entrar con un proveedor';

  @override
  String get otcOnly =>
      'Solo instrucciones del operador. Esta app no integra esa API.';

  @override
  String get featureOff => 'Esta acción está apagada en este armado.';

  @override
  String get copied => 'Listo para compartir';

  @override
  String get reportHold => 'Contra no haber movido';

  @override
  String get reportInflation => 'Contra inflación';

  @override
  String get chainSeparated => 'Los totales no se suman entre redes.';

  @override
  String get vaultDeposit => 'Apartar';

  @override
  String get vaultRedeem => 'Retirar';
}
