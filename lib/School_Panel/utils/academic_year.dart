// lib/School_Panel/utils/academic_year.dart

String computeCurrentAcademicYear({DateTime? asOf, int startMonth = 4}) {
  final now = asOf ?? DateTime.now();
  final year = now.year;
  final month = now.month;
  if (month >= startMonth) {
    final nextShort = (year + 1).toString().substring(2);
    return '$year-$nextShort';
  } else {
    final prev = year - 1;
    final curShort = year.toString().substring(2);
    return '$prev-$curShort';
  }
}

List<String> generateAcademicYearOptions({int past = 5, int future = 5, DateTime? asOf, int startMonth = 4}) {
  final now = asOf ?? DateTime.now();
  final List<String> years = [];
  for (int i = -past; i <= future; i++) {
    final d = DateTime(now.year + i, now.month, now.day);
    years.add(computeCurrentAcademicYear(asOf: d, startMonth: startMonth));
  }
  // Remove duplicates and sort
  final set = {...years};
  final list = set.toList();
  list.sort();
  return list;
}
