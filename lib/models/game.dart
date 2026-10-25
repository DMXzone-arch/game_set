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

  factory Game.fromCatalogFirestore({
    required String id,
    required Map<String, dynamic> data,
  }) {
    String value(String key) {
      final Object? field = data[key];
      return field is String ? field : '';
    }

    return Game(
      id: id,
      name: value('name'),
      category: value('category'),
      icon: value('icon'),
      screenshot1: '',
      screenshot2: '',
      description: '',
      version: '',
      size: '',
      downloadLink: value('downloadLink'),
      isPublished: data['isPublished'] != false,
    );
  }

  Game copyWith({String? icon}) => Game(
    id: id,
    name: name,
    category: category,
    icon: icon ?? this.icon,
    screenshot1: screenshot1,
    screenshot2: screenshot2,
    description: description,
    version: version,
    size: size,
    downloadLink: downloadLink,
    isPublished: isPublished,
  );

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
