import 'skill.dart';

class PracticeStatistics {
  const PracticeStatistics({
    required this.skill,
    required this.date,
    required this.businessDays,
    required this.goal,
    required this.ideal,
    required this.total,
    required this.percentage,
    required this.missing,
    required this.remaining,
    required this.suggestion,
  });
  final Skill skill;
  final DateTime date;
  final int businessDays,
      goal,
      ideal,
      total,
      percentage,
      missing,
      remaining,
      suggestion;
  String get message => total >= goal
      ? 'Meta do mês concluída. Excelente trabalho!'
      : total >= ideal
      ? 'Você está em dia com sua meta. Continue assim!'
      : 'Um passo de cada vez. Ainda dá para avançar.';
}
