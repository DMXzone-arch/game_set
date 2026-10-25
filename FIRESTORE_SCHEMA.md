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

### `games/{gameId}/feedback/{userId}`

Signed-in users can report whether a published game works. Each account has one
vote per game and can change or remove its own vote. Consumers read these small
records to display the live totals:

```json
{
  "vote": "works",
  "updatedAt": "server timestamp"
}
```

`vote` is either `works` or `doesNotWork`. Guests can see totals but must sign
in to vote.

## `game_images/{gameId}`

The document ID matches the associated game. Store direct, publicly accessible
image URLs in these fields. The publishing app accepts `http` and `https` URLs:

```json
{
  "iconUrl": "https://...",
  "screenshot1Url": "https://...",
  "screenshot2Url": "https://..."
}
```

Host image files wherever you prefer, then save their direct URLs in this
Firestore document from the separate publishing app.

## `downloads/{gameId}`

The app increments `count` after successfully opening a game's download URL:

```json
{ "count": 1 }
```

## `app_updates/android`

The publishing app writes the latest Android APK metadata here. Increase
`buildNumber` for every release and make `apkUrl` a public HTTPS download link:

```json
{
  "version": "1.0.1",
  "buildNumber": 2,
  "apkUrl": "https://...",
  "releaseNotes": "New features and improvements",
  "publishedAt": "server timestamp"
}
```

The consumer app checks this document and offers the APK when its build number
is higher than the installed one.

## `notifications/{notificationId}`

The publishing app writes one document per update. Consumers read notifications
in realtime and show a system alert and inbox badge. The publishing app creates
game notifications when a game is published and app update notifications when
a release is published:

```json
{
  "type": "new_game",
  "title": "New update: Example Game",
  "body": "What changed in this release",
  "gameId": "abc123",
  "createdAt": "server timestamp",
  "read": false
}
```

```json
{
  "type": "app_update",
  "title": "GameSet 1.0.1 is available",
  "body": "New features and improvements",
  "version": "1.0.1",
  "buildNumber": 2,
  "apkUrl": "https://...",
  "releaseNotes": "New features and improvements",
  "createdAt": "server timestamp",
  "read": false
}
```

`type` is `new_game`, `app_update`, or `general`. Rules allow public reads and
restricted publishing writes.

## `users/{uid}`

Users create profile documents when they sign up. A profile document can look
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
field. The separate publishing app may use manually assigned roles for its
own access control.

### `users/{uid}/wishlist/{gameId}`

Each signed-in user has a private subcollection of saved published games. The
document ID is the game ID; only the owner can read or change these records.

```json
{ "addedAt": "server timestamp" }
```
