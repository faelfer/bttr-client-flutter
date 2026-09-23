import '../entities/paged_result.dart';
import '../entities/skill.dart';
import '../repositories/skill_repository.dart';
import 'validation.dart';

class SkillUseCases {
  const SkillUseCases(this.repository);
  final SkillRepository repository;
  Future<PagedResult<Skill>> list(int page) =>
      repository.list(page < 1 ? 1 : page);
  Future<List<Skill>> all() => repository.all();
  Future<Skill> get(int id) => repository.get(id);
  Future<String> save({int? id, required String name, required int daily}) {
    Validation.require(Validation.name(name, max: 120));
    Validation.require(Validation.minutes('$daily'));
    return id == null
        ? repository.create(name.trim(), daily)
        : repository.update(id, name.trim(), daily);
  }

  Future<String> delete(int id) => repository.delete(id);
}
