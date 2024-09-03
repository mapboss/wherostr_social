class FeedMenuItem {
  final String type;
  final String id;
  final String name;
  final List<String> value;

  FeedMenuItem({
    required this.type,
    required this.id,
    required this.name,
    required this.value,
  });

  factory FeedMenuItem.fromString(String value) {
    final [i, t, n, v] = value.split('|');
    return FeedMenuItem(type: t, id: i, name: n, value: v.split(','));
  }

  @override
  String toString() {
    return '$id|$type|$name|${value.join(',')}';
  }
}
