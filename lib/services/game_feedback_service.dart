import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum GameWorkingVote { works, doesNotWork }

class GameFeedbackSummary {
  const GameFeedbackSummary({
    required this.works,
    required this.doesNotWork,
    required this.currentVote,
  });

  final int works;
  final int doesNotWork;
  final GameWorkingVote? currentVote;

  int get total => works + doesNotWork;
}

class GameFeedbackService {
  GameFeedbackService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Stream<GameFeedbackSummary> watch(String gameId) {
    return _votes(gameId).snapshots().map((snapshot) {
      int works = 0;
      int doesNotWork = 0;
      GameWorkingVote? currentVote;
      final String? uid = _registeredUser?.uid;

      for (final doc in snapshot.docs) {
        final Object? value = doc.data()['vote'];
        if (value == 'works') {
          works++;
          if (doc.id == uid) currentVote = GameWorkingVote.works;
        } else if (value == 'doesNotWork') {
          doesNotWork++;
          if (doc.id == uid) currentVote = GameWorkingVote.doesNotWork;
        }
      }

      return GameFeedbackSummary(
        works: works,
        doesNotWork: doesNotWork,
        currentVote: currentVote,
      );
    });
  }

  Future<void> setVote(String gameId, GameWorkingVote vote) async {
    final User? user = _registeredUser;
    if (user == null) throw const GameFeedbackSignInRequiredException();

    await _votes(gameId).doc(user.uid).set({
      'vote': switch (vote) {
        GameWorkingVote.works => 'works',
        GameWorkingVote.doesNotWork => 'doesNotWork',
      },
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  User? get _registeredUser {
    final User? user = _auth.currentUser;
    return user != null && !user.isAnonymous ? user : null;
  }

  CollectionReference<Map<String, dynamic>> _votes(String gameId) =>
      _firestore.collection('games').doc(gameId).collection('feedback');
}

class GameFeedbackSignInRequiredException implements Exception {
  const GameFeedbackSignInRequiredException();
}
