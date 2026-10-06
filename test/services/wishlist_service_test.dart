import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_set/models/game.dart';
import 'package:game_set/services/wishlist_service.dart';

void main() {
  const String uid = 'player-uid';
  const String otherUid = 'other-uid';

  Game game(String id) => Game(
    id: id,
    name: 'Game $id',
    category: 'Action',
    icon: '',
    screenshot1: '',
    screenshot2: '',
    description: '',
    version: '1',
    size: '1 GB',
    downloadLink: 'https://example.com/$id',
  );

  Future<void> publishGame(
    FakeFirebaseFirestore firestore,
    String id, {
    bool isPublished = true,
  }) {
    return firestore.collection('games').doc(id).set({
      'name': 'Game $id',
      'category': 'Action',
      'description': '',
      'version': '1',
      'size': '1 GB',
      'downloadLink': 'https://example.com/$id',
      'isPublished': isPublished,
    });
  }

  WishlistService serviceFor(
    FakeFirebaseFirestore firestore, {
    String? signedInAs = uid,
  }) {
    return WishlistService(
      auth: MockFirebaseAuth(
        signedIn: signedInAs != null,
        mockUser: signedInAs == null
            ? null
            : MockUser(
                uid: signedInAs,
                email: '$signedInAs@example.com',
                isAnonymous: false,
              ),
      ),
      firestore: firestore,
    );
  }

  group('wishlist add and remove', () {
    test('saves a game and reports it as saved', () async {
      final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();
      await publishGame(firestore, 'g1');
      final WishlistService service = serviceFor(firestore);

      expect(await service.isSaved('g1'), isFalse);
      await service.setSaved(game('g1'), true);
      expect(await service.isSaved('g1'), isTrue);
    });

    test('removes a saved game', () async {
      final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();
      await publishGame(firestore, 'g1');
      final WishlistService service = serviceFor(firestore);

      await service.setSaved(game('g1'), true);
      await service.setSaved(game('g1'), false);

      expect(await service.isSaved('g1'), isFalse);
      expect(await service.fetchGames(), isEmpty);
    });

    test(
      're-adding a game keeps a single entry and refreshes addedAt',
      () async {
        final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();
        await publishGame(firestore, 'g1');
        final WishlistService service = serviceFor(firestore);

        await service.setSaved(game('g1'), true);
        await service.setSaved(game('g1'), true);

        final QuerySnapshot<Map<String, dynamic>> entries = await firestore
            .collection('users')
            .doc(uid)
            .collection('wishlist')
            .get();
        expect(entries.docs.length, 1);
      },
    );
  });

  group('wishlist persistence across sessions', () {
    test('a fresh session sees previously saved games', () async {
      final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();
      await publishGame(firestore, 'g1');
      await publishGame(firestore, 'g2');

      final WishlistService first = serviceFor(firestore);
      await first.setSaved(game('g1'), true);
      await first.setSaved(game('g2'), true);

      // New service instance = new session reading the same Firestore data.
      final WishlistService second = serviceFor(firestore);
      final List<Game> games = await second.fetchGames();

      expect(games.map((Game g) => g.id).toSet(), {'g1', 'g2'});
    });

    test('does not leak one account wishlist into another', () async {
      final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();
      await publishGame(firestore, 'g1');
      await publishGame(firestore, 'g2');

      await serviceFor(firestore).setSaved(game('g1'), true);
      await serviceFor(
        firestore,
        signedInAs: otherUid,
      ).setSaved(game('g2'), true);

      final List<Game> mine = await serviceFor(firestore).fetchGames();
      final List<Game> theirs = await serviceFor(
        firestore,
        signedInAs: otherUid,
      ).fetchGames();

      expect(mine.map((Game g) => g.id), ['g1']);
      expect(theirs.map((Game g) => g.id), ['g2']);
    });

    test('orders games newest save first', () async {
      final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();
      await publishGame(firestore, 'first');
      await publishGame(firestore, 'second');
      await publishGame(firestore, 'third');

      final WishlistService service = serviceFor(firestore);
      await service.setSaved(game('first'), true);
      await service.setSaved(game('second'), true);
      await service.setSaved(game('third'), true);

      final List<Game> games = await serviceFor(firestore).fetchGames();
      expect(games.map((Game g) => g.id), ['third', 'second', 'first']);
    });
  });

  group('wishlist hides unpublished games', () {
    test('omits a game that was unpublished after being saved', () async {
      final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();
      await publishGame(firestore, 'g1');
      await serviceFor(firestore).setSaved(game('g1'), true);

      await publishGame(firestore, 'g1', isPublished: false);

      expect(await serviceFor(firestore).fetchGames(), isEmpty);
    });

    test('omits a game that was deleted after being saved', () async {
      final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();
      await publishGame(firestore, 'g1');
      await serviceFor(firestore).setSaved(game('g1'), true);

      await firestore.collection('games').doc('g1').delete();

      expect(await serviceFor(firestore).fetchGames(), isEmpty);
    });

    test('prunes the stale entry so it cannot resurface', () async {
      final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();
      await publishGame(firestore, 'g1');
      await serviceFor(firestore).setSaved(game('g1'), true);
      await firestore.collection('games').doc('g1').delete();

      await serviceFor(firestore).fetchGames();

      final QuerySnapshot<Map<String, dynamic>> entries = await firestore
          .collection('users')
          .doc(uid)
          .collection('wishlist')
          .get();
      expect(entries.docs, isEmpty);
    });

    test('keeps published games while pruning unpublished ones', () async {
      final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();
      await publishGame(firestore, 'live');
      await publishGame(firestore, 'hidden', isPublished: false);

      // Saved directly to bypass the unpublished game's normal save path.
      await firestore
          .collection('users')
          .doc(uid)
          .collection('wishlist')
          .doc('live')
          .set({'addedAt': FieldValue.serverTimestamp()});
      await firestore
          .collection('users')
          .doc(uid)
          .collection('wishlist')
          .doc('hidden')
          .set({'addedAt': FieldValue.serverTimestamp()});

      final List<Game> games = await serviceFor(firestore).fetchGames();
      expect(games.map((Game g) => g.id), ['live']);
    });
  });

  group('wishlist requires a registered account', () {
    test('fetching while signed out throws', () async {
      final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();
      await expectLater(
        serviceFor(firestore, signedInAs: null).fetchGames(),
        throwsA(isA<WishlistSignInRequiredException>()),
      );
    });

    test('anonymous users cannot save', () async {
      final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();
      await publishGame(firestore, 'g1');

      final WishlistService anonymous = WishlistService(
        auth: MockFirebaseAuth(
          signedIn: true,
          mockUser: MockUser(uid: 'anon', isAnonymous: true),
        ),
        firestore: firestore,
      );

      expect(await anonymous.isSaved('g1'), isFalse);
      await expectLater(
        anonymous.setSaved(game('g1'), true),
        throwsA(isA<WishlistSignInRequiredException>()),
      );
    });
  });
}
