class EventRefTag {
  final String id;
  final String? marker;
  final String? pubkey;
  EventRefTag({
    required this.id,
    this.marker,
    this.pubkey,
  });

  factory EventRefTag.fromTag(List<String> tag) {
    return EventRefTag(
      id: tag.elementAt(1),
      marker: tag.elementAtOrNull(3),
      pubkey: tag.elementAtOrNull(4),
    );
  }

  toTag() {
    return [
      'a',
      id,
      if (marker != null) ...["", marker],
      if (marker != null && pubkey != null) pubkey,
    ];
  }
}
