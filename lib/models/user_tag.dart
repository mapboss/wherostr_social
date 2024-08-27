class UserTag {
  final String pubkey;
  final String? marker;
  UserTag({
    required this.pubkey,
    this.marker,
  });

  factory UserTag.fromTag(List<String> tag) {
    return UserTag(
      pubkey: tag.elementAt(1),
      marker: tag.elementAtOrNull(3),
    );
  }
  List<String> toTag() {
    return [
      'p',
      pubkey,
      if (marker != null) ...[
        "",
        marker!,
      ],
    ];
  }
}
