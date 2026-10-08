# Mobile beta readiness

October 6, 2026 audit. Beta is authorized for iOS and Android with validated
coverage; national supported coverage is required before full public release.
October 20–27 remains a provisional beta estimate, not a promised launch date.
As of October 7, nine states have accepted supported coverage, including Missouri.
No mobile distribution is implied by desktop state acceptance.

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
  development team configured. Android key.properties is absent; release now rejects missing signing
  credentials (see October 6 signing update below). Account enrollment
  and store listings are unverified, not assumed absent. No keys were created,
  private identity values published, fees authorized or store submissions made.

## Ordered beta checklist

- [x] Inventory local toolchains and platform configuration.
- [x] Compile unsigned iOS release and fix mobile labels/network permission.
- [x] Compile Android release AAB; inspect merged manifest and archive signature.
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

Next: install the current simulator build and exercise mobile interaction, then
complete privacy, icons and tester preparation. Existing signing credentials and
store registrations remain unverified. The national readiness forecast is in
NATIONAL_RELEASE_FORECAST.md; accepted state publication checkpoints are closed.

Implementation references checked October 6:
[Flutter Android release guide](https://docs.flutter.dev/deployment/android) and
[Flutter iOS release guide](https://docs.flutter.dev/deployment/ios).

## Android build result — October 6, 03:45 ET audit

Release AAB compilation passes (64.6 MB, 238.2 seconds). The merged release
manifest contains INTERNET and Lottery Atlas. The archive is signed with the
template Android Debug certificate: compilation success does not make it ready
for Play distribution. Gradle installed SDK Platform 36 using an already accepted
SDK license. No new license consent was submitted. Logs remain private in work/.
Both platform compilation gates now pass; signing and phone interaction gates
remain open. Next: replace the Android debug-release signing configuration and
prepare simulator/device smoke testing, while advancing Oregon publication.

## Android signing configuration — October 6, 05:46 ET

Removed the template debug-key fallback for release. Gradle reads the ignored
android/key.properties only when populated; key.properties.example contains blank
fields and documents private storage. Explicit release tasks require all four
fields and an existing keystore. No identity, key or password was generated.
The missing-credentials release check fails with the intended actionable message,
without leaking values. This is the expected guard, not a source compilation
regression. The earlier successful AAB is debug-signed and must not be distributed
as a beta release. Signed-path verification awaits actual existing credentials;
independent mobile preparation continues before requesting account intervention.
Android debug APK build passes with credentials absent, confirming local testing remains available.

## Mobile acceptance preparation — October 6, 13:55 ET

The iOS debug simulator build passed (Xcode phase 30.6 seconds), producing
build/ios/iphonesimulator/Runner.app independently of store signing. Available
local test targets include iPhone 17e, iPhone 17 Pro Max and iPad mini on iOS 26.5;
all were shut down at inventory. No physical-device or simulator interaction pass
is inferred from availability. Android debug APK remains available for emulator
or physical-device installation; a release key is not needed for local smoke work.

Use the following bounded mobile acceptance sequence on a smaller phone and a
larger phone/tablet, recording OS, app commit, orientation and actual screenshots:

1. Cold launch; inspect safe areas, bottom navigation and map controls. Select an
   accepted state through Find a State with the keyboard open, then dismiss it.
2. Open a state report, switch game/session, scroll to source limitations and
   retrieval dates, open an official source and return. Verify data remains legible
   at the device's default text size and an enlarged accessibility text setting.
3. Search a retailer, inspect address and product/coverage limitations, save it to
   Favorites, relaunch and verify persistence, then remove the test favorite.
4. Apply game/date/prize filters and reset them. Verify a supported populated case
   and an explicitly scoped empty case without implying zero statewide winners.
5. Exercise retained feeds during controlled request failure, restore requests and
   reopen. Record newer-snapshot adoption only when a genuinely newer feed appears.
   Do not equate this with offline map tiles or OS-wide offline support.
6. Inspect portrait/landscape behavior, long names, report selectors and external
   source return; record crashes, overflow, inaccessible controls and launch delays.

Preliminary code inventory: favorite games and report caches use shared_preferences;
report downloads use the project's GitHub Pages host and map tiles use ArcGIS.
This is evidence for a later complete privacy audit, not a “no data collected”
claim or finished store declaration. Network-provider handling, all outbound
routes, support contact, privacy page, icons and tester instructions remain open.


## October 7 supported-state update

Missouri was accepted at 17:22 ET on release 337848b, bringing the supported
testing set to nine states: TX, KY, SC, VA, NY, OH, CO, OR and MO. Missouri's
directory is a dated Jefferson City/Columbia bundle with official search for
other locations, not statewide mapping. Mobile simulator interaction, privacy,
icons/tester preparation and signing/distribution remain open as documented above.


## October 7, 19:20 ET — first iPhone simulator smoke and layout repair

Built the current app for iOS simulator (32.0-second Xcode phase), installed and
cold-launched on iPhone 17e / iOS 26.5. The national map loaded, but the heat
legend and timeline mode row visibly overflowed the phone width. This was a
mobile platform defect, not a reopened state-data acceptance.

Changed the heat legend to use two rows at narrow widths and a flexible scale;
timeline controls now wrap rather than forcing four mode chips into one row.
Seven timeline tests pass, including new 320/390/900 logical-pixel checks that
all four mode chips remain within bounds, respond to taps and produce no layout
exceptions. An intermediate corrected simulator build passed (8.1-second Xcode
phase). Final equivalent legend cleanup also passes the tests; full final-device
interaction/rebuild remains pending after the memory/storage intervention.
Earlier analysis found only four existing Radio API deprecation infos in the
controls file; no errors. Do not claim complete mobile acceptance or distribution.

During testing the internal disk ran out of space. Removed only regenerable,
ignored Android build intermediates; preserved APK/AAB outputs and project data.
The user subsequently reported macOS application-memory exhaustion and began
moving PNY files to My Passport. At this checkpoint internal free space is about
12 GiB and no simulator is booted. Keep builds sequential and one simulator at
most; close test apps and research tabs after use. Do not start another large
build while the storage migration is underway. A separate user-authorized 8 PM
Eastern automation handles PNY verification/formatting; this development task
must not format it or interfere with copying. Uncommitted layout edits from the
interrupted run were recovered and preserved. No next state activated in this
platform repair; select next state with a fresh deadline after resuming national
implementation. No Gmail, fees, signing keys or store upload.

## October 7, 20:20 ET — low-resource privacy preparation

Added `MOBILE_PRIVACY_INVENTORY.md` with code-backed local ticket/favorite/cache
storage, feed/tile/MUSL requests, external directions and source navigation,
source-manifest permissions and remaining runtime/store-declaration checks.
This is internal release preparation, not a published policy or completed
privacy acceptance. No code changed and no build/simulator was started.

The separate 8 PM PNY preparation check could not verify that retained files had
been completely backed up to My Passport. PNY was left untouched and that
one-time automation was deleted after requesting the missing confirmation.
Continue only lightweight work while transfer completion remains unverified;
do not format the drive from the development automation. Final simulator layout
verification, mobile acceptance, icons, tester materials and signing remain open.
