class SafeParser {
  static String? parseString(dynamic data) {
    return (data ?? '') != '' ? data : null;
  }

  static int? parseInt(dynamic data) {
    if (data is double) {
      return data.toInt();
    } else if (data is int) {
      return data;
    } else {
      return int.tryParse(data.toString());
    }
  }

  static List<dynamic> castToList(dynamic data) {
    return ((data['tags'] ?? []) as List<dynamic>)
        .map((t) => (t as List<dynamic>)
            .map((e) => SafeParser.parseString(e) ?? "")
            .toList())
        .toList();
  }

  static DateTime parseDateTime(dynamic data) {
    if (data is DateTime) return data;
    if (data is double) {
      data = data.toInt();
    }
    return data != null
        ? DateTime.fromMillisecondsSinceEpoch(data)
        : DateTime.timestamp();
  }
}
