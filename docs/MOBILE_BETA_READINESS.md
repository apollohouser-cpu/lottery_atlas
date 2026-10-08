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

## October 7, 21:20 ET — tester preparation

Prepared `MOBILE_BETA_TESTER_GUIDE.md`: supported-state and Missouri directory
limits, a bounded mobile interaction/recovery checklist, synthetic saved-data
cases, a reproducible feedback template and release-owner handoff requirements.
It is a draft, with no installation link or feedback destination invented and no
invitation sent. Signing, device acceptance, icon/launch verification and privacy
publication still gate distribution. This lightweight documentation work did not
start a build/simulator, inspect external drives or reopen state acceptance.

## October 7, 22:20 ET — icon and launch asset audit

Inspected source assets without building or starting a simulator. Both the iOS
1024-pixel marketing icon and Android xxxhdpi launcher visibly contain the
Flutter template mark, not the in-app Lottery Atlas compass. All 19 declared
iOS icon slots exist and match their declared pixel dimensions; the marketing
image is RGB, 1024×1024. Android has five legacy raster density assets
(48/72/96/144/192 pixels), with transparency, and no adaptive-icon resource in
the current main resource tree. Dimensions alone do not close icon readiness.

All three iOS LaunchImage assets are fully transparent 1×1 images; its storyboard
centers that image over white. Android's launch drawable uses a white background
with its example image commented out. Native launch appearance still needs
verification after replacement, including Android's system splash behavior.
Private dimension/hash evidence: work/mobile_beta/icon_audit_2026-10-07.json.

Use the existing compass branding in map_controls_overlay.dart as the design
reference: white explore_rounded glyph and blue gradient (#1478FF to #073A8A).
Next implementation should provide a reproducible master/export path, replace
mobile template icons, add Android adaptive resources and coordinate launch
backgrounds. Verify small-size legibility, masks, light/dark launch and the final
built resources before closing this gate. No new identity or arbitrary brand
redesign is needed. No assets changed in this audit, no store acceptance implied.

Storage migration confirmation remains pending; this audit did not access either
external drive, start builds or change accepted state coverage. The separate
South Carolina correspondence check has recorded cashing-retailer semantics and
retained its Pick 3/Pick 4 caveat; no agency delivery was promoted here.

## October 7, 23:20 ET — existing compass exported to mobile icons

Replaced Flutter template launcher PNGs with the in-app white compass/blue
branding. Added reproducible Pillow/Flutter-font exporter and upstream Material
icon attribution/license in tool/branding. Android now has adaptive foregrounds
and a blue background resource in addition to the five legacy density icons.
The iOS master was visually inspected; all 19 declared slots match dimensions
and are opaque RGB. Five Android legacy/adaptive sizes and foreground margins
pass checks; both new resource XML files parse. No full build or simulator was
started while storage migration remains unresolved. These checks do not prove
installed launcher masks or store acceptance. Launch-screen backgrounds/assets,
Android system splash and final native icon/layout verification remain pending.
No external-drive, signing, Gmail or state-scope changes.

## October 8 — external project storage

After the user confirmed the PNY-to-My Passport transfer had finished and
explicitly authorized formatting/migration, re-identified the physical PNY SSD
and formatted it as APFS, retaining its PNY SSD volume name. The active desktop
test app was stopped before moving build outputs. Project build and private
work directories are now on PNY through links preserving their existing paths;
content checksum comparisons passed before removing the internal originals.
Source checkout and Git history remain on the internal disk. Git ignore rules
cover both directories and symlinks to prevent private-work publication.

Keep PNY mounted at its existing name during development. Heavy builds should
remain sequential, with at most one simulator; external storage frees internal
disk space but does not increase RAM. Mobile native verification is still
pending; storage migration does not itself close any mobile acceptance gate.

The inactive Gradle user cache was also copied to PNY and content-checksummed
before replacing its original location with a link. No Gradle/Java build was
running during migration. Build/work/Gradle linked read/write checks passed.
Private migration evidence is stored on PNY in LotteryAtlas/migration_record.json.

## October 8, 00:23 ET — launch assets and post-migration iOS build

Replaced transparent iOS launch placeholders with reproducible 120-point white
compass assets at 1x/2x/3x over a dark navy storyboard background. Android legacy
launch backgrounds now center the existing compass foreground; light/dark API
31+ themes explicitly select the system splash background and icon following
[Android's splash-screen guidance](https://developer.android.com/develop/ui/views/launch/splash-screen).
XML parsing and launch-image dimensions/nonempty-alpha checks pass.

First post-migration iOS build failed with undefined Flutter framework symbols.
Preserved the prior iOS build directory separately on PNY and regenerated only
iOS outputs; simulator debug build then passed (10.2-second Xcode phase).
This establishes a working build path on external storage, not the failure's
precise root cause. No source checkout or private evidence was removed. The
old outputs remain at LotteryAtlas/project/ios-build-before-regeneration on PNY.
No simulator was booted; installed launcher/splash appearance and final phone
layout/interaction verification remain pending. Internal free space remains
about 20 GiB. Builds ran sequentially; no Gmail, fees, signing or state activation.

Android `:app:processDebugResources --no-daemon` also passes using the installed
Android Studio JBR explicitly (the shell default had no Java runtime). This
links the new API-qualified resources but is not a full APK/device smoke pass.

## October 8, 00:49 ET — user-requested simulator smoke: defects found

Installed current 5298281 simulator build on iPhone 17e / iOS 26.5 and launched.
Stopped the other booted iPhone 17 to keep one simulator active. National portrait
map loads; the corrected heat legend/timeline fit, and Day/Week/Month/Year each
respond and update their selection/labels. Find a State search with keyboard
selects Missouri; source navigation and Powerball report open, with legible
wrapped limits and prize rows. Closing the report returns to sources and map.

Mobile acceptance remains OPEN. Two observed layout defects:
- In state-map landscape, the empty-results banner covers timeline controls and
  upper map controls crowd the source/game buttons.
- Returning to upright portrait shows state draw/Scratch buttons overflowing
  horizontally (visible 8.5/10-pixel debug overflow indicators). The national
  portrait legend fix does not address this separate state header layout.
Rotation also left the viewport showing a much wider geographic area; inspect
camera preservation with the layout repair. No crash was observed in this bounded
session. No claim of complete source-return, offline, favorites, physical-device,
launcher/splash or accessibility acceptance. Simulator left upright on Missouri
for continued diagnosis. Prior state-data acceptance is not reopened.

## October 8 — responsive map layout correction

User-requested follow-up to the simulator layout defects: state source/draw/Scratch
controls now wrap into two rows on narrow phones, expanded menus use the available
width, and source-button text cannot overflow its row. Phone map actions run
horizontally above the timeline instead of covering headers or empty-state text.
The national draw control now measures the map's actual safe-area width, preventing
landscape overlap with Find a State.

Short landscape screens show a branded Timeline button that opens the complete,
scrollable timeline sheet with an explicit close button; portrait retains the
original full timeline. Timeline selections persist when closing/reopening the
sheet and returning to portrait. The landscape header omits the large brand row.

Validation: eight timeline widget tests pass (320/390/900 portrait widths and
780x360 landscape, including selecting Year, closing and reopening). Two-file
analysis has only the four existing Radio API deprecation infos. Final debug iOS
simulator build passes (10.3s). Installed on iPhone 17e / iOS 26.5: national map
portrait/landscape, Missouri state toolbar/empty notice/actions in both orientations,
landscape timeline Year selection/close, and return to upright portrait checked.
No visible overflow stripes or overlapping controls in these checked views.
Simulator accessibility text temporarily disappeared in landscape; pointer actions
and screenshots verified the timeline and its close button, and the accessibility
tree returned in portrait. This is layout smoke coverage, not complete mobile or
accessibility acceptance. Only one simulator remained running, upright with the
updated build; no signing, upload, state-feed changes or new state activation.

### October 8 — user review: Home and timeline alignment

Corrected the follow-up review findings: Day/Week/Month/Year now occupy their own
single equal-width row beneath playback controls, with stable widths on selection.
The map Home icon is always present; its existing handler opens a saved home state
or resets to the national map when no home state is configured. Previously the
control displayed a recenter icon whenever a home state was unset.

Eight timeline tests pass, now asserting equal widths and a common row at
320/390/900 widths. Three-file analysis retains only four existing Radio API infos.
iOS simulator debug build passes (9.8s); installed native portrait inspection
confirms the house icon and all four aligned choices. Month selection and Home tap
were exercised; the app remains open for user review. This does not add platform
acceptance, signing or distribution claims.

### October 8 — Home setup instead of an apparent no-op

User reported that Home did nothing. With no saved home state, the previous
fallback merely recentered the already-national map. Home now opens a searchable
home-state chooser when unset; selecting a state saves the existing preference
and the map preference listener opens it. Subsequent Home taps retain the saved
state navigation behavior. Settings uses the same chooser. Cancel does not save
anything, and repeated taps cannot open duplicate pickers.

The picker test passes search/no-match/selection/cancellation at phone size;
three-file analysis has only two existing Settings Radio API infos. iOS simulator
build passes (33.0s). Installed and clicked the actual map Home control: the
chooser visibly opens with the explanation and state list, without overflow.
Left it open for the user to choose; no home state was selected on their behalf.

### October 8, 02:23 ET — phone camera padding diagnosis

While leaving the live Home chooser untouched for user review, code inspection
found that most states used desktop camera-fit padding of 48px left plus 360px
right even on a 390px phone. That exceeds the map width and is a concrete defect
consistent with the previously observed over-wide Missouri view; it is not proof
of the complete rotation issue's cause. Phone widths below 600 now use 24px
horizontal/48px vertical camera-fit padding. Single-file analysis passes. No build,
reinstall or simulator navigation was performed in this checkpoint. Native state
selection/rotation and saved-Home camera verification remain pending; do not mark
camera acceptance complete. Current installed app remains f876014 with the Home
chooser available for user review.

### October 8, 03:23 ET — camera build and tester handoff

The pending phone camera-padding change (1e03a7b) compiles successfully in a
sequential debug iOS simulator build. Kept the installed f876014 app and its Home
chooser untouched for user review; this build is not native camera verification.
Added explicit Home setup/cancel/save/return, timeline alignment/retention and
state-camera rotation cases to the draft tester guide. Next native work remains
state selection/rotation/saved-Home framing, followed by the remaining mobile
acceptance checklist. No new state activation, signing, upload or distribution.

### October 8, 04:23 ET — synthetic saved-number lifecycle

Added and passed an isolated service test using mock preference storage: save
synthetic Powerball numbers, verify normalized persisted values, reload, rename,
replace the same number set, retain an identical set under Mega Millions, delete
each independently, and reject renaming a missing entry without changing storage.
The test inspects persisted JSON as well as service reads. It does not touch the
simulator's preferences, real tickets, user Home selection or private data.

This is automated service coverage only: physical storage/process restart and
native saved-number UI acceptance remain pending. No app-code change, build,
installation, simulator navigation, state activation or distribution occurred.
The already-built camera fix still awaits native verification; leave the user's
Home review undisturbed. The preceding documentation commit rebased to 8587604
while preserving the scheduled feed update f68e5c4.

### October 8: user-requested map-first phone redesign

The phone and short-landscape map now use a compact selected-state header with state picker, Search, menu and a separate U.S. action. The timeline defaults to a 72px dock with a thin heat legend and date/period button; full controls open in a scrollable sheet, retaining selection when closed. Drawings, Scratch, filters and source navigation are available from the menu. Desktop panels are retained on larger screens. Missouri Scratch opens its literal catalog sheet; other supported catalogs retain their existing selection/source routes.

Phone state framing reserves space for the visible controls, and viewport changes refit the selected state without clearing its filters. The national phone view fits the contiguous U.S.; Alaska and Hawaii remain reachable through state selection. The minimum zoom now permits the national fit on narrow/short viewports.

Validation: nine timeline/menu widget tests passed, including 320/390/900 widths, aligned period controls, collapsed/expanded retention and menu callbacks. Two-file analysis reports only the four existing Radio API deprecation infos. iOS simulator debug build passed (10.1s), installed and launched on the existing iPhone 17e. Native checks confirmed the complete South Carolina outline in portrait and landscape, Month selection and collapse, Drawings menu sheet, contiguous U.S. framing and saved Home return to South Carolina. Simulator restored upright and left on the state map for review. This is layout verification, not full mobile/store acceptance. Private logs: work/mobile_beta/map_first_{tests,analysis,build}.log.
