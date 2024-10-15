import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

class EnShortMessages implements timeago.EnShortMessages {
  @override
  String prefixAgo() => '';
  @override
  String prefixFromNow() => '';
  @override
  String suffixAgo() => '';
  @override
  String suffixFromNow() => '';
  @override
  String lessThanOneMinute(int seconds) => 'now';
  @override
  String aboutAMinute(int minutes) => '1m';
  @override
  String minutes(int minutes) => '${minutes}m';
  @override
  String aboutAnHour(int minutes) => '1h';
  @override
  String hours(int hours) => '${hours}h';
  @override
  String aDay(int hours) => '1d';
  @override
  String days(int days) => '${days}d';
  @override
  String aboutAMonth(int days) => '1mo';
  @override
  String months(int months) => '${months}mo';
  @override
  String aboutAYear(int year) => '1y';
  @override
  String years(int years) => '${years}y';
  @override
  String wordSeparator() => ' ';
}

String formatTime(DateTime? date) {
  timeago.setLocaleMessages('en_short', EnShortMessages());
  if (date == null) {
    return '';
  }
  final now = DateTime.now();
  if (now.difference(date).inDays < 3) {
    return timeago.format(date, locale: 'en_short');
  } else {
    return DateFormat.yMMMMd('en_US').format(date);
  }
}

String formatTimeAgo(DateTime? date) {
  timeago.setLocaleMessages('en_short', EnShortMessages());
  if (date == null) {
    return '';
  }
  final now = DateTime.now();
  if (now.year == date.year && now.month == date.month && now.day == date.day) {
    final elapsedTime = timeago.format(date, locale: 'en_short');
    return '$elapsedTime${elapsedTime == 'now' ? '' : ' ago'}';
  } else {
    return 'on ${DateFormat.yMMMMd('en_US').format(date)}';
  }
}

String formatDuration(Duration? duration) {
  if (duration == null) {
    return '';
  }
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60).abs();
  final seconds =
      duration.inSeconds.remainder(60).abs().toString().padLeft(2, '0');
  return '${duration.isNegative ? '-' : ''}${hours == 0 ? '' : '$hours:'}${hours == 0 ? minutes : minutes.toString().padLeft(2, '0')}:$seconds';
}
