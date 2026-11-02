# TreasuryBox Mobile

Tesorería LatAm con ancla en USD. El core (`lib/core/`) no nombra cadenas ni emisores. Cada APK es un flavor:

| Flavor | Entrypoint | App id | Entrega |
|---|---|---|---|
| `celo` | `lib/main_celo.dart` | `io.treasurybox.mobile.celo` | Agents on Open Rails |
| `twin` | `lib/main_twin.dart` | `io.treasurybox.mobile.twin` | HackaTwin |

`lib/main.dart` no arranca la app. Hay que elegir un entrypoint.

Flutter **3.47.7** (Dart 3.13.5), el mismo revision que AW. El SDK de este entorno está en `~/Development/flutter-3.47.7`.

## Correr

El modo por defecto es **dry-run**. La app no firma sola: en live hace falta `TREASURY_MODE=live`, una firma humana por WalletConnect y una cotización ejecutable.

```bash
export PATH="$HOME/Development/flutter-3.47.7/bin:$PATH"
flutter pub get
flutter analyze
flutter test

flutter run -d linux -t lib/main_celo.dart --dart-define-from-file=env/celo.example.json
flutter run -d linux -t lib/main_twin.dart --dart-define-from-file=env/twin.example.json
```

APK (CI, hace falta Android SDK):

```bash
flutter build apk --release --flavor celo -t lib/main_celo.dart --dart-define-from-file=env/celo.example.json
flutter build apk --release --flavor twin -t lib/main_twin.dart --dart-define-from-file=env/twin.example.json
```

Copiá `env/*.example.json` si querés un archivo local. No commitees secretos. `WALLETCONNECT_PROJECT_ID` vacío deja el signer sin proyecto: el dry-run igual arma propuestas, y conectar la wallet falla hasta que el id esté definido.

## Qué hace cada flavor

**Celo.** Saldos por token en Celo. Rotar usa Textile v2 (`/rfq/preview` en dry-run, `/rfq/request` en live). Sin cotización, la ruta queda `uniswap-stub` y no se ejecuta. Cobro con QR EIP-681. El ramp de Ripio es un link-out. La atribución ERC-8021 solo agrega un sufijo hex; un código `celo_…` no alcanza para un envío live (`attribution-unverified`, `TODO(verify)`).

**Twin.** ARGt en Arbitrum y USDC en Arc, mostrados por cadena, nunca sumados entre testnet y mainnet. Arc testnet es el default (`ARC_NETWORK=testnet`). El swap de Curve queda indicativo mientras `fxEnabled` es false. El vault arma `approve` + `deposit` / `redeem` en calldata. CCTP solo si hay sesión de empresa. La paleta es hielo `#4CC3FF` sobre navy `#070D18`, distinta del dorado de AW.

## Fuera de alcance

iOS no entra en el hackathon: no hay schemes ni flavors de Xcode. El día de tesorería es America/Argentina/Buenos_Aires como UTC-3 fijo. Los montos son `BigInt` más decimales.

Pedidos a Eve lab, AW y ZonaBank: `docs/UPSTREAM_CHANGES.md`. Mapping: `docs/TS_DART_MAPPING.md`. Pin del lab: `docs/EVE_LAB_PIN.md`.
