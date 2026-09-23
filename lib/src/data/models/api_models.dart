import '../../domain/entities/paged_result.dart';
import '../../domain/entities/skill.dart';
import '../../domain/entities/time_entry.dart';
import '../../domain/entities/user.dart';

abstract final class ApiModels {
  static User user(Map<String, dynamic> json) => User(
    id: (json['id'] as num).toInt(),
    username: json['username'] as String,
    email: json['email'] as String,
    created: DateTime.parse(json['created'] as String),
  );

  static Skill skill(Map<String, dynamic> json) => Skill(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String,
    daily: (json['daily'] as num).toInt(),
    created: DateTime.parse(json['created'] as String),
  );

  static TimeEntry time(Map<String, dynamic> json) => TimeEntry(
    id: (json['id'] as num).toInt(),
    minutes: (json['minutes'] as num).toInt(),
    created: DateTime.parse(json['created'] as String),
    skill: skill(json['skill'] as Map<String, dynamic>),
  );

  static List<T> list<T>(
    dynamic json,
    T Function(Map<String, dynamic>) parse,
  ) => (json as List<dynamic>)
      .map((item) => parse(item as Map<String, dynamic>))
      .toList(growable: false);

  static PagedResult<T> page<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) parse,
  ) => PagedResult(
    count: (json['count'] as num).toInt(),
    results: list(json['results'], parse),
    next: json['next'] as String?,
    previous: json['previous'] as String?,
  );
}
