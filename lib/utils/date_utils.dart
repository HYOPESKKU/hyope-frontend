DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String formatDate(DateTime date) {
  return '${date.month}월 ${date.day}일';
}

String formatDateTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${date.month}/${date.day} $hour:$minute';
}

/// 그 날짜가 속한 주의 월요일(0시).
///
/// DateTime.weekday는 월=1 … 일=7이라 (weekday - 1)일을 빼면 월요일이 된다.
/// 일요일 시작으로 바꾸려면 이 함수만 고치면 된다.
DateTime startOfWeek(DateTime date) {
  final day = dateOnly(date);
  return day.subtract(Duration(days: day.weekday - 1));
}

/// 주의 마지막 날(일요일 0시). 범위 비교는 이 날의 "다음날 0시 미만"으로 한다.
DateTime endOfWeek(DateTime date) =>
    startOfWeek(date).add(const Duration(days: 6));

/// 그 시각이 해당 주에 속하는지.
///
/// 끝을 endOfWeek+1일 미만으로 비교하는 이유는 일요일 오후 통화도 그 주에
/// 포함시키기 위해서다. endOfWeek는 일요일 0시라 그것만으로는 잘린다.
bool isInWeek(DateTime moment, DateTime weekStart) {
  final start = startOfWeek(weekStart);
  final end = start.add(const Duration(days: 7));
  return !moment.isBefore(start) && moment.isBefore(end);
}

/// "8월 11일 ~ 8월 17일" — 해가 다르면 연도를 붙인다.
String formatWeekRange(DateTime weekStart) {
  final start = startOfWeek(weekStart);
  final end = endOfWeek(weekStart);
  if (start.year != end.year) {
    return '${start.year}년 ${formatDate(start)} ~ ${end.year}년 ${formatDate(end)}';
  }
  return '${formatDate(start)} ~ ${formatDate(end)}';
}
