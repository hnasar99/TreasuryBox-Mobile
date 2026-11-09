# TreasuryBox web deployment

This deploys the actual Flutter Celo UI and treasury core, not a replacement landing page.

## Scope

- Entrypoint: `lib/main_web.dart`.
- Flutter 3.47.7, revision `abaf9c523780a608bd46686fd5e53740a07077f8`.
- Locked Dart dependencies; the build runs Flutter tests before release compilation.
- Mandatory dry-run mode and a visible WEB DEMO banner.
- An unavailable browser signer fails closed for signing and broadcasting.
- Session state is ephemeral. Reloading the page clears preview changes.
- The native Android entrypoints and WalletConnect implementation are unchanged.
- This deployment does NOT integrate OpenHuman Rust, enable browser WalletConnect, or prove live blockchain operations. Provider requests remain subject to browser CORS and API availability.

## Build

```sh
bash scripts/build_web.sh
# Optionally reuse the exact SDK revision:
FLUTTER_SDK_PATH=/path/to/flutter-3.47.7 bash scripts/build_web.sh
```

Vercel serves `build/web`. Rewrites support Flutter client-side routes. No API credentials or signing keys should be supplied as Dart build defines: those values become public browser assets.

When the Vercel GitHub integration cannot access the repository, a deployment may download the public source at an exact Git commit during its build. The deployment metadata must record that source commit. This does not provide automatic deployments on future pushes.
