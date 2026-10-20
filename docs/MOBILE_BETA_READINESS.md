# Mobile beta readiness

October 6, 2026 audit. Beta is authorized for iOS and Android with validated
coverage; national supported coverage is required before full public release.
October 20–27 remains a provisional beta estimate, not a promised launch date.
As of October 18 at 20:42 ET, fourteen states have accepted supported coverage, including South Dakota.
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

### October 8, 05:35 ET — redesign handoff synchronized

The direct-user redesign in 8198d32 supersedes the old pending-camera-build and
Home-chooser checkpoints: that build is installed, with native South Carolina
portrait/landscape, saved Home return, national fit and timeline sheet evidence
recorded above. Updated tester instructions to the actual compact header/menu
and collapsed timeline flow. Leave the running state map available for user
review; no repeated compile, native navigation or accepted-state recheck was
performed. Remaining mobile work includes broader supported-screen navigation,
saved-data native persistence, connection recovery, enlarged text, Android
runtime checks and signing/distribution gates. No full mobile acceptance.

### October 8, 06:35 ET — enlarged-text overflow repair

An isolated 390px widget check at 2x text scaling reproduced two concrete layout
failures: the collapsed timeline's fixed height overflowed vertically by 11px,
and the expanded year-axis labels overflowed horizontally by 11px. The dock now
sizes to its text with a 72px minimum and at least a 48px button; axis labels can
wrap within their available width. The expanded heat legend switches to its
stacked layout based on scaled text width. Ten timeline/menu tests pass,
including doubled-text menu reachability and Year selection. Two-file analysis
has only the four existing Radio API infos.

No simulator restart, installation or preference changes: the user's installed
8198d32 review remains untouched. Native enlarged-text verification and broader
accessibility work remain pending; these widget checks are not certification.
No full build was needed for this isolated layout check. Private logs are
work/mobile_beta/enlarged_text_{test,analysis}.log.

### October 8, 07:36 ET — current Android debug packaging

Built the current mobile redesign and enlarged-text fix (9617c82) as an Android
debug APK using the Android Studio JBR and migrated PNY build/Gradle paths.
Gradle assembleDebug passed in 29.3s. The 142,641,656-byte universal debug APK
contains arm64-v8a, armeabi-v7a and x86_64 native libraries, adaptive launcher XML,
all five legacy/foreground icon densities, and the compiled launch background.
Compiled manifest inspection confirms Lottery Atlas, package
com.apollohouser.my_flutter_app, version 1.0.0 (1), minimum SDK 24, target SDK 36,
and INTERNET. Signature verification identifies Android Debug, as expected for
this local artifact; this is not a signed distribution release.

No Android device or AVD is available in the current tooling inventory, so this
checkpoint does not establish installation, launch, splash/mask rendering or
Android interaction. The iOS simulator remains untouched for user review.
Internal storage was 16 GiB free and PNY 437 GiB free before this sequential build.
Private build log: work/mobile_beta/android_current_debug_build.log. No account,
credential, enrollment, upload or accepted-state changes.

### October 8, 08:37 ET — isolated Favorites persistence checks

Added two tests using the preferences package's in-memory asynchronous backend.
Both game and place favorites load valid entries despite malformed neighboring
records, deduplicate repeated keys, preserve game-kind/county/state destinations,
and persist additions and independent removals. Tests decode stored values via a
separate preferences reader rather than relying only on the visible notifier.
Both pass. Synthetic keys/labels only; no real preference storage was touched.

These checks do not prove native Favorites navigation or persistence across a
real process restart. The running iOS review is unchanged; no build, installation,
Gmail check, state activation or distribution was performed. Android runtime
preparation also confirmed that no SDK system image is installed; an emulator
binary alone is insufficient to launch an AVD. Keep to one running simulator.
Private log: work/mobile_beta/favorites_persistence_test.log.

### October 8, 09:37 ET — Android virtual device prepared on PNY

Installed the official SDK `system-images;android-36;default;arm64-v8a` package
(revision 2, approximately 1.9 GB). SDK Manager completed with stdin closed;
no license acceptance or account attestation was submitted. The previously absent
SDK system-images directory now links to
`/Volumes/PNY SSD/LotteryAtlas/tooling/android-system-images`.

Created `LotteryAtlas_API36`, a Pixel 7 profile backed by that Android 16 ARM64
image, with its writable data under PNY `LotteryAtlas/tooling/avd`. Configured
2 CPU cores, 2 GB RAM and a 4 GB data partition for bounded resource use.
`avdmanager list avd` and `emulator -list-avds` recognize it; acceleration check
returns Hypervisor.Framework success. Creation logged an unavailable optional
image devices.xml, but the selected Pixel 7 definition and AVD were registered.
First boot is still required to establish runtime readiness.

The AVD has not been booted or installed with the APK. Keep the running iOS
simulator available for user review; shut it down before starting Android so
only one simulator is running. No existing device data was removed. Private logs:
work/mobile_beta/android_{sdk_packages,system_image_install,avd_create}.log.

### October 8 user-requested five map buttons

Added a separate re-center action between Home and zoom controls. The horizontal
row gives Back, Home, Re-center, Zoom in and Zoom out five equal-width cells.
Re-center fits the selected state (or national view) without resetting selections
or filters. Desktop vertical spacing accounts for all five buttons. iOS simulator
debug build passed (Xcode 11.5 seconds), installed and launched on the existing
single iPhone 17e. Portrait screenshot confirms five evenly aligned buttons and
visible SC outline. No tap/rotation or broader state acceptance claim from this
visual check. Analysis retains one pre-existing live-map brace info. Current
simulator now includes these changes and intervening NC catalog UI code; the
prior installed-build references are superseded. Left open for user review.

### October 10 — user-reported landscape distortion

The running simulator initially stretched the entire old app frame, including
text and icons, when rotated. Restarting that installed app restored normal
proportions; the cause of the stale frame is not established. Inspection then
found a separate map-framing problem: full-width controls consumed most of the
short landscape map height.

Landscape now places the header, five map actions and collapsed timeline in a
300 logical-pixel right-hand column. Camera fitting reserves that column and
uses the remaining map height. Portrait layout is preserved. Eleven targeted
widget tests pass, including portrait/landscape/portrait control sizing. Analysis
has only five existing informational findings (four Radio API deprecations and
one brace suggestion). iOS simulator debug build passed (Xcode 10.4 seconds).

Installed and launched this build on the existing iPhone 17e simulator. Native
checks confirmed normal text/icon proportions, the contiguous U.S. fitting left
of the controls, portrait return, saved Home returning to South Carolina, and
South Carolina fitting after another landscape rotation. No visible control
obstruction in those views. Left the simulator in landscape on South Carolina
for user review. This supersedes the installed 1b201c5 and uninstalled ce3a93e
artifact references. Do not interrupt that review with automated navigation.

This does not establish North Carolina native acceptance, newer remote adoption,
source-return or failure retention, Android runtime readiness, or full mobile
acceptance. Private logs: work/mobile_beta/landscape-{tests,analysis,build}.log.

### October 12 — User simulator review complete

The user confirmed that the current simulator layout checks out and review is
finished. The prior do-not-interrupt review hold is cleared. NC native checking
has resumed on the existing installed build; see NORTH_CAROLINA_ACCEPTANCE.md
for the partial adoption, source-return and catalog interaction checkpoint.
Full NC/mobile acceptance and Android runtime checks remain open.


### October 12, 23:00 ET — NC supported acceptance

NC bounded supported coverage accepted on release 7de7bb8; see its acceptance
document for the final native reports/source-return/landscape and loader-failure
evidence. User simulator review remains cleared. Ordinary app remains installed
and portrait; no new build. This is state acceptance, not full mobile acceptance.
Next independent mobile work remains saved-data process persistence, enlarged-text
native checks and Android runtime (one emulator/simulator at a time), followed by
actual signing/account/distribution gates. No store upload or attestation occurred.


### October 15 — First Android emulator build/install/launch

At the user's request, built the current Android debug APK (15.8 seconds) and
booted the prepared LotteryAtlas_API36 emulator on PNY. No iOS simulator was
booted. Installation succeeded and a cold launch reached the national map with
visible controls, tiles and bottom navigation. Initial log inspection found an
unhandled MissingPluginException for the shared desktop setMapActive channel.
Added an Android no-op handler for that desktop-only setting; unknown methods
still return notImplemented. Rebuild passed (10.7 seconds), reinstall succeeded,
and cold launch returned Status ok. The new process log contained no matching
MissingPluginException, unhandled exception, fatal exception or RenderFlex
overflow marker at the checkpoint.

Private screenshots/build/runtime logs are in work/mobile_beta/android-*. The
emulator remains open for user testing. This establishes first Android launch,
not complete navigation/rotation/persistence/network recovery or beta acceptance.
Debug signing only; no store upload, account action or fee. Kansas remains the
sole active state; mobile work does not change its acceptance deadline.


### October 15, 16:50 ET — Current Android artifact prepared

Ordinary main.dart Android debug APK at 2c4b6ed builds successfully (Gradle14.3s;
167,669,700 bytes). Packaged Kansas collection and Scratch assets byte-match their
committed baselines. Build log is private work/mobile_beta/android-kansas-build.log.
Not installed or launched: the user's existing emulator review remains untouched.
This artifact includes the newly connected Kansas UI, but establishes compilation
only. Native Kansas interactions/source returns/adoption and full mobile acceptance
remain open; debug signing is not distribution signing. No additional emulator,
Gmail, account action or fees. No repeat build needed absent code changes.


## October 15, 17:51 ET — Android Kansas native checks started

Installed the prepared 2c4b6ed ordinary debug APK successfully on the existing
Android emulator; cold launch returned Status ok. No iOS simulator was booted,
no new build was needed and no additional emulator was started. Continued under
the user's authorization to control Android and the explicit cleared-review
instruction; earlier notes preserving the initial review are superseded.

Native search selected Kansas, displayed its no-mapped-activity notice, and the
compact menu opened the dedicated Scratch inventory. All 46 games are listed.
Game 257 shows separate conflicting launch fields and inventory limitations;
scrolling reaches FREE TICKET, unpublished verification time, cadence/coverage
and official source buttons. Footer screenshot confirms readable portrait layout.
Native retrieval 2026-10-15T21:33:00.108Z is newer than the packaged Scratch
baseline, establishing newer remote adoption for Scratch. Private screenshot and
UI evidence are in work/mobile_beta/android-kansas-*.

This is partial native evidence only: full tier traversal, filters, source return,
report interactions/adoption, wide layout and request-failure retention remain.
The app remains portrait at the Scratch footer. No state/mobile acceptance,
Gmail, fee or deadline change; Kansas remains due October 19 at 19:40 ET.


### October 15, 21:53 ET — User Android review handoff

The user asked to see the app running; the existing emulator was brought forward
with Lottery Atlas, without restarting or reinstalling. During the subsequent
heartbeat, independent tester preparation updated MOBILE_BETA_TESTER_GUIDE.md
with the exact debug revision, source-return navigation, Kansas limitations and
remaining checks. No emulator navigation, build or repeat test was performed in
this heartbeat, allowing the live user review to continue. This does not create
a new permission gate or require the user to reconfirm earlier authorization.
Kansas native acceptance remains open with its existing October 19 deadline.


## October 15, 22:55 ET — Enlarged-text Scratch correction

Independent 390x844 widget checks at 2x text reproduced a 23px horizontal and
372px vertical overflow in Kansas Scratch: the unconstrained Reset filters
button squeezed the count label into an extremely narrow column. Constraining
the reset button with Flexible lets both labels wrap while preserving the tier
viewport. Six tests now pass (two new enlarged-text/footer checks for Scratch
and reports plus four existing Scratch layout/filter tests). Two-file analysis
is clean. No source validation or data changed.

The user-visible emulator was not navigated or restarted. Installed 2c4b6ed does
not yet contain this fix; a new ordinary build and native enlarged-text check
remain necessary. No full mobile/accessibility acceptance is claimed. Kansas
remaining native groups and retention checks remain open, deadline unchanged.


## October 15, 23:55 ET — Enlarged-text Android artifact ready

Ordinary main.dart debug APK at eeae509 builds successfully (Gradle 15.9s),
including the Kansas enlarged-text fix. Build log is private
work/mobile_beta/android-kansas-large-text-build.log. Not installed or launched;
existing emulator session remains untouched. No repeat build is needed absent
code changes. Prepared a private Kansas production-loader request-failure probe
for the remaining native cache-retention gate, adapted to the real Kansas cache
keys and retrievedAt field; it has not been built or executed and establishes
no retention result. No tracked probe code.

Next install ordinary artifact and verify enlarged text, then continue remaining
native report families and controlled retention/restoration. State and mobile
acceptance remain open, deadline October 19 at 19:40 ET unchanged. No Gmail,
fees, account action or additional emulator.


## October 16, 00:55 ET — Native enlarged-text correction verified

Installed the existing eeae509 ordinary debug APK; cold launch succeeded without
another build. Only the existing Android emulator was active. At system font
scale 2.0, Kansas Scratch count/reset controls remain separately readable, with
a usable tier viewport. Native scrolling traversed game 257's tiers, FREE TICKET,
source limits and both official-source buttons. Screenshot and XML evidence in
work/kansas_native confirm the corrected portrait layout. Search hint ellipsis
is visible at this scale; no broad accessibility certification is claimed.

Restored the exact prior system font setting and confirmed normal-size controls.
New installed build supersedes 2c4b6ed; the named enlarged-text Scratch overflow
checkpoint is closed. Eight remaining report families/other groups, wide layouts
and native request-failure retention remain open. App left on Scratch with normal
text. No Gmail, fees, additional emulator or deadline change; Kansas remains due
October 19 at 19:40 ET.


## October 16, 01:57 ET — Native request-failure retention verified

The private Android probe ran both production Kansas loaders against real
preexisting SharedPreferences caches while HttpOverrides forced exactly two
SocketExceptions. Returned objects equaled the decoded caches and both stored
JSON strings stayed byte-identical. Logcat recorded KS_NATIVE_RETENTION_PASS:
24 reports at retrieval 2026-10-15T21:25:47.612140+00:00 and 46 Scratch games at
2026-10-16T04:41:40.465046+00:00, sourceDate null. Evidence is private
work/kansas_native/retention-logcat.txt. This closes the production-loader
request-failure retention gate, not OS-offline, tiles or UI-outage acceptance.

Probe build passed (8.9s); ordinary lib/main.dart rebuild passed (6.2s), was
reinstalled and cold-launched successfully. Native Kansas Scratch reopened with
46 games and source limits. No tracked probe code remains, no second emulator
was started and normal text settings were retained. Ordinary source is eeae509
plus later documentation/feed commits; no probe entry point is installed.
Remaining report-family interactions and wide layouts are still open; no new
remote-adoption claim from restoration. Kansas deadline unchanged. No Gmail,
fees or user action.


## October 16, 07:01 ET — Powerball native checks and advertisement correction

Selected base October 14/12 and Double Play October 14/12 on Android, with
separate numbers, raw timestamps and local dates. Traversed all nine shared
schedule rows with separately labeled base/Double Play amounts, pari-mutuel and
shared-jackpot qualifications, Power Play exclusions/10X threshold, option costs,
rules, cutoffs and limits. Official powerball page rendered in WebView Browser
Tester; Back retained base October 14 and footer position. Evidence is private
work/kansas_native/pb-*.xml.

Native review exposed a real scope defect: matching advertisements by shared
scheduleKey displayed the base Powerball $600M annuity/$246M cash advertisement
on Double Play selections. Restricted advertisements to exclude Double Play;
its literal $10M schedule remains. A regression test verifies base advertisement
presence and Double Play absence. Four widget tests pass (including all 24
selections compact/wide), two-file analysis clean. Ordinary Android debug build
passed 14.1s, installed and launched. Fresh native dumps confirm both Double Play
dates now proceed directly from numbers to schedules, while base October 14
retains its separately dated October 17 advertisement. This named defect is
closed; no feed values or validation weakened.

Installed ordinary build supersedes eeae509 for the report widget. Left portrait
on base October 14 summary. Four remaining families (Super Kansas Cash, Xs & Os,
Keno and Racetrax), report-wide and final consolidation remain. Kansas not yet
accepted; October 19 at 19:40 ET deadline unchanged. No Gmail, fees or additional
emulator.


## October 16, 11:00 ET — Supported coverage ACCEPTED

Kansas supported coverage is accepted on ordinary release **5d22fca**, ahead of
October 19 at 19:40 ET, with no extension. Scope closed October 14 at 20:41 ET.
The supported experience contains 24 bounded results across ten families/twelve
groups, literal schedules and separately dated advertisements, plus 46 Scratch
games with 425 literal remaining-prize tiers. Official retailer and unsupported
product/history routes remain explicit; no retailer map layer, Kansas winner
counts, paid-prize aggregation, live Keno/Racetrax service or complete history is
claimed. Scratch verification date remains unpublished, FREE TICKET categorical,
and conflicting launch metadata remains disclosed.

Native checks cover all families/groups and both retained selections, each
family's official page return, Scratch search/price/reset/detail return, newer
remote adoption and production-loader request-failure cache retention with
ordinary restoration. Prior evidence is retained above; no closed checkpoint
was repeated without a named defect. The Powerball/Double Play advertisement
scope defect was fixed and natively verified on the accepted release.

Final landscape report verification passed on the sole Android emulator:
selection/header/close controls remain usable, Keno long number order and warnings
wrap, base/Bull's-eye schedule fields remain readable, and switching to Mega
Millions resets scroll. Screenshots reports-wide.png and reports-wide-tiers.png
are private under work/kansas_native. Restored original rotation settings (auto
1/user 0); portrait retains Mega Millions October 13. Earlier Scratch landscape
and enlarged-text correction gates remain closed. This is not accessibility
certification or OS-offline/tile acceptance.

Consolidated checks pass: **49 Python tests** (33 Kansas parser/catalog/schedule
plus 4 atomic importer and 12 refresh transaction tests), **24 Flutter tests**,
and analysis of seven Kansas production Dart files is clean. Existing ordinary
Android build/install evidence stands; no new build was needed. Scheduled
publication and public byte verification are closed as documented above.

This is state supported-coverage acceptance, not full mobile beta, signed store
submission or national release. Twelve states are accepted; 33 remain. No active
successor selected in this checkpoint. No Gmail, fees or user action.


### October 16 — Additional user-authorized PNY storage migration

Moved Android SDK, project .dart_tool and user .pub-cache to PNY LotteryAtlas
tooling/android-sdk, project/dart_tool and tooling/pub-cache. Original paths are
symlinks. Existing SDK system-images symlink remains intact. Emulator stopped
before SDK move; no builds were active. All copies passed rsync checksum
comparison and linked read/write verification before original directories were
removed. Ditto initially normalized five AppleDouble sidecars; explicit rsync
copy resolved the comparison without discarding source files.

Internal free space increased from about 11 GiB to 18 GiB. Flutter version and
ADB version checks pass; AVD enumeration finds LotteryAtlas_API36. Two Kansas
result-validator tests pass using relocated Dart/package caches. Initial test
command named a nonexistent file; corrected to the existing validator suite.
.gitignore now ignores .dart_tool as a symlink as well as a directory. Flutter
SDK and Apple simulator storage remain internal. Keep PNY mounted during work.


### October 18 — Additional build-cache relocation

After the Mac update, Flutter/ADB and existing PNY links work. Relocated
~/Library/Developer/Xcode/DerivedData (524 MiB) to PNY
LotteryAtlas/tooling/xcode-derived-data with original-path symlink. Full rsync
checksum comparison and linked read/write passed before removing the original.
Future default Xcode derived data now uses PNY. No Xcode build was active; no
new iOS build validation is claimed. Flutter SDK (4 GiB) remains internal and
in use by VS Code; CoreSimulator device data (7.1 GiB) remains internal.


### October 18 — Flutter migration passed; simulator relocation rolled back

User authorized moving Flutter and simulator device data and closing VS Code.
Closed VS Code normally and stopped CoreSimulator before copying. Flutter now
lives at /Volumes/PNY SSD/LotteryAtlas/tooling/flutter with the original
~/Development/flutter path linked. Ditto/rsync copy, full checksum comparison
and linked read/write passed. Removed internal SDK backup only after six Flutter
tests, Android debug build and iOS simulator debug build passed. Internal free
space is approximately 24 GiB; PNY approximately 395 GiB.

Simulator Devices (7.1 GiB) copied and checksum-verified at PNY
LotteryAtlas/tooling/ios-simulator-devices, but CoreSimulator could not enumerate
the devices through either symlink or explicit device-set path. Its log reports
NSCocoaErrorDomain 513 / POSIX 1 Operation not permitted on external files.
No privacy/security settings or volume ownership were changed. Restored original
internal Devices directory from retained backup; PNY copy remains for diagnosis.
External simulator relocation is NOT complete and has reclaimed no internal space.

Original iPhone 17e booted successfully after rollback. First iOS rebuild hit a
stale generated App.framework path; moved .dart_tool/flutter_build aside to
flutter_build.pre-migration-validation (on PNY), rebuilt successfully, installed
and launched ordinary app. Native UI shows South Carolina map and navigation.
No probe code or state acceptance change. Simulator shut down after verification;
VS Code remains closed. Private logs: work/storage-migration-20261018.log,
migration-flutter-tests-20261018.log, migration-android-build-20261018.log and
migration-ios-rebuild-20261018.log. Keep PNY mounted for Flutter/build work.

### October 18 — Simulator device migration completed after permission grant

User explicitly approved Full Disk Access for Apple's CoreSimulator service and
manually added its executable. Settings verified the service switch on. Refreshed
PNY copy using checksum-based rsync; content matched. Corrected two destination
cache-file modes to the source modes after verification. Retained the internal
Devices directory as rollback while switching its original path to a symlink to
/Volumes/PNY SSD/LotteryAtlas/tooling/ios-simulator-devices.

Normal-path simctl enumeration retains all 11 original UUIDs. Original iPhone 17e
booted; ordinary Runner.app installed and launched successfully. get_app_container
resolves directly to PNY. Native map and Games navigation passed. Shutdown and
second boot completed; app relaunched and native map rendered again. Internal
rollback copy removed only after these checks. The earlier explicit --set probe
returned no devices; completion is based on the verified normal-path symlink,
not that probe. Full Disk Access remains enabled for the approved service.

Private evidence: work/simulator-copy-verification-20261018.txt (final content
comparison with two subsequently corrected mode differences) and
work/simulator-devices-pny-verified-20261018.json. Simulator runtimes/Xcode remain
internal; this moves device data only. Keep PNY mounted for simulator use.


### October 18 — Nebraska accepted; ordinary builds and migration verified

Nebraska release aabff9f accepted early; 13 states accepted/32 remain. Ordinary
iOS build, native flows, newer feed adoption and controlled production-loader
request-failure retention passed. Probe restored to ordinary main.dart and cold
launch into Nebraska passed. Ordinary Android debug APK built/installed and
cold-launched on API36 ARM64; process running with no filtered runtime errors.
Current native control cannot attach the standalone Android emulator; Android
visual flows remain a beta gate, not inferred from successful launch. iOS is
shut down, Android alone running. SDK/build/cache/device data use existing PNY
links; no further migration or permission changes. Signing/accounts, broader
persistence and distribution remain open. October20–27 is provisional beta only.

## October 18, 20:42 ET — South Dakota ordinary iOS release

Ordinary iOS debug `94fd40c` rebuilt, installed and cold-launched after the enlarged-title fix and private test-harness removal. Normal South Dakota draw and Scratch navigation passed. SD native acceptance is closed; see SOUTH_DAKOTA_ACCEPTANCE.md. iOS remains upright on the Scratch inventory; Android is stopped. Android last ordinary build remains `aabff9f`; broader Android visual flows, persistence, signing/accounts and distribution remain open. Fourteen accepted states/31 remaining does not establish national launch readiness. PNY links and permissions are unchanged.

## October 19, 23:16 ET — Iowa ordinary iOS remote adoption

Ordinary iOS `7eeec8b` adopted the real newer coupled Iowa feed and persisted bytes identical to the live publication. Corrected Pick3 midday numbers and the populated Powerball jackpot were verified in native presentation. The app remains upright; Android stopped. Iowa native layout/long-schedule/source-return gates remain open, so Iowa is not yet accepted. No probe or permission change. Broader Android, signing/accounts and distribution gates remain open.
