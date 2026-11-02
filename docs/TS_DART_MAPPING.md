# TS → Dart

Fuentes leídas, no editadas: Eve lab `packages/rails` y `agent/`, AW `lib/`, ZonaBank `docs/zonabank/twin-arbitrum.md` y `supabase/functions/ecosystem-api`.

| Origen | Destino | Notas |
|---|---|---|
| `packages/rails/src/format.ts` | `lib/core/amount.dart`, `lib/core/decimal.dart` | `BigInt` + escala. Sin `double`. |
| `agent/lib/guards.ts` | `lib/core/guards.dart` | Topes y buffer en HOME. Día `tb_treasury_day_v1`, UTC-3 fijo. Dos contadores: `liveSpent` (dedup `caip2:txHash`) y `dryRunIntended`. |
| `agent/tools/monthly_report.ts` | `lib/core/report.dart` | vs-hold = fin − (inicio + flujos). No usa los mocks de `/api/pnl`. |
| `abi/erc20.ts` | `lib/core/evm/abi.dart` | ERC-20 más `deposit` / `redeem` / `convertToAssets`. El ABI del lab no trae deposit/redeem. |
| `services/evm_read_client.dart` (AW) | `lib/core/evm/json_rpc.dart`, `balances.dart` | Lectura genérica. El gas es `eth_getBalance`. |
| `domain/qr_intent.dart` (AW) | `lib/core/qr/qr_intent.dart` | Rechaza `wc:`. Acepta link de empresa, EIP-681 y address pelada. |
| `domain/company_link.dart`, `services/ecosystem_api.dart` (AW) | `lib/core/company_link.dart`, `session_api.dart` | Redeem, refresh y `/v1/me`. Hosts: `fluuix.com`, `*.supabase.co`, `localhost:54321`. |
| `wallet_session_native.dart` (AW) | `lib/core/signer/walletconnect_signer.dart` | Cadenas las pasa el flavor. `eth_sendTransaction` y `eth_signTypedData_v4`. Disconnect: `client.disconnect` + `ReownSignError(6000)`. |
| `ui/theme.dart`, `router.dart` (AW) | `lib/ui/theme.dart`, `lib/app/router.dart` | Inicio / Caja / Agente / Más + scan. Paleta por flavor. |
| `entry-ripio.ts`, `ripio/tokens.ts` | `lib/flavors/celo/` | USDC y USAT `TODO(verify)`. wPEN y wCLP sin corredor. |
| `ripio/textile.ts` | `lib/flavors/celo/textile_client.dart` | v2: `POST /rfq/preview`, `POST /rfq/request`. Preview no es ejecutable. EIP-712 "Textile Taker Control" v1, chainId 42220. |
| `ripio/uniswap.ts` | `NonExecutablePayload('uniswap-stub')` | Nunca `minOut` 0. |
| `ripio/x402.ts` | cobro EIP-681 en el flavor celo | No usa `${PUBLIC_BASE_URL}/pay`. |
| `agent/schedules/daily_treasury.ts` | `lib/core/daily_job.dart` | Devuelve notas y un evento de ledger. No arma una tx. |
| `twin/tokens.ts` + `twin-arbitrum.md` | `lib/flavors/twin/tokens.dart` | Las 7 stables y el vault salen del markdown. En el TS del lab, fuera de ARGt y BRAt, las addresses son `0x0`. |
| `ecosystem-api` `arc_usdc_prepare`, `cctp_prepare`, `cctp_status` | `lib/flavors/twin/zonabank_api.dart` | `POST /v1/rails/arc/prepare`, `POST /v1/rails/cctp/prepare`, `GET /v1/rails/cctp/status`. |
| `domain/arc.dart` (AW) | `TwinTokens` | Testnet `eip155:5042002` / `https://rpc.testnet.arc.io`. Mainnet `eip155:5042` solo si `ARC_NETWORK=mainnet`. |
| Pool Curve del plan | quote en `twin/ecosystem.dart` | `get_dy` se lee igual. Ejecutable solo con `fxEnabled`, counter-asset USDC de Arbitrum `0xaf88…5831` y caps. Si no, indicativo (`feature-off`, `hop-unverified`, `twin-fx-otc`). No hay address de USD₮0 hardcodeada. |

`lib/flavors/registry.dart` solo mapea ids (`celo` → `ripio-celo`, `twin` → `twin-arc`) para que un import compartido no meta los dos ecosistemas en el mismo APK.

## Riesgos que quedan `TODO(verify)`

- Sesión Eve (`/eve/v1/session` y el stream) no está en el source del lab.
- Sufijo ERC-8021 contra `@celo/attribution-tags`.
- Direcciones USDC Celo y USAT.
- Pool Curve `0x356d349da9add7efb56a35fab939a2c6d852f853` viene del plan, no del source del lab.
- El hop ARGt → USD₮0 → USDC queda `hop-unverified` salvo que el counter-asset del pool sea el USDC de Arbitrum.
