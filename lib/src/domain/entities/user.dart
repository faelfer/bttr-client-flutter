class User {
  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.created,
  });
  final int id;
  final String username;
  final String email;
  final DateTime created;
}
