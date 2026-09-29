# Fandom Verse – Pocket Edition

A mobile app for fans of anime, manga, games, K-pop, movies and other fandoms. Fans can explore lore, follow fandoms, find conventions near them, buy official merchandise, and ask an AI Fan Helper about anything in the app. Admins run all of the content from a built-in admin panel.

Built with **Flutter** and **Firebase**, for Android and web.

---

## Contents

- [Features](#features)
  - [For fans](#for-fans)
  - [For admins](#for-admins)
- [Tech stack](#tech-stack)
- [Getting started](#getting-started)
- [Running and building](#running-and-building)
- [Project structure](#project-structure)
- [Firebase setup](#firebase-setup)
- [Firestore collections](#firestore-collections)
- [Levels, XP and Deep Dive](#levels-xp-and-deep-dive)
- [AI Fan Helper](#ai-fan-helper)
- [Offline support](#offline-support)
- [Testing](#testing)
- [Configuration reference](#configuration-reference)
- [Troubleshooting](#troubleshooting)
- [Known limitations](#known-limitations)

---

## Features

### For fans

**First launch**
- Intro slides (managed by admins), then an interest picker (categories) and a fan badge (Newcomer, Enthusiast, Veteran or Collector).
- Guests can use most of the app without an account. Choices made as a guest carry over when they register on the same phone.
- Sign in with email and password or with Google. Registration checks the password strength (8+ characters with a letter, a number and a special character). Both screens have a show/hide password button.

**Home**
- Search bar for posts, fandoms, videos and podcasts.
- A "New here? Start here" card that guides beginners through their first steps.
- **Trending fandoms** carousel, ranked automatically from this week's views and follows (admins can also pin fandoms).
- **From your fandoms**: new posts from the fandoms you follow, with suggestions if you follow none.
- **Trending events** chosen by the team.
- **For you**: posts from your interest categories, filterable by reading level (Beginner or Expert).
- **Featured fandoms**: every category as a card.

**Lore and content**
- Categories → fandoms → posts. Post types are News, Gallery (image sets), Video (YouTube or uploaded clips up to 30 s) and Podcast (audio, YouTube or video).
- Fandom pages with followers, tags, a creators row and tabs (All, Beginner, Deep Dive, News, Gallery, Video, Podcast, Merch, Events).
- **Beginner Fan Hub**: guides for new fans, glossary quick terms and "Latest stories".
- **Deep Dive**: expert trivia, lore and interviews, locked until Level 3 (see [Deep Dive](#levels-xp-and-deep-dive)).
- **Glossary** of fan terms with a multi-word search.
- **Resources**: one search across posts, fandoms and creators, with filters.
- **Creators**: profile pages for writers, artists and channels, with their posts.
- **Today's Fandom**: a daily post highlighted by the team.

**Events**
- Views: **List**, **Map** (OpenStreetMap, pins coloured by event type) and **Calendar**.
- The list shows:
  - **Near you**: events within 50 km or in your city (when location is on)
  - **Happening now**
  - **All upcoming events**: every city, soonest first, grouped by month
- Filters (search, type, date range, city, distance, "My fandoms") only apply when the fan picks them.
- Event details: type, status (Coming soon / Now · Live / Closed), dates, venue, organizer, price, interested count, agenda sessions, and a **Get tickets** link to the official ticket page.
- **My Agenda**: save events. Saved events and their agendas work offline.

**Shop**
- Official merchandise with category chips and price sorting.
- Wishlist with **price-change alerts** (the phone notifies you when a wishlisted item gets cheaper or more expensive).
- Cart and **simulated checkout** (no real payment). Orders appear in Purchase history, with a PDF invoice and a status that admins update (Placed → Processing → Completed).

**Profile**
- Avatar (upload a photo or choose a built-in or team-made avatar), name, bio and badge.
- Level card with XP progress.
- Links to Following, Bookmarks, Wishlist, My Agenda, Purchase history, Notifications, About Us and Contact Us.

**Bookmarks = offline reading**
- Bookmarking a post saves its text, cover, gallery images, uploaded clip and podcast audio on the phone, so it can be read with no connection.

**Notifications**
- Team announcements (push, through Firebase Cloud Messaging) and wishlist price alerts, with a history screen.

**AI Fan Helper**
- A chat assistant that knows the app, its live content, the business details and the signed-in fan's own account. See [AI Fan Helper](#ai-fan-helper).

**About Us and Contact Us**
- The team's story, mission and "Meet the Team" (managed in the admin panel).
- Contact details, an office map with directions, FAQs, and an inquiry form that also works offline (the message is sent later).

### For admins

Admins sign in with a normal account whose `role` is `admin`. An orange **admin shield** button then appears in Home's top bar and opens the admin panel.

| Area | What admins can do |

| Dashboard | Overview counts and quick links |
| Categories | Add, edit, reorder, activate or deactivate, delete (with safety checks); choose which appear on the first-visit interest screen |
| Fandoms | Add, edit, pin as trending, activate or deactivate; renames update every linked post and product 
| Content (posts) | Create and edit posts of every type, set depth (Beginner / Deep Dive), attach a YouTube link or upload a video, pick Today's Fandom |
| Creators | Add and edit creator profiles |
| Events | Create and edit events with a map pin, a cover image (required for new events), a price, a ticket link and agenda sessions; unpublish, republish or **delete permanently** |
| Merchandise | Products, prices and images |
| Orders | View all orders and update their status |
| Users | Add users, edit name, role and XP, **activate or deactivate** accounts (deactivated users are signed out straight away), delete profiles |
| Glossary | Add and edit terms (duplicates are blocked) |
| FAQs | Questions shown on Contact Us and used by the AI helper |
| Inquiries | Read and manage Contact Us messages |
| About Us team | Team members, photos and order |
| Avatar library | Avatars fans can pick in Edit Profile |
| Onboarding slides | The first-launch intro carousel |
| Backup & Export | Export the app's data as files to share or keep |

Images and videos are uploaded to **Cloudinary**, with a progress indicator. Save buttons wait for an upload to finish.

---

## Tech stack

| Part  Technology 

| App | Flutter (Dart SDK ^3.11), Material 3, dark theme, Google Fonts (Orbitron, Inter) |
| Sign-in | Firebase Authentication (email/password and Google) |
| Database | Cloud Firestore, protected by `firestore.rules` |
| Push notifications | Firebase Cloud Messaging + flutter_local_notifications |
| Media hosting | Cloudinary (unsigned upload preset) |
| AI | Google Gemini (`google_generative_ai`, model `gemini-3.1-flash-lite`, fallback `gemini-3.5-flash-lite`) |
| Offline storage | Hive CE |
| Maps and location | flutter_map (OpenStreetMap tiles), geolocator, Nominatim reverse geocoding |
| Calendar | table_calendar |
| Video | youtube_player_flutter, video_player |
| PDF invoices | pdf, printing |
| Sharing | share_plus, url_launcher |

---

## Getting started

### Requirements

- Flutter SDK with Dart 3.11 or newer (`flutter --version`)
- Android Studio or the Android SDK (for Android builds), or Chrome (for web)
- A Gemini API key (free from Google AI Studio) for the AI Fan Helper

### Setup

```bash
git clone https://github.com/obaid000-rgb/techwiz7.git
cd techwiz7
flutter pub get
```

Create **`secrets.json`** in the project folder (next to `pubspec.yaml`), by copying `secrets.example.json`:

```json
{
  "GEMINI_API_KEY": "your-gemini-api-key"
}
```

`secrets.json` is git-ignored. Never commit a real key. Without it the app still runs, and the AI helper says it isn't available.

The Firebase project settings are already included (`lib/firebase_options.dart`, `android/app/google-services.json`). To use your own Firebase project, see [Firebase setup](#firebase-setup).

---

## Running and building

The API key is passed in at build time with `--dart-define-from-file`.

```bash
# Run on a connected Android phone or emulator
flutter run --dart-define-from-file=secrets.json

# Run on web (Chrome)
flutter run -d chrome --dart-define-from-file=secrets.json

# Build the release APK
flutter build apk --release --dart-define-from-file=secrets.json
```

The APK is written to `build/app/outputs/flutter-apk/app-release.apk`.

**VS Code:** use the **Run and Debug** panel. The launch configurations already pass the key: "Fandom Verse (phone)" and "Fandom Verse (Chrome)".

---

## Project structure

```
lib/
├── main.dart                 App entry: Firebase, Hive, push setup
├── firebase_options.dart     Firebase project config (generated)
├── config/                   App-wide settings: contact details, Gemini, Cloudinary
├── theme/                    Colours, fonts, dark theme
├── models/                   Data classes (Post, Fandom, EventItem, Merchandise, …)
├── services/                 Firebase, storage and API access (one service per feature)
│   └── chatbot/              AI Fan Helper: context builder, per-question picker,
│                             action buttons, offline answers
├── logic/                    Pure functions with no Flutter or Firebase code
│                             (event filters and status, search ranking); unit-tested
├── utils/                    Helpers: levels and XP, validators, formatting, YouTube
├── controllers/              State for larger fan screens (Resources, fandom pages, Beginner Hub)
├── widgets/                  Shared UI: post cards, Deep Dive lock, upload fields, avatars
├── screens/                  Fan screens, one folder per area
│   ├── splash/  onboarding/  auth/  home/  explore/  fandoms/
│   ├── events/  shop/  profile/  resources/  creators/  info/  notifications/
└── admin/                    Admin panel (views, widgets and controllers per area)

test/                         Unit and widget tests
firestore.rules               Firestore security rules
secrets.example.json          Template for secrets.json
```

---

## Firebase setup

To run the app against your own Firebase project:

1. Create a project at [console.firebase.google.com](https://console.firebase.google.com).
2. Enable **Authentication** → Email/Password and Google.
3. Create a **Cloud Firestore** database.
4. Connect the app:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   This regenerates `lib/firebase_options.dart` and `android/app/google-services.json`.
5. **Publish the security rules:** copy all of `firestore.rules` into Console → Firestore → **Rules**, then press **Publish**. (Or run `firebase deploy --only firestore:rules`.)
6. **Make the first admin:** register in the app, then in Console → Firestore → `users` → your document, set `role` to `admin`. Admins can promote other users from the admin panel after that.
7. For Google sign-in on Android, add your signing key's SHA-1 in Firebase project settings.

Republish `firestore.rules` every time the file changes; the app relies on it.

---

## Firestore collections

| Collection | Contents | Who can write |
|---|---|---|
| `users/{uid}` | Profile, role, XP, interests, follows, bookmarks, wishlist, saved events, `disabled` flag | Owner (limited fields), admins |
| `users/{uid}/cart` | Cart lines | Owner |
| `categories` | Categories (display order, interest-screen flag) | Admins |
| `fandoms` | Fandoms, follower and weekly counters | Admins; fans can only change the counters by ±1 |
| `posts` | All posts (type, depth, media, status) | Admins; fans can only add a view |
| `creators` | Creator profiles | Admins |
| `events` | Events, sessions, `interestedCount`, `isPublished` | Admins; fans can only move `interestedCount` by ±1 when saving |
| `merchandise` | Products | Admins |
| `orders` | Orders | Fans create their own; admins change the status |
| `glossary` | Fan terms | Admins |
| `faqs` | FAQs | Admins |
| `inquiries` | Contact Us messages | Anyone creates; admins read |
| `teamMembers` | About Us team | Admins |
| `avatarLibrary` | Avatars fans can pick | Admins |
| `onboarding_slides` | Intro carousel | Admins |
| `backups` | Backup and export history | Admins |

Queries never combine `where` with `orderBy` on a different field, so **no composite indexes are needed**. Filtering and sorting happen on the device.

---

## Levels, XP and Deep Dive

A fan's level is worked out from their XP; it isn't stored.

| Level | Name | XP |
|---|---|---|
| 1 | Newcomer | 0 |
| 2 | Explorer | 100 |
| **3** | **Fan** | **250 (unlocks Deep Dive)** |
| 4 | Superfan | 500 |
| 5 | Legend | 1000 (max) |

**Earning XP:**

| Action | XP |
|---|---|
| Open the app (once a day) | +10 |
| Read a post for the first time | +5 |
| Follow a new fandom | +10 |
| Ask the Fan Helper (up to 5 a day) | +2 |
| Place a shop order | +20 |

**Deep Dive lock:** one rule, `canViewDeepDive(user)` in `lib/utils/levels.dart`: admins always can, guests never can, everyone else needs Level 3 (`DEEP_DIVE_LEVEL`).
- Every way into a post uses it, including saved offline copies.
- Locked fans see a teaser screen: title, cover, progress bar, how to earn XP, and a link to the Beginner Fan Hub.
- Deep Dive cards show a lock badge instead of a text preview.
- The bookmark button is hidden on locked posts.

---

## AI Fan Helper

Opened from the robot button on Home. Replies stream in word by word.

**What it knows** (picked fresh for every question to keep requests small, about 2–3k tokens):
- A feature guide written from the app's real screens and labels.
- Live content that matches the question: fandoms, events, products, posts, creators, FAQs and glossary terms, plus trending fandoms and the next events.
- The business details: story, mission, team, contact details and office.
- The signed-in fan's own account (level, XP, orders, cart, wishlist, saved events, follows), but only when the question is about it. Never anyone else's data.

**Rules**
- It answers questions about the app, its content, the fan's account, the business, and general fandom knowledge.
- Anything else gets a fixed decline line.
- It never invents events, prices or contact details.
- It never reveals Deep Dive content to fans below Level 3.

**Action buttons:** answers can include buttons such as "Open Naruto", "View cart" or "Contact Us". Only ids that really exist in the app become buttons.

**Reliability**
- Busy or rate-limited replies (429, 500, 503) are retried up to 3 times (after 2, 5 and 10 seconds, or the delay the API asks for). The chat shows "Still thinking…" meanwhile.
- If the main model still fails, the fallback model gets one try.
- If everything fails while the phone is online, it shows "The assistant is busy right now. Please try again in a moment."
- The **offline answer** (matched from FAQs and the glossary) appears only when a DNS check confirms the phone really has no internet.

Code: `lib/services/chatbot/`.

---

## Offline support

- Firestore's offline cache keeps recently loaded screens working.
- **Bookmarks** save full posts (text, images, clip, audio) on the phone.
- **My Agenda** saves events and their agendas.
- **Contact Us** messages sent offline are delivered when the connection returns.
- The AI helper answers from the FAQs and glossary when the phone is offline.

Android backup is turned off (`allowBackup="false"` plus `data_extraction_rules.xml`), so a fresh install always starts clean, shows onboarding and asks the fan to sign in. Account data comes back from Firebase after sign-in.

---

## Testing

```bash
flutter analyze
flutter test
```

The unit tests cover:
- event filtering, status, city matching and the "Near you" rule
- levels, XP and the Deep Dive lock
- search and ranking for Resources and the glossary
- trending-fandom ranking
- the AI helper's action buttons, offline answers and per-question context

---

## Configuration reference

| File | What to change |
|---|---|
| `secrets.json` | `GEMINI_API_KEY` (git-ignored) |
| `lib/config/app_info.dart` | App name, tagline, support email, phone, working hours, office address and map coordinates, About Us story and mission |
| `lib/config/gemini_config.dart` | Gemini model and fallback model |
| `lib/config/cloudinary_config.dart` | Cloudinary cloud name and unsigned upload preset |
| `lib/utils/levels.dart` | Level thresholds, names, `DEEP_DIVE_LEVEL` |
| `lib/services/xp_service.dart` | XP awarded per action |
| `firestore.rules` | Security rules (republish after changes) |

---

## Troubleshooting

| Problem | Fix |
|---|---|
| AI helper says "The assistant is not available right now." | The app was started without the key. Run with `--dart-define-from-file=secrets.json`, or use a VS Code launch configuration. |
| AI helper says "The assistant is busy right now." | Gemini is overloaded. It already retried; try again in a minute. |
| Fans see no events | Events must be **published** and not ended. Check Admin → Content → Events. |
| Permission errors, or admin actions failing | Republish `firestore.rules` in the Firebase Console. |
| White page on web while debugging | Stop and restart the run. Google sign-in on web uses Firebase's popup, so no web client id is needed. |
| Hot reload error "Const class cannot remove fields" | Use a hot **restart** (capital R) instead. |
| Build fails or tools misbehave | Check free disk space on the system drive. |

---

## Known limitations

- **Payments are simulated.** No money is taken and nothing is shipped. Tickets are bought on the organiser's site through the ticket link.
- **Deleting a user** removes their profile only; their login still exists. Use **Deactivate** to block someone. Removing a login fully needs the Firebase Console or a Cloud Function.
- **Security rules**:
  - XP and counter limits are enforced per write, not over time; for a stricter setup, move XP awards to Cloud Functions.
  - Posts are publicly readable, so Deep Dive is locked in the app but not at the database level.
- **Keys shipped in the app**:
  - The Gemini key is compiled into the APK; restrict it to the Android app in Google Cloud Console.
  - The Cloudinary preset is unsigned; restrict its formats and size.
- **Release signing** uses the debug key and the `com.example.fandom_verse` id. Set a real application id and a release keystore before publishing to the Play Store.
- **Office location and phone** in `app_info.dart` are demo values; the phone number is a placeholder.



Admin panel email : test@gmail.com
password : Test@123 

