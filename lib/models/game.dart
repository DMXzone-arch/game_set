class Game {
  final String id;
  final String name;
  final String category;
  final String icon;
  final String screenshot1;
  final String screenshot2;
  final String description;
  final String version;
  final String size;
  final String downloadLink;
  final bool isPublished;

  Game({
    required this.id,
    required this.name,
    required this.category,
    required this.icon,
    required this.screenshot1,
    required this.screenshot2,
    required this.description,
    required this.version,
    required this.size,
    required this.downloadLink,
    this.isPublished = true,
  });

  factory Game.fromFirestore({
    required String id,
    required Map<String, dynamic> data,
    Map<String, dynamic> images = const {},
  }) {
    String value(Map<String, dynamic> source, String key) {
      final Object? field = source[key];
      return field is String ? field : '';
    }

    return Game(
      id: id,
      name: value(data, 'name'),
      category: value(data, 'category'),
      icon: value(images, 'iconUrl').isNotEmpty
          ? value(images, 'iconUrl')
          : value(data, 'icon'),
      screenshot1: value(images, 'screenshot1Url').isNotEmpty
          ? value(images, 'screenshot1Url')
          : value(data, 'screenshot1'),
      screenshot2: value(images, 'screenshot2Url').isNotEmpty
          ? value(images, 'screenshot2Url')
          : value(data, 'screenshot2'),
      description: value(data, 'description'),
      version: value(data, 'version'),
      size: value(data, 'size'),
      downloadLink: value(data, 'downloadLink'),
      isPublished: data['isPublished'] != false,
    );
  }
}
