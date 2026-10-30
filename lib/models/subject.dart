class Subject {
  final String id;
  String name;

  /// Classes counted before dates were tracked (also holds data saved by
  /// the older version of the app).
  int baseAttended;
  int baseTotal;

  /// One entry per day: 'yyyy-MM-dd' -> true (present) / false (absent).
  final Map<String, bool> records;

  /// Weekdays this subject has class (1 = Monday ... 7 = Sunday).
  List<int> days;

  Subject({
    required this.id,
    required this.name,
    this.baseAttended = 0,
    this.baseTotal = 0,
    Map<String, bool>? records,
    List<int>? days,
  })  : records = records ?? {},
        days = days ?? [1, 2, 3, 4, 5];

  static String keyFor(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

  int get attended => baseAttended + records.values.where((v) => v).length;
  int get total => baseTotal + records.length;

  double get percentage => total == 0 ? 0 : attended / total * 100;

  /// true = present, false = absent, null = not marked on that day.
  bool? statusOn(DateTime d) => records[keyFor(d)];

  /// Does this subject have a class on the weekday of [d]?
  bool isScheduledOn(DateTime d) => days.contains(d.weekday);

  /// How many more classes can be missed while staying at or above [target]%.
  int classesCanMiss(double target) {
    final t = target / 100;
    final v = (attended / t - total + 1e-9).floor();
    return v < 0 ? 0 : v;
  }

  /// How many consecutive classes must be attended to reach [target]%.
  int classesNeeded(double target) {
    if (total == 0 || percentage >= target) return 0;
    final t = target / 100;
    return ((t * total - attended) / (1 - t) - 1e-9).ceil();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'baseAttended': baseAttended,
    'baseTotal': baseTotal,
    'records': records,
    'days': days,
  };

  factory Subject.fromJson(Map<String, dynamic> json) {
    final rawDays = json['days'];
    final days = rawDays is List ? rawDays.map((e) => e as int).toList() : null;
    final rawRecords = json['records'];

    if (rawRecords is Map) {
      return Subject(
        id: json['id'] as String,
        name: json['name'] as String,
        baseAttended: (json['baseAttended'] as int?) ?? 0,
        baseTotal: (json['baseTotal'] as int?) ?? 0,
        records: rawRecords.map((k, v) => MapEntry(k as String, v as bool)),
        days: days,
      );
    }
    // Older saved data: only counts, no dates.
    return Subject(
      id: json['id'] as String,
      name: json['name'] as String,
      baseAttended: (json['attended'] as int?) ?? 0,
      baseTotal: (json['total'] as int?) ?? 0,
      days: days,
    );
  }
}