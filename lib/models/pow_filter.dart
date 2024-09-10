class PoWfilter {
  int value;
  bool enabled;

  PoWfilter({
    required this.value,
    required this.enabled,
  });

  factory PoWfilter.fromString(String value) {
    final [v, e] = value.split('|');
    return PoWfilter(
        value: int.parse(v), enabled: bool.parse(e, caseSensitive: false));
  }

  @override
  String toString() {
    return '$value|$enabled';
  }
}
