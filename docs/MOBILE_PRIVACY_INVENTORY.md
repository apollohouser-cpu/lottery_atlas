# Mobile data-flow inventory

Internal beta preparation, October 7, 2026; source baseline `61492cd`.
This is an implementation inventory, not a published privacy policy or a submitted
Apple/Google declaration. Runtime traffic and final signed artifacts remain to
be checked before making distribution claims.

## Local persistence

| Feature | Stored fields / purpose | Evidence and removal behavior |
| --- | --- | --- |
| Saved tickets | Game code, entered numbers, optional label, generated local ID and saved time; at most 50 entries | `lib/services/saved_ticket_service.dart`, `lib/models/saved_lottery_ticket.dart`; SharedPreferences JSON, rename/delete methods |
| Favorite places | Display title/subtitle, kind, state name, optional county/retailer identifiers and local key | `lib/models/favorite_place.dart`, `lib/services/favorite_places_service.dart`; SharedPreferences string list, toggle/remove |
| Favorite games | Encoded game records for quick access | `lib/services/favorite_games_service.dart`; SharedPreferences string list, toggle/remove |
| Preferences | Home state, map detail mode and time-zone display | `lib/services/app_preferences.dart`; settings exposes home-state clear and map-settings reset |
| Public data caches | Downloaded results, catalogs, directories and retrieval/check timestamps | Feed/report loaders in `lib/services`; retained data supports fallback and freshness disclosure |

The reviewed ticket/favorites services store these records locally and contain
no upload operation. This does not establish encryption, exclusion from OS
backups, or deletion from backups. Individual removal methods are present;
end-to-end mobile deletion and a comprehensive clear-data experience are not yet
verified. Freeform ticket labels can contain user-supplied personal information;
beta test cases should use synthetic labels and numbers.

## Network and external navigation

| Destination | Observed request data / trigger | Evidence |
| --- | --- | --- |
| Project GitHub Pages | Public JSON feed requests for activity, catalogs, directories, totals and state reports; some services support build-time URL/manifest overrides | `lottery_activity_feed_service.dart`, `state_scratch_catalog_feed_service.dart`, `state_retailer_directory_feed_service.dart`, `state_winning_ticket_total_service.dart` and state loaders |
| ArcGIS map tiles | Tile zoom/row/column requests for the viewed map area; configured app user-agent name | `lib/widgets/map/live_lottery_map.dart`, dark-gray base/reference TileLayers |
| MUSL, when configured | GET draw report with GameCode and optional OrganizationCode; winner summary with GameCode; configured API key in header | `lib/services/musl_draw_service.dart`; no request when key is missing |
| Apple Maps / Google Maps | Selected retailer address or activity coordinates as destination, opened externally on user action | Direction methods in `lib/widgets/map/live_lottery_map.dart` |
| Official lottery websites | Selected source/report/catalog URL opened externally | Source registry and report/catalog sheets |

Ticket checker fetches the latest result by game code and compares entered
numbers in Dart (`lib/screens/settings/ticket_checker_screen.dart`, lines
173 onward). The reviewed call does not send entered ticket numbers to MUSL.
Map tile selection can reveal the viewed area to the tile provider; it is not
proof that the app acquired device GPS location. External directions pass a
destination, not an app-supplied current-device origin in the reviewed methods.
Network recipients necessarily handle requests; their logging, retention and
use cannot be established by reading this repository. Do not translate this
inventory into a blanket “no data collected” claim.

## Permissions and dependency scope

The source Android main manifest declares INTERNET. The reviewed iOS Runner
Info.plist has no location, camera, microphone or tracking usage-description
keys. Direct dependencies in pubspec.yaml are Flutter, shared_preferences,
flutter_svg, flutter_map, latlong2, path_drawing, xml, timezone, http,
url_launcher and crypto. No analytics/advertising/crash-reporting SDK is named
in that direct dependency list; targeted lockfile searches for Firebase,
Sentry and geolocator returned no matches. This is not a runtime or full native
binary audit. Final merged Android permissions and iOS embedded SDK privacy
manifests still require inspection.

## Remaining beta release evidence

- Capture network destinations on the final mobile build, including startup,
  map navigation, saved-ticket checks and official-source navigation. Record
  request shapes without retaining keys or personal ticket labels.
- Verify local persistence and individual deletion across restart on both
  platforms, and establish intended backup/reset behavior.
- Review final dependency/SDK privacy manifests and merged permissions; complete
  required platform declarations from verified behavior, with human account
  attestations left to the account holder.
- Prepare an accurate public privacy/support page after confirming operator
  details and provider practices. Do not request contact details already supplied.
- Keep private agency deliveries, correspondence and unapproved joins outside
  app assets and public feeds. Existing state acceptance restrictions still apply.

No policy has been published, store questionnaire submitted, signing credential
created, account attested or mobile privacy acceptance claimed by this audit.


## October 22 — embedded simulator manifest audit

Inspected the existing ordinary iOS simulator Runner.app after Iowa acceptance;
no new build or signing operation. Parsed all three embedded PrivacyInfo.xcprivacy
files with plistlib, rather than inferring declarations from dependency names:

| Embedded component | Declared accessed API categories / reasons |
| --- | --- |
| shared_preferences_foundation | UserDefaults: 1C8F.1 |
| url_launcher_ios | Empty accessed-API list |
| Flutter.framework | FileTimestamp: 0A2A.1, C617.1; SystemBootTime: 35F9.1 |

All three declare tracking false and empty tracking-domain and collected-data
lists. These are component declarations, not proof of app-wide network privacy
or a completed store questionnaire. No root app privacy manifest was found in
this simulator artifact. The final signed release archive still requires its own
inspection and declaration review.

The built Info.plist reports Lottery Atlas, version 1.0.0, build 1 and a Flutter
local-network debugging usage description. Do not copy that debug permission
behavior into release claims. Source Android main manifest declares INTERNET;
it does not explicitly set allowBackup or dataExtractionRules. Backup exclusion
and deletion from OS backups therefore remain unverified. No backup behavior was
changed. Source dependency list remains the one inventoried above. No runtime
traffic capture, final merged release-manifest audit or user-data deletion test
is implied by this static inspection.

## October 28 — ordinary Android debug artifact audit

Inspected the restored ordinary main.dart APK after the Montana cache test,
using aapt2 against the compiled APK and the corresponding merged manifest.
The compiled permission list contains INTERNET and the application-scoped
DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION; the latter is declared signature-level.
No location, camera, microphone, contacts or advertising-ID permission appears
in this artifact's declared permission list. This is not a runtime traffic claim.

The merged artifact is explicitly debuggable, targets API36 and has minimum API24.
MainActivity is exported as the launcher; the URL-launcher WebViewActivity and
AndroidX startup provider are not exported. The exported profile-installer
receiver requires android.permission.DUMP. No allowBackup, fullBackupContent or
dataExtractionRules attribute is declared, so backup exclusion and deletion from
backups remain unverified. No permission, backup or device setting was changed.

Private build hashes, merged XML and compiled permission output are retained in
work/mobile_privacy_20261028. This debug-artifact check supplements the source
inventory; final signed-release manifests, runtime traffic, user-data deletion,
signing and distribution gates remain open. Android ordinary app remains running.
