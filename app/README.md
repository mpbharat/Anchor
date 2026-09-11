# app/ — Flutter app, iOS + Android (owner: Bharat)

One Dart codebase → iOS + Android (web later if wanted).

## Run
```bash
flutter pub get
flutter run
```

## Structure
```
lib/
├── main.dart               app entry; static Load screen for now
├── theme/anchor_theme.dart V2 "Duo" design tokens (neobrutalist)
├── api/anchor_api.dart      typed client for the API contract (§7) — stubs today
├── screens/                 Onboarding, Load, Commit, Declined, Talk, Standing, Import, Connect
└── widgets/                 shared components (plates, gauge, talk button)
```

## Design — V2 "Duo"
Paper ground, cobalt accent, yellow on the load gauge, coral for refusal only. Neobrutalist: thick dark borders, hard offset shadows (no blur), flat fills. Tokens in `theme/anchor_theme.dart`. Screens/flows are in the design artifact (link in team chat) and `ANCHOR-BUILD-SPEC.md §9`.

## Persistent "Talk" affordance
Anchor is always one tap away — every main screen has a talk button (dock or floating mic). Silent by default on Anchor's side, always reachable on the user's side.

## Today vs event day
- **Today (body):** all screens as static UI wired to mock data via `anchor_api.dart`; voice plumbing (`speech_to_text` / `flutter_tts`) stubbed.
- **Event day (net-new):** wire every screen to real data, live voice loop, the silence log view.
