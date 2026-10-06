import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_set/services/user_profile_service.dart';

void main() {
  const String uid = 'player-uid';

  UserProfileService signedInService(FakeFirebaseFirestore firestore) {
    return UserProfileService(
      auth: MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(
          uid: uid,
          email: 'player@example.com',
          displayName: 'Player One',
          isAnonymous: false,
        ),
      ),
      firestore: firestore,
    );
  }

  Future<void> seedProfile(
    FakeFirebaseFirestore firestore, {
    required int avatarId,
  }) {
    return firestore.collection('users').doc(uid).set({
      'displayName': 'Player One',
      'email': 'player@example.com',
      'avatarId': avatarId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  group('profile avatar persistence', () {
    test('writes the chosen avatar id to Firestore', () async {
      final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();
      await seedProfile(firestore, avatarId: 1);

      final UserProfileService service = signedInService(firestore);
      await service.updateProfile(displayName: 'Player One', avatarId: 3);

      final Map<String, dynamic>? stored = await service.fetchProfile(uid);
      expect(stored?['avatarId'], 3);
    });

    test('reloads the previously saved avatar on a fresh session', () async {
      final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();
      await seedProfile(firestore, avatarId: 1);

      // First session saves icon 4.
      await signedInService(
        firestore,
      ).updateProfile(displayName: 'Player One', avatarId: 4);

      // A new session reads the profile back, as a relaunch would.
      final Map<String, dynamic>? reloaded = await signedInService(
        firestore,
      ).fetchProfile(uid);

      expect(reloaded?['avatarId'], 4);
    });

    test('survives several saves and keeps the latest icon', () async {
      final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();
      await seedProfile(firestore, avatarId: 0);

      final UserProfileService service = signedInService(firestore);
      for (final int avatarId in [1, 2, 3, 0]) {
        await service.updateProfile(
          displayName: 'Player One',
          avatarId: avatarId,
        );
      }

      final Map<String, dynamic>? stored = await service.fetchProfile(uid);
      expect(stored?['avatarId'], 0);
    });

    test('clamps out-of-range avatar ids', () async {
      final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();
      await seedProfile(firestore, avatarId: 0);

      await signedInService(
        firestore,
      ).updateProfile(displayName: 'Player One', avatarId: 9);

      final Map<String, dynamic>? stored = await signedInService(
        firestore,
      ).fetchProfile(uid);
      expect(stored?['avatarId'], 4);
    });

    test('keeps the display name and avatar together in one write', () async {
      final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();
      await seedProfile(firestore, avatarId: 0);

      await signedInService(
        firestore,
      ).updateProfile(displayName: 'New Name', avatarId: 2);

      final Map<String, dynamic>? stored = await signedInService(
        firestore,
      ).fetchProfile(uid);
      expect(stored?['displayName'], 'New Name');
      expect(stored?['avatarId'], 2);
    });

    test('never lets a profile update write the role field', () async {
      final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();
      await seedProfile(firestore, avatarId: 0);
      await firestore.collection('users').doc(uid).update({'role': 'admin'});

      await signedInService(
        firestore,
      ).updateProfile(displayName: 'Still An Admin', avatarId: 1);

      final Map<String, dynamic>? stored = await signedInService(
        firestore,
      ).fetchProfile(uid);
      expect(stored?['role'], 'admin');
      expect(stored?['avatarId'], 1);
    });
  });

  group('updateProfile requires a signed-in account', () {
    test('throws instead of silently succeeding when signed out', () async {
      final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();
      await seedProfile(firestore, avatarId: 3);

      final UserProfileService signedOut = UserProfileService(
        auth: MockFirebaseAuth(),
        firestore: firestore,
      );

      await expectLater(
        signedOut.updateProfile(displayName: 'Ghost', avatarId: 0),
        throwsA(isA<ProfileUpdateRequiresSignInException>()),
      );

      // The stored icon must be untouched by the rejected update.
      final Map<String, dynamic>? stored = await signedOut.fetchProfile(uid);
      expect(stored?['avatarId'], 3);
    });
  });

  group('updateProfile when no profile document exists yet', () {
    test('creates the document with every field the rules require', () async {
      final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();
      // No seedProfile: the document is absent, so this is a create.
      final UserProfileService service = signedInService(firestore);

      await service.updateProfile(displayName: 'Fresh User', avatarId: 2);

      final Map<String, dynamic>? stored = await service.fetchProfile(uid);
      expect(stored, isNotNull);
      expect(stored?['displayName'], 'Fresh User');
      expect(stored?['avatarId'], 2);
      // The create rule requires these keys, so they must all be written.
      expect(stored?['email'], 'player@example.com');
      expect(stored?['createdAt'], isNotNull);
      expect(stored?['updatedAt'], isNotNull);
    });

    test('a freshly created profile is readable on the next session', () async {
      final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();
      await signedInService(
        firestore,
      ).updateProfile(displayName: 'Persisted', avatarId: 3);

      final Map<String, dynamic>? reloaded = await signedInService(
        firestore,
      ).fetchProfile(uid);
      expect(reloaded?['displayName'], 'Persisted');
      expect(reloaded?['avatarId'], 3);
    });

    test('rejects an empty display name without writing', () async {
      final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();
      final UserProfileService service = signedInService(firestore);

      await expectLater(
        service.updateProfile(displayName: '   ', avatarId: 1),
        throwsA(isA<InvalidDisplayNameException>()),
      );
      expect(await service.fetchProfile(uid), isNull);
    });

    test('rejects an over-long display name without writing', () async {
      final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();
      await seedProfile(firestore, avatarId: 0);
      final UserProfileService service = signedInService(firestore);

      await expectLater(
        service.updateProfile(
          displayName: 'x' * (kMaxDisplayNameLength + 1),
          avatarId: 2,
        ),
        throwsA(isA<InvalidDisplayNameException>()),
      );

      final Map<String, dynamic>? stored = await service.fetchProfile(uid);
      expect(stored?['avatarId'], 0);
    });
  });
}
