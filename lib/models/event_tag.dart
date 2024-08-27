class EventTag {
  final String id;
  final String? marker;
  final String? pubkey;
  EventTag({
    required this.id,
    this.marker,
    this.pubkey,
  });

  factory EventTag.fromTag(List<String> tag) {
    return EventTag(
      id: tag.elementAt(1),
      marker: tag.elementAtOrNull(3),
      pubkey: tag.elementAtOrNull(4),
    );
  }

  toTag() {
    return [
      'e',
      id,
      if (marker != null) ...["", marker],
      if (marker != null && pubkey != null) pubkey,
    ];
  }
}
