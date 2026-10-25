# GameSet

GameSet is a Flutter game catalog backed by Firebase Authentication and Cloud
Firestore.

## Firebase setup

The Android Firebase app is already configured in
`android/app/google-services.json` for project `gameset-c135b`. Enable **Google**
and, if you want the email form, **Email/Password** in Firebase Authentication.
Google Sign-In uses Firebase Authentication and the official Flutter Google
Sign-In package. In Google Cloud Console, configure the OAuth consent screen and
create the OAuth clients for this app. Register the Android package name and
SHA-1 certificate in Firebase Project Settings, then download the refreshed
`google-services.json` into `android/app/`. The file must contain the web OAuth
client entry as well as the Android client. The current file has no OAuth client
entries, so Google sign-in will remain unavailable until this setup is done.

Guests can browse the catalog. A signed-in Google or email account is required
to save games to its private wishlist.

Deploy `firestore.rules` before using the app:

```sh
firebase deploy --only firestore:rules
```

The admin interface is maintained in a separate app. The catalog shows
published Firestore records only. See
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
