# Mobile beta readiness

October 6, 2026 audit. Beta is authorized for iOS and Android with validated
coverage; national supported coverage is required before full public release.
October 20–27 remains a provisional beta estimate, not a promised launch date.
Oregon remains the sole active state with its October 10, 16:35 ET deadline.

## Verified local readiness

- Flutter 3.47.1 / Dart 3.13.1, Xcode 26.6 and Android SDK 36 toolchains pass
  Flutter doctor. Android SDK licenses are already accepted; no new enrollment
  or license attestation was performed.
- iOS release compilation with `flutter build ios --release --no-codesign`
  passes: Runner.app, 79.8 MB. This is an unsigned build, not an installable beta
  or TestFlight upload. Its built display name is Lottery Atlas.
- Flutter migrates the iOS deployment target from 13.0 to 15.0; the project now
  retains that required toolchain migration. Older iOS compatibility is not claimed.
- Corrected mobile display names to Lottery Atlas. Added Android INTERNET to the
  main manifest; previously it was only present in development manifests, which
  would prevent release network feeds and map requests from working.
- iOS simulators are installed but shut down. No connected iOS or Android mobile
  device was available; no Android virtual device was listed. Mobile interaction
  acceptance remains unperformed. Desktop acceptance is not phone acceptance.
- No valid local codesigning identities were found. The iOS project has no
  development team configured. Android key.properties is absent and release
  currently uses the template debug signing configuration. Account enrollment
  and store listings are unverified, not assumed absent. No keys were created,
  private identity values published, fees authorized or store submissions made.

## Ordered beta checklist

- [x] Inventory local toolchains and platform configuration.
- [x] Compile unsigned iOS release and fix mobile labels/network permission.
- [ ] Finish Android release build audit and inspect packaged manifest/signature.
- [ ] Replace debug release signing with private upload-key configuration; settle
  final app identifiers against existing store registrations before first upload.
- [ ] Prepare app icons, launch screens, beta description and supported-state list.
- [ ] Audit actual data collection/storage/third-party services and prepare accurate
  privacy/support materials and store declarations; do not invent privacy claims.
- [ ] Exercise small-phone and larger-device layouts, source links, filters,
  keyboard/safe areas, directories/reports, favorites and cold start on mobile.
- [ ] Exercise retained data during request failure/reconnect on mobile; do not
  imply offline map tiles or complete national activity.
- [ ] Complete independent artifact preparation before asking for account/signing
  access. Verify existing Apple/Google enrollment and signing through authorized
  account access; no purchases or automatic human attestations.
- [ ] Produce signed iOS/Android beta builds and validate installation/update.
- [ ] Configure tester distribution and feedback/crash triage; observe beta results
  and fix blocking defects before wider distribution.

Next: finish Android build evidence, then mobile layout/interaction preparation
and signing configuration. Resume Oregon publication alongside this bounded
platform work. National forecast still requires a remaining-state readiness audit.

Implementation references checked October 6:
[Flutter Android release guide](https://docs.flutter.dev/deployment/android) and
[Flutter iOS release guide](https://docs.flutter.dev/deployment/ios).
