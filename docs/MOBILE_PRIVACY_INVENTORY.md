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
