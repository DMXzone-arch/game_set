import 'package:flutter_test/flutter_test.dart';
import 'package:game_set/models/game.dart';

void main() {
  test('maps Firestore game fields and image URLs', () {
    final Game game = Game.fromFirestore(
      id: 'game-1',
      data: {
        'name': 'Example Game',
        'category': 'Action',
        'description': 'A test game.',
        'version': '1.2',
        'size': '2 GB',
        'downloadLink': 'https://example.com/game',
      },
      images: {
        'iconUrl': 'https://example.com/icon.png',
        'screenshot1Url': 'https://example.com/one.png',
        'screenshot2Url': 'https://example.com/two.png',
      },
    );

    expect(game.id, 'game-1');
    expect(game.name, 'Example Game');
    expect(game.category, 'Action');
    expect(game.icon, 'https://example.com/icon.png');
    expect(game.screenshot1, 'https://example.com/one.png');
    expect(game.screenshot2, 'https://example.com/two.png');
    expect(game.downloadLink, 'https://example.com/game');
  });
}
