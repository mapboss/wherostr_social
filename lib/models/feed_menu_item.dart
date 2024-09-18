class FeedMenuItem {
  final String type;

  String? _id;
  String get id => _id ?? '';
  set id(String? v) => _id = v;

  String? _name;
  String get name => _name ?? '';
  set name(String? v) => _name = v;

  final List<String> value;

  FeedMenuItem({
    required String id,
    required String name,
    required this.type,
    required this.value,
  })  : _id = id.toLowerCase(),
        _name = name.toLowerCase();

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
    return '${id.toLowerCase()}|$type|${name.toLowerCase()}|${value.map((e) => e.toLowerCase()).join(',')}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FeedMenuItem) return false;
    return other.toString() == toString();
  }

  @override
  int get hashCode => toString().hashCode;
}
