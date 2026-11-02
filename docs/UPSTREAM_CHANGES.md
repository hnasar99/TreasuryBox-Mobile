# Pedidos upstream

No se modifican Eve lab (`/home/hnasar/dev1/TreasuryBox`), AW (`/home/hnasar/dev1/aw`) ni ZonaBank (`/home/hnasar/dev1/zonafranca-digital-hub`). Esto es lo que hay que pedirles.

## Eve lab

- `approval: always()` en `agent/tools/rebalance.ts` y `agent/tools/pay_supplier.ts`. Hoy el rebalance llama `execute` directo y `pay_supplier` no envía la transferencia.
- Rutas de panel que la app no puede usar porque no existen: `POST /api/quote`, `POST /api/rebalance`, `POST /api/payments/scheduled`.
- `/api/balances` tiene que devolver `raw` y `decimals`. El cliente solo parsea `formatted` si la dirección coincide con un token conocido.
- `/api/pnl` no debe leer `PNL_STARTING_BALANCE` / `PNL_ENDING_BALANCE`. El reporte mobile calcula vs-hold con flujos locales y, si el panel falla, no usa esos mocks.
- En `rebalance`, buffer y topes en moneda HOME. Hoy compara el monto del token de origen.
- `dailySpent` persistido y calculado en America/Argentina/Buenos_Aires, no en UTC.
- Nombres de env: el código lee `RAIL_${SYMBOL}_ADDRESS` y el ejemplo tiene `TEXTILE_LIMIT_ORDER_REACTOR` y `RAIL_ARGT_PRIME_VAULT` (sin `_ADDRESS`). Agregar `UNISWAP_ROUTER_ADDRESS` al `.env.example`.
- `public/agent.json` apunta el agente a `:3000/eve/v1`. El README del lab usa `:2000`.
- Header de flavor (`X-Treasury-Flavor`) en la sesión Eve, cuando exista el endpoint.
- x402: `ripio/x402.ts` arma `${PUBLIC_BASE_URL}/pay` y el panel no tiene `/pay` (404). Opción A: página `/pay`. Opción B, ya tomada en mobile: el QR es EIP-681, no esa URL.
- Uniswap: si Textile no cotiza, no ejecutar con `amountOutMinimum = 0`. Mobile lo deja como `NonExecutablePayload('uniswap-stub')`.
- `POST /eve/v1/session`, el stream NDJSON y `POST /eve/v1/session/:id` con answers **no están** en el source del lab. `TODO(verify)`. El único call documentado es `POST /eve/v1/dev/schedules/daily_treasury`.
- `@celo/attribution-tags` no está en `node_modules`. Hasta que el sufijo coincida con ese paquete, el envío live tira `attribution-unverified`.
- USDC Celo `0xcebA9300f2b948710d2653dD7B07f33A8B32118C` y USAT `0xD2ab3C9A02DBBAB236BfEC45D1d755DF4267F771` son `TODO(verify)`: no aparecen en los tres repos.

## AW

Nada que cambiar en el repo. Mobile no copia el signer de Arc hardcodeado, OpenHuman, el bridge Rust, inference, cirBTC ni el burn/mint de Gateway. WalletConnect queda en `reown_sign` 1.4.1 / `reown_core` 1.5.1.

## ZonaBank

Nada que cambiar. `prepare_vault_*` vive en el edge de zonabank, no en ecosystem-api. El depósito y el rescate del vault se arman en Dart (`deposit` `0x6e553f65`, `redeem` `0xba087652`). Arc USDC y CCTP salen de la sesión que ya existe: `POST /v1/rails/arc/prepare`, `POST /v1/rails/cctp/prepare`, `GET /v1/rails/cctp/status`. `POST /v1/payments/submit` está en ecosystem-api y esta app no lo llama: la wallet firma los pasos que devolvió el prepare.
