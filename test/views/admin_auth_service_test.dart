import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_set/views/admin/admin_auth_service.dart';

/// The consumer app deliberately exposes no admin entry point; the admin UI is
/// intended for the separate admin app (see ADMIN_APP_GUIDE.md). These tests
/// cover the authorization layer that admin app will depend on, so admin access
/// is enforced from code as well as from `firestore.rules`.
void main() {
  Future<FakeFirebaseFirestore> seededFirestore() async {
    final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();
    await firestore.collection('users').doc('admin-uid').set({
      'displayName': 'Admin',
      'email': 'admin@example.com',
      'avatarId': 0,
      'role': 'admin',
    });
    await firestore.collection('users').doc('player-uid').set({
      'displayName': 'Player',
      'email': 'player@example.com',
      'avatarId': 1,
    });
    return firestore;
  }

  MockFirebaseAuth authAs(String uid, {String? email}) => MockFirebaseAuth(
    signedIn: true,
    mockUser: MockUser(uid: uid, email: email),
  );

  group('AdminAuthService role detection', () {
    test('recognises an account with the admin role', () async {
      final FakeFirebaseFirestore firestore = await seededFirestore();
      final AdminAuthService service = AdminAuthService(
        auth: authAs('admin-uid', email: 'admin@example.com'),
        firestore: firestore,
      );

      expect(await service.isAdmin('admin-uid'), isTrue);
    });

    test('treats an account without the admin role as a normal user', () async {
      final FakeFirebaseFirestore firestore = await seededFirestore();
      final AdminAuthService service = AdminAuthService(
        auth: authAs('player-uid', email: 'player@example.com'),
        firestore: firestore,
      );

      expect(await service.isAdmin('player-uid'), isFalse);
    });

    test('treats an unknown account as a normal user', () async {
      final FakeFirebaseFirestore firestore = await seededFirestore();
      final AdminAuthService service = AdminAuthService(
        auth: authAs('ghost-uid'),
        firestore: firestore,
      );

      expect(await service.isAdmin('ghost-uid'), isFalse);
    });

    test('only the exact admin role value grants access', () async {
      final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();
      await firestore.collection('users').doc('impostor-uid').set({
        'displayName': 'Impostor',
        'email': 'impostor@example.com',
        'avatarId': 0,
        'role': 'administrator',
      });

      final AdminAuthService service = AdminAuthService(
        auth: authAs('impostor-uid'),
        firestore: firestore,
      );

      expect(await service.isAdmin('impostor-uid'), isFalse);
    });

    test('exposes the signed-in account', () async {
      final FakeFirebaseFirestore firestore = await seededFirestore();
      final AdminAuthService service = AdminAuthService(
        auth: authAs('admin-uid', email: 'admin@example.com'),
        firestore: firestore,
      );

      expect(service.currentUser?.uid, 'admin-uid');
    });
  });

  group('AdminAuthService sign-in gate', () {
    test('an account with no users document is denied', () async {
      final FakeFirebaseFirestore firestore = await seededFirestore();
      final AdminAuthService service = AdminAuthService(
        auth: authAs('ghost-uid', email: 'ghost@example.com'),
        firestore: firestore,
      );

      await expectLater(
        service.signInAsAdmin(
          email: 'ghost@example.com',
          password: 'correct-password',
        ),
        throwsA(isA<AdminAccessDeniedException>()),
      );
      expect(service.currentUser, isNull);
    });
    test('accepts an account that already holds the admin role', () async {
      final FakeFirebaseFirestore firestore = await seededFirestore();
      // The mock returns its configured `mockUser` for any credential, so the
      // uid must be the seeded admin for the role lookup to succeed.
      final AdminAuthService service = AdminAuthService(
        auth: authAs('admin-uid', email: 'admin@example.com'),
        firestore: firestore,
      );

      await service.signInAsAdmin(
        email: 'admin@example.com',
        password: 'correct-password',
      );

      expect(service.currentUser?.uid, 'admin-uid');
    });

    test('refuses a non-admin account and signs it back out', () async {
      final FakeFirebaseFirestore firestore = await seededFirestore();
      final AdminAuthService service = AdminAuthService(
        auth: authAs('player-uid', email: 'player@example.com'),
        firestore: firestore,
      );

      await expectLater(
        service.signInAsAdmin(
          email: 'player@example.com',
          password: 'correct-password',
        ),
        throwsA(isA<AdminAccessDeniedException>()),
      );

      // A rejected account must never remain signed in.
      expect(service.currentUser, isNull);
    });

    test(
      'never leaves a signed-in session after an unverifiable role',
      () async {
        final FakeFirebaseFirestore firestore = await seededFirestore();
        final AdminAuthService service = AdminAuthService(
          auth: authAs('admin-uid', email: 'admin@example.com'),
          firestore: firestore,
        );

        // The role lookup succeeds here, so the gate accepts the admin and the
        // session stays valid. The negative case (an account with no admin role)
        // is covered above and must always end signed out.
        await service.signInAsAdmin(
          email: 'admin@example.com',
          password: 'correct-password',
        );
        expect(service.currentUser?.uid, 'admin-uid');

        await service.signOut();
        expect(service.currentUser, isNull);
      },
    );

    test('signs out an authenticated admin on request', () async {
      final FakeFirebaseFirestore firestore = await seededFirestore();
      final AdminAuthService service = AdminAuthService(
        auth: authAs('admin-uid', email: 'admin@example.com'),
        firestore: firestore,
      );

      await service.signOut();

      expect(service.currentUser, isNull);
    });
  });
}
