# Lottery Atlas mobile beta tester guide — draft

Prepared October 7, 2026. Distribution is not yet open. This guide becomes an
invitation only after a signed build passes mobile acceptance and a verified
installation link and feedback destination are added. No tester invitation has
been sent. October 20–27 is a provisional planning window, not a launch promise.

## What to test

Lottery Atlas helps explore available lottery reports, catalogs and retailer
information with source dates and coverage limits. Supported state coverage has
been accepted for Texas, Kentucky, South Carolina, Virginia, New York, Ohio,
Colorado, Oregon and Missouri. Phone testing remains a separate requirement.
Other states are unfinished; their presence on the map is not evidence that
national coverage is complete. Ten-year history is outside this beta scope.

Read the source and scope notes for each screen. An empty result describes the
selected data and filters; it does not prove that there were no statewide wins.
Report prize counts are not necessarily distinct tickets or people. Scratch
unclaimed-prize estimates are not store inventory. The ticket checker compares
numbers with the latest completed national draw; it does not validate a ticket
or establish a prize entitlement.

Missouri's directory contains dated entries for Jefferson City and Columbia
only. Use its official search link for other locations. There are no Missouri
map coordinates or statewide directory count in that bundle.

## Before a session

Record the installed version/build, device model, OS version and orientation.
Use synthetic ticket numbers and labels when testing saved entries. Keep real
tickets, account details and private correspondence out of screenshots and
feedback. Use the designated beta installation route once supplied; the earlier
unsigned iOS build and debug-signed Android release archive are not beta releases.

## First-session checklist

| Step | Action | Expected observation |
| --- | --- | --- |
| Launch | Open from a cold start; inspect portrait and landscape | Navigation, map legend and timeline controls fit and remain usable; record any clipping or crash |
| Select a state | Tap the state name or Lottery Atlas in the compact header, search for an accepted state with the keyboard open, then dismiss it | Search and selection work without controls hiding behind keyboard or safe areas |
| Home setup | With no saved home state, tap Home, cancel, then reopen and choose a test state; navigate elsewhere and tap Home again | First tap opens setup, cancel saves nothing, saved Home returns to the chosen state; Settings can change it |
| Timeline modes | Tap the collapsed date/period bar, select Day, Week, Month and Year where available, then close and reopen in portrait and landscape | Choices remain aligned and selected mode persists; date-only sources retain their documented mode limits |
| Map menu | Open the header menu, then Drawings, Scratch games, Filters and Sources and coverage | Each action opens its controls on demand; dismissing returns to the map; selecting a state is required for state-specific catalogs and sources |
| State camera | Select an accepted state, rotate both directions, and return Home | Selected state remains visible between controls; the separate U.S. action returns to the contiguous national view; record clipped bounds or covered controls |
| Read a report | Change game, date and session where supported; scroll through tiers and footer | Selected identity, source date, retrieval date, units and limits remain legible |
| Follow a source | Open the official source, then return to the app | The source matches the selected report; record whether selection and scroll position persist |
| Browse Scratch | Search, apply ticket-price filters, select a game, clear filters | Results and empty states match filters; advertised prizes and unknown dates remain explicit |
| Browse a directory | Search within stated coverage, inspect available address/product fields, clear filters | No invented positions, stock or retailer-win implication; official wider-search route remains available |
| Favorites | Save a test game/place, close and reopen, then remove it | Entry persists, then stays removed after another restart |
| Saved numbers | Save synthetic numbers and a label, reopen, rename, then delete | Saved values are preserved correctly and deleted entry does not return; record any error |
| Readability | Enlarge system text and repeat core navigation | Controls and source limitations remain reachable; report clipping rather than assuming accessibility certification |
| Connection recovery | After loading a report, interrupt connectivity, reopen it, then reconnect | Record the actual error/fallback and displayed retrieval date; retained data must not acquire a fabricated new date |

Map tiles may require connectivity. Retained reports do not imply an offline
map. Only report newer-data adoption when the displayed source/retrieval evidence
actually changes to a newer validated snapshot. A successful reconnect alone is
not proof of a refresh.

## Feedback template

Copy this template into the verified feedback route once it is supplied:

- App version/build:
- Device and OS:
- State, screen, game/date/session and filters:
- Network condition and displayed retrieval date:
- Steps to reproduce:
- Expected result:
- Actual result:
- Frequency (once / sometimes / every attempt):
- Screenshot or short recording with personal information removed:

Report launch crashes, lost saved entries, incorrect state/game/session labels,
misleading coverage or freshness claims, and controls that cannot be reached
before cosmetic issues. Do not send passwords, signing keys, private agency
attachments or actual ticket barcodes. No automatic crash-upload service is
promised by this guide.

## Release-owner handoff — required before sending

- Fill in verified iOS/Android installation links, build numbers and a working
  feedback/support destination; use already supplied contact details where
  applicable, without publishing private contact data by default.
- Confirm signed installation and update, final phone layout, supported-state
  scope, network recovery, privacy/support publication and icon/launch appearance.
- Provide known mobile defects for that exact build and the current supported
  state list. Do not present desktop acceptance as completed mobile acceptance.
- Test the feedback route and assign triage ownership. Do not send invitations,
  purchase enrollment or make human account attestations as part of this draft.
