import 'skill.dart';

class TimeEntry {
  const TimeEntry({
    required this.id,
    required this.minutes,
    required this.created,
    required this.skill,
  });
  final int id;
  final int minutes;
  final DateTime created;
  final Skill skill;
}
