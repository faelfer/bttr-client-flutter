import '../entities/paged_result.dart';
import '../entities/skill.dart';

abstract interface class SkillRepository {
  Future<PagedResult<Skill>> list(int page);
  Future<List<Skill>> all();
  Future<Skill> get(int id);
  Future<String> create(String name, int daily);
  Future<String> update(int id, String name, int daily);
  Future<String> delete(int id);
}
