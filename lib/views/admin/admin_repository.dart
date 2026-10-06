import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/game.dart';
import '../../services/game_repository.dart';

class AdminRepository {
  AdminRepository({FirebaseFirestore? firestore, FirebaseStorage? storage})
    : _database = firestore ?? FirebaseFirestore.instance,
      _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _database;
  final FirebaseStorage _storage;

  String createGameId() => _database.collection('games').doc().id;

  Future<String> uploadGameImage({
    required String gameId,
    required String imageKey,
    required XFile image,
  }) async {
    final String extension = image.name.contains('.')
        ? image.name.split('.').last.toLowerCase()
        : 'jpg';
    final Reference reference = _storage.ref(
      'games/$gameId/$imageKey.$extension',
    );
    final String? contentType = image.mimeType;
    await reference.putData(
      await image.readAsBytes(),
      SettableMetadata(
        contentType: contentType != null && contentType.startsWith('image/')
            ? contentType
            : 'image/jpeg',
      ),
    );
    return reference.getDownloadURL();
  }

  Future<List<Game>> fetchAdminGames() =>
      GameRepository(firestore: _database).fetch7Games();

  Future<String> saveGame(Game game) async {
    final CollectionReference<Map<String, dynamic>> games = _database
        .collection('games');
    final DocumentReference<Map<String, dynamic>> gameDocument = game.id.isEmpty
        ? games.doc()
        : games.doc(game.id);
    final WriteBatch batch = _database.batch();

    batch.set(gameDocument, {
      'name': game.name,
      'category': game.category,
      'description': game.description,
      'version': game.version,
      'size': game.size,
      'downloadLink': game.downloadLink,
      'isPublished': game.isPublished,
    });
    batch.set(_database.collection('game_images').doc(gameDocument.id), {
      'iconUrl': game.icon,
      'screenshot1Url': game.screenshot1,
      'screenshot2Url': game.screenshot2,
    }, SetOptions(merge: true));

    await batch.commit();
    return gameDocument.id;
  }

  Future<void> deleteGame(String gameId) async {
    final WriteBatch batch = _database.batch();
    batch.delete(_database.collection('games').doc(gameId));
    batch.delete(_database.collection('game_images').doc(gameId));
    await batch.commit();
  }

  Future<List<AdminCategory>> fetchAdminCategories() async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _database
        .collection('categories')
        .get();

    return snapshot.docs
        .map((document) {
          final Map<String, dynamic> data = document.data();
          return AdminCategory(
            id: document.id,
            name: data['name'] is String ? data['name'] as String : '',
            isActive: data['isActive'] != false,
          );
        })
        .where((category) => category.name.trim().isNotEmpty)
        .toList()
      ..sort((first, second) => first.name.compareTo(second.name));
  }

  Future<void> saveCategory(String name, {String? id}) {
    final String categoryId =
        id ?? name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    return _database.collection('categories').doc(categoryId).set({
      'name': name.trim(),
      'isActive': true,
    }, SetOptions(merge: true));
  }

  Future<void> deleteCategory(String categoryId) {
    return _database.collection('categories').doc(categoryId).delete();
  }

  Future<List<AdminDownloadEntry>> fetchDownloadEntries() async {
    final QuerySnapshot<Map<String, dynamic>> downloadSnapshot = await _database
        .collection('downloads')
        .get();
    final QuerySnapshot<Map<String, dynamic>> gameSnapshot = await _database
        .collection('games')
        .get();
    final Map<String, String> gameNames = {
      for (final game in gameSnapshot.docs)
        game.id: game.data()['name'] is String
            ? game.data()['name'] as String
            : game.id,
    };

    final List<AdminDownloadEntry> entries = downloadSnapshot.docs.map((doc) {
      final Object? count = doc.data()['count'];
      return AdminDownloadEntry(
        gameId: doc.id,
        gameName: gameNames[doc.id] ?? doc.id,
        count: count is num ? count.toInt() : 0,
      );
    }).toList()..sort((first, second) => second.count.compareTo(first.count));

    return entries;
  }

  Future<AdminOverviewData> fetchAdminOverview() async {
    final List<QuerySnapshot<Map<String, dynamic>>> snapshots =
        await Future.wait([
          _database.collection('games').get(),
          _database.collection('categories').get(),
          _database.collection('downloads').get(),
        ]);
    final int downloadCount = snapshots[2].docs.fold<int>(0, (total, document) {
      final Object? count = document.data()['count'];
      return total + (count is num ? count.toInt() : 0);
    });

    return AdminOverviewData(
      gameCount: snapshots[0].docs.length,
      categoryCount: snapshots[1].docs.length,
      downloadCount: downloadCount,
    );
  }
}

class AdminCategory {
  const AdminCategory({
    required this.id,
    required this.name,
    required this.isActive,
  });

  final String id;
  final String name;
  final bool isActive;
}

class AdminDownloadEntry {
  const AdminDownloadEntry({
    required this.gameId,
    required this.gameName,
    required this.count,
  });

  final String gameId;
  final String gameName;
  final int count;
}

class AdminOverviewData {
  const AdminOverviewData({
    required this.gameCount,
    required this.categoryCount,
    required this.downloadCount,
  });

  final int gameCount;
  final int categoryCount;
  final int downloadCount;
}
