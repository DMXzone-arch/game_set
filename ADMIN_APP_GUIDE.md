# GameSet admin app guide

This repository is the **consumer** GameSet app. It contains the catalog,
authentication, profiles, and wishlist. The admin experience is intended to ship
as a **separate Flutter app**; this document describes the admin capabilities,
data, services, and access expectations that already exist here so that app can
be built on the same Firebase project and rules.

The admin screens, authentication, user records, and admin repository described
below are grouped in `lib/views/admin/`. They are intentionally **not reachable** from the consumer
app: there is no hidden entry point, and `test/views/admin_access_test.dart`
guards that. A separate admin app should copy/reuse these screens rather than
re-wire them into the consumer app.

## 1. Existing admin screens

All admin UI is in `lib/views/admin/`:

| Screen | File | Purpose |
| --- | --- | --- |
| Dashboard | `admin_dashboard_view.dart` | Entry screen. Shows aggregate counts and links to each management area. Hosts the admin sign-out action. |
| Games | `admin_games_view.dart` | Lists every game (published and unpublished). Creates, edits, publishes/unpublishes, and deletes games. |
| Game editor | `admin_games_view.dart` (`AdminGameEditorView`) | Form for a single game: name, category, description, version, size, download link, publish toggle, and image URLs. |
| Categories | `admin_categories_view.dart` | Lists all categories, adds, renames, activates/deactivates, and deletes them. |
| Downloads | `admin_downloads_view.dart` | Download counts per game, sorted by count, with a total. Read-only. |
| Users | `admin_users_view.dart` | Read-only list of user profiles (name, email, avatar, role, join date). |

## 2. Admin workflows

- **Sign in.** `AdminAuthService.signInAsAdmin(email, password)` signs in with
  email/password, then verifies `users/{uid}.data.role == 'admin'`. If the
  check fails or throws, the account is signed back out and
  `AdminAccessDeniedException` is raised. This "verify then sign out on failure"
  pattern must be preserved in the admin app.
- **Sign out.** `AdminAuthService.signOut()` clears the session and returns the
  user to a signed-out state.
- **Manage the catalog.** Create or edit a game, toggle `isPublished` to control
  whether it appears in the consumer catalog, and manage the category list.
- **Review activity.** Read download counts and browse users. Both are
  read-only in this app; role assignment is done manually in the Firebase
  Console.

## 3. Services available to the admin app

These live beside the admin screens in `lib/views/admin/` and are already used
by them. A new admin app can depend on the same logic:

- **`AdminRepository`** (`admin_repository.dart`)
  - `fetchAdminGames()` / `fetchAdminOverview()`
  - `fetchAdminCategories()`, `saveCategory()`, `deleteCategory()`
  - `saveGame(Game)`, `deleteGame(String)` — both write `games/{id}` and
    `game_images/{id}` in a single batch.
  - `fetchDownloadEntries()`
  - `createGameId()` for pre-allocating a document id.
  - Image handling: the editor stores **direct, publicly reachable image URLs**.
    `uploadGameImage()` exists for the optional Storage path, but the documented
    model does not require Firebase Storage.
- **`AdminAuthService`** (`admin_auth_service.dart`) — admin role verification
  and admin sign-out. See the sign-in workflow above.
- **`fetchAdminUserRecords()`** (in `admin_user_service.dart`) — returns
  `AdminUserRecord` values for the users screen.
- **`Game`** (`models/game.dart`) — the catalog model shared by admin and
  consumer. `Game.fromFirestore` merges `games/{id}` with `game_images/{id}`.
- **`GameRepository`** (`services/game_repository.dart`) — shared consumer
  catalog reads and download-count operations used by the admin repository.

## 4. Data model

See `FIRESTORE_SCHEMA.md` for the full field list. Collections the admin app
touches:

- **`games/{gameId}`** — `name`, `category`, `description`, `version`, `size`,
  `downloadLink`, `isPublished`.
- **`game_images/{gameId}`** — `iconUrl`, `screenshot1Url`, `screenshot2Url`
  (document id matches the game).
- **`categories/{categoryId}`** — `name`, `isActive`.
- **`downloads/{gameId}`** — `count` (incremented by the consumer app).
- **`users/{uid}`** — `displayName`, `email`, `avatarId`, `createdAt`,
  `updatedAt`, and an optional `role: 'admin'` assigned manually.

## 5. Access-control expectations

`firestore.rules` is the source of truth. The admin app must rely on these rules
rather than hiding UI alone:

- **`isAdmin()`** requires a signed-in user whose `users/{uid}` document has
  `role == 'admin'`. Writes to `games`, `game_images`, and `categories` are
  `isAdmin()`-only.
- **Catalog reads** are public but filtered: non-admins only read documents where
  `isPublished == true` (games) or `isActive == true` (categories). Admins can
  read everything.
- **`users` is admin-listable** (`allow list: if isAdmin()`), and a user can
  read their own document. Role assignment is not exposed to clients: profile
  create/update rules whitelist the allowed keys, so `role` cannot be set or
  changed by the app itself. Only the Firebase Console (or another trusted
  backend) grants admin.
- **`downloads`** are admin-readable and deletable; clients may only increment
  `count` by exactly one on a published game.

**The admin app must not weaken these rules.** It should reuse the same
`firestore.rules`, and it must keep `AdminAuthService.signInAsAdmin`'s
verify-then-sign-out behaviour so a non-admin session cannot reach admin data.

## 6. Recommended next steps for the separate admin app

1. Create a new Flutter app pointed at the same Firebase project
   (`gameset-c135b`); reuse this repo's `.env`-based web config or
   `google-services.json` pattern.
2. Copy `lib/views/admin/` and the shared `Game` model/repository as needed, or
  depend on this repository as a package.
3. Start from `AdminAuthService.signInAsAdmin` as the only gate into admin UI.
4. Deploy the existing rules before shipping:
   `firebase deploy --only firestore:rules`.
5. Grant `role: 'admin'` manually in the Firebase Console for the first admin
   account; the app cannot self-assign it.