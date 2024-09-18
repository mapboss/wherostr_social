class FeedMenuItem {
  final String type;
  final String name;
  final List<String> value;

  String? _id;
  String get id => _id ?? '';
  set id(String? v) => _id = v;

  FeedMenuItem({
    required String id,
    required this.name,
    required this.type,
    required this.value,
  }) : _id = id.toLowerCase();

  factory FeedMenuItem.fromString(String value) {
    final [i, t, n, v] = value.split('|');
    return FeedMenuItem(
        type: t,
        id: i,
        name: n,
        value: v.split(',').map((e) => e.toLowerCase()).toList());
  }

  @override
  String toString() {
    return '${id.toLowerCase()}|$type|$name|${value.map((e) => e.toLowerCase()).join(',')}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FeedMenuItem) return false;
    return other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
