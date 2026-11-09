# OpenHuman Rust runtime integration

## Decision

TreasuryBox reuses the embedded OpenHuman runtime already exercised by AW. It does not create a second agent implementation and does not call a remote AW server.

- Upstream: https://github.com/hnasar99/AW
- Pinned upstream revision for this integration: `2d0d720669e5658839a14c3d64948a3c17921a16`
- Native crate: `rust/arc_openhuman_bridge` (`cdylib` + `staticlib`)
- Runtime: `openhuman-embed`
- Dart FFI reference: `lib/openhuman_bridge_native.dart`

The upstream bridge is GPL-3.0-only. Distribution/licensing must be cleared before shipping a binary that incorporates it. Do not silently copy the crate into this repository or strip its license.

## TreasuryBox adapter boundary

The Rust runtime is the reasoning/orchestration engine. TreasuryBox remains the authority for balances, policy, authorization, transaction construction and signing.

Initial read-only tools:
- `get_treasury_status`
- `get_balances`
- `get_cashflow`
- `generate_treasury_report`

Proposal-only tools:
- `propose_rebalance`
- `prepare_transfer`

Execution must remain a separate, explicit user-authorized path through the existing TreasuryBox signer and policy guards. The agent must never receive private keys, seed phrases, signing callbacks, or unrestricted RPC write access. A prepared transfer is not an executed transfer.

## Integration sequence

1. Bring the pinned AW runtime and its complete `vendor/openhuman` dependency tree into the Flutter build as a native Rust component. Preserve upstream notices and GPL-3.0-only terms.
2. Build `libarc_openhuman_bridge.so` for Android `arm64-v8a` (and x86_64 for emulator); package it through Android jniLibs or a reproducible Gradle/Cargo task.
3. Port the Dart FFI bridge, then replace AW-specific lab-only policy and tool evidence validation with a TreasuryBox-specific ABI contract. Do not weaken the current lab policy as a shortcut.
4. Implement a TreasuryBox tool registry backed by the existing Dart core/services. Start read-only; add proposal tools only after schema validation and guard tests.
5. Add integration tests proving the runtime loads in the app, completes a model turn, invokes only registered TreasuryBox tools, and cannot bypass caps/approval/signing.
6. Verify on a physical Android ARM64 device and run Flutter/Rust tests before claiming the agent runs in TreasuryBox.

## Current verified state (2026-11-09)

- AW contains the Rust C-ABI bridge and the Dart FFI client described above.
- TreasuryBox has Celo/Twin Flutter flavors and its own signer, balances and treasury logic.
- The checked TreasuryBox branch did **not** contain the Rust crate, FFI bridge, or an agent service at the time this integration proposal was prepared.
- Therefore this PR records and pins the intended upstream architecture; it does not claim that the Rust runtime is already linked into the TreasuryBox APK or that live financial operations have been tested.

## Release blockers

- GPL-3.0-only compatibility review.
- Reproducible Android native build and ABI packaging.
- TreasuryBox tool adapter and explicit approval boundary.
- On-device inference smoke test and regression suite.
