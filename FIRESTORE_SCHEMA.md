# Firebase data model

## `categories/{categoryId}`

```json
{ "name": "Action", "isActive": true }
```

## `games/{gameId}`

```json
{
  "name": "Example Game",
  "category": "Action",
  "description": "Game description",
  "version": "1.0",
  "size": "2 GB",
  "downloadLink": "https://example.com/download",
  "isPublished": true
}
```

Public catalog queries select only `isPublished: true`. The category must match
an active category's `name`.

## `game_images/{gameId}`

The document ID matches the associated game. Store direct, publicly accessible
image URLs in these fields. The admin editor accepts `http` and `https` URLs:

```json
{
  "iconUrl": "https://...",
  "screenshot1Url": "https://...",
  "screenshot2Url": "https://..."
}
```

Host image files wherever you prefer, then paste their direct URLs into the
admin editor. The URL values are saved in this Firestore document.

## `downloads/{gameId}`

The app increments `count` after successfully opening a game's download URL:

```json
{ "count": 1 }
```

## `users/{uid}`

Users create profile documents when they sign up. Admin role documents are
still assigned manually in the Firebase Console. A profile document can look
like this:

```json
{
  "displayName": "Player One",
  "email": "player@example.com",
  "avatarId": 2,
  "createdAt": "server timestamp",
  "updatedAt": "server timestamp"
}
```

`avatarId` selects one of the five generated in-app icons (0–4). Users can
update their display name and avatar. They cannot assign or edit the `role`
field. Admins receive read-only access to the `users` collection for the user
records screen. Assign administrator roles manually by adding `role: "admin"`
to the user's document in the Firebase Console.

### `users/{uid}/wishlist/{gameId}`

Each signed-in user has a private subcollection of saved published games. The
document ID is the game ID; only the owner can read or change these records.

```json
{ "addedAt": "server timestamp" }
```

```json
{ "role": "admin" }
```
