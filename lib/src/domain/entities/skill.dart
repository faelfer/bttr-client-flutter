class Skill {
  const Skill({
    required this.id,
    required this.name,
    required this.daily,
    required this.created,
  });
  final int id;
  final String name;
  final int daily;
  final DateTime created;
}
