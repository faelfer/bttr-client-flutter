import 'dart:math';
import '../entities/practice_statistics.dart';
import '../entities/skill.dart';
import '../entities/time_entry.dart';
import '../repositories/skill_repository.dart';
import '../repositories/time_repository.dart';

({DateTime initial, DateTime end}) monthRange(DateTime date) => (
  initial: DateTime(date.year, date.month),
  end: DateTime(
    date.year,
    date.month + 1,
  ).subtract(const Duration(milliseconds: 1)),
);

int workingDays(int year, int month, int lastDay) {
  var count = 0;
  for (var day = 1; day <= lastDay; day++) {
    if (DateTime(year, month, day).weekday <= DateTime.friday) count++;
  }
  return count;
}

PracticeStatistics calculateStatistics(Skill skill, int total, DateTime date) {
  final days = workingDays(
    date.year,
    date.month,
    DateTime(date.year, date.month + 1, 0).day,
  );
  final elapsed = workingDays(date.year, date.month, date.day);
  final remainingDays =
      days - elapsed + (date.weekday <= DateTime.friday ? 1 : 0);
  final goal = days * skill.daily;
  final ideal = elapsed * skill.daily;
  final remaining = max(0, goal - total);
  return PracticeStatistics(
    skill: skill,
    date: date,
    businessDays: days,
    goal: goal,
    ideal: ideal,
    total: total,
    percentage: goal > 0 ? total * 100 ~/ goal : 0,
    missing: max(0, ideal - total),
    remaining: remaining,
    suggestion: (remaining / max(1, remainingDays)).ceil(),
  );
}

class LoadStatistics {
  const LoadStatistics(this.skills, this.times);
  final SkillRepository skills;
  final TimeRepository times;
  Future<PracticeStatistics> call(int id, {DateTime? now}) async {
    final date = now ?? DateTime.now();
    final range = monthRange(date);
    final skillFuture = skills.get(id);
    final timesFuture = times.byDate(id, range.initial, range.end);
    // Future.wait attaches error handlers to both requests immediately.
    final results = await Future.wait<Object>([skillFuture, timesFuture]);
    final skill = results[0] as Skill;
    final entries = results[1] as List<TimeEntry>;
    final total = entries.fold<int>(0, (sum, entry) => sum + entry.minutes);
    return calculateStatistics(skill, total, date);
  }
}
