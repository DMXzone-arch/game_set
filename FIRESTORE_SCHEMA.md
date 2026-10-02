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

Create admin role documents manually in the Firebase Console. Clients can read
their own role document to gate the admin interface, but cannot create or edit
role documents.

```json
{ "role": "admin" }
```
