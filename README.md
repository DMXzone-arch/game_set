# GameSet

GameSet is a Flutter game catalog backed by Firebase Authentication and Cloud
Firestore.

## Firebase setup

The Android Firebase app is already configured in
`android/app/google-services.json` for project `gameset-c135b`. Enable
**Email/Password** in Firebase Authentication and create an admin account.
Then add `users/{AUTH_UID}` in Firestore with:

```json
{ "role": "admin" }
```

Sign in from Settings by tapping the version row seven times. Never set admin
roles from the client.

Deploy `firestore.rules` before using the app:

```sh
firebase deploy --only firestore:rules
```

The admin editor accepts direct, publicly accessible image URLs, so Firebase
Storage and a billing account are not required. The catalog shows published
Firestore records only. See
[FIRESTORE_SCHEMA.md](FIRESTORE_SCHEMA.md) for collection fields.

## Run on Chrome

Register a Web app in Firebase Console under the `gameset-c135b` project. Copy
its App ID from the web config, then copy `.env.example` to `.env` and fill in
the Firebase Web values. Run:

```sh
flutter run -d chrome --dart-define-from-file=.env
```

`.env` is ignored by Git. Firebase Web configuration is included in the
compiled client app, so treat these values as public configuration rather than
secrets. Protect data with Firebase Authentication, Firestore rules, and API
key restrictions; never put service-account credentials or other server
secrets in this file. If Chrome shows a backend error, the catalog screen
shows the Firebase initialization or Firestore error.

## Other platforms

For iOS, register an iOS app in Firebase and add its
`GoogleService-Info.plist`. Android is the only native platform configured in
this repository.

## Run

```sh
flutter pub get
flutter run
```
