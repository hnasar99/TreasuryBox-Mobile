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

APK de release. Twin productivo usa Arc mainnet (`5042`, `https://rpc.mainnet.arc.io`). El ejemplo de laboratorio sigue en testnet. La firma del release es la de debug del repo: no hay keystore de tienda. El modo sigue en simulación hasta `TREASURY_MODE=live` y un Project ID de WalletConnect.

```bash
flutter build apk --release --flavor celo -t lib/main_celo.dart --dart-define-from-file=env/celo.example.json
flutter build apk --release --flavor twin -t lib/main_twin.dart --dart-define-from-file=env/twin.release.example.json --target-platform android-arm64,android-x64 --split-per-abi
```

Copiá `env/*.example.json` si querés un archivo local. No commitees secretos. `WALLETCONNECT_PROJECT_ID` vacío deja el signer sin proyecto: el dry-run igual arma propuestas, y conectar la wallet falla hasta que el id esté definido.

## Qué hace cada flavor

**Celo.** Saldos por token en Celo mainnet (`42220`). Rotar usa Textile v2 (`/rfq/preview` en dry-run, `/rfq/request` en live). Sin cotización, la ruta queda `uniswap-stub` y no se ejecuta. Cobro con QR EIP-681. El ramp de Ripio es un link-out. Live exige `TREASURY_MODE=live`, WalletConnect y el tag ERC-8021 Schema 0 `celo_202a37e338a2` (el que emitió Loops). Un código `0x…` sigue bloqueado (`attribution-unverified`). Este APK no pide credenciales Twin ni Belo.

**Twin.** ARGt en Arbitrum y USDC en Arc, mostrados por cadena, nunca sumados entre testnet y mainnet. El laboratorio usa `ARC_NETWORK=testnet`. El release usa mainnet (`eip155:5042`). El swap de Curve queda indicativo mientras `fxEnabled` es false. El vault arma `approve` + `deposit` / `redeem` en calldata. CCTP solo si hay sesión de empresa. La paleta es hielo `#4CC3FF` sobre navy `#070D18`, distinta del dorado de AW.

## Fuera de alcance

iOS no entra en el hackathon: no hay schemes ni flavors de Xcode. El día de tesorería es America/Argentina/Buenos_Aires como UTC-3 fijo. Los montos son `BigInt` más decimales.

Pedidos a Eve lab, AW y ZonaBank: `docs/UPSTREAM_CHANGES.md`. Mapping: `docs/TS_DART_MAPPING.md`. Pin del lab: `docs/EVE_LAB_PIN.md`.


## Agente Rust

La integración prevista reutiliza el runtime OpenHuman Embedded de AW. Arquitectura, revisión de licencia, límites de herramientas y estado real de integración: [docs/OPENHUMAN_INTEGRATION.md](docs/OPENHUMAN_INTEGRATION.md). Esta documentación no implica que el runtime ya esté empaquetado en el APK.
