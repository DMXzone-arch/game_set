import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/game.dart';
import '../services/wishlist_service.dart';

class WishlistViewModel extends ChangeNotifier {
  WishlistViewModel({WishlistService? wishlist, FirebaseAuth? auth})
    : _wishlist = wishlist ?? WishlistService(),
      _auth = auth ?? FirebaseAuth.instance {
    _activeUid = _currentUid;
    _authSubscription = _auth.authStateChanges().listen(_onAuthChanged);
    unawaited(loadGames());
  }

  final WishlistService _wishlist;
  final FirebaseAuth _auth;
  StreamSubscription<User?>? _authSubscription;

  String? _activeUid;
  List<Game> _games = const [];
  bool _isLoading = true;
  String? _errorMessage;
  int _loadGeneration = 0;

  String? get currentUid => _currentUid;
  bool get hasAccount => currentUid != null;
  List<Game> get games => List.unmodifiable(_games);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String? get _currentUid {
    final User? user = _auth.currentUser;
    return user != null && !user.isAnonymous ? user.uid : null;
  }

  void _onAuthChanged(User? user) {
    final String? nextUid = user != null && !user.isAnonymous ? user.uid : null;
    if (nextUid == _activeUid) return;
    _activeUid = nextUid;
    unawaited(loadGames());
  }

  Future<void> loadGames() async {
    final int generation = ++_loadGeneration;
    if (!hasAccount) {
      _games = const [];
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final List<Game> games = await _wishlist.fetchGames();
      if (generation != _loadGeneration) return;
      _games = games;
    } catch (error) {
      if (generation != _loadGeneration) return;
      _errorMessage = error.toString();
    } finally {
      if (generation == _loadGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _loadGeneration++;
    _authSubscription?.cancel();
    super.dispose();
  }
}
