import '../../domain/entities/paged_result.dart';
import '../../domain/entities/skill.dart';
import '../../domain/repositories/skill_repository.dart';
import '../datasources/api_client.dart';
import '../models/api_models.dart';

class SkillRepositoryImpl implements SkillRepository {
  const SkillRepositoryImpl(this.api);
  final ApiClient api;
  @override
  Future<PagedResult<Skill>> list(int page) async => ApiModels.page(
    await api.request(
      'GET',
      '/skills/skills_by_page',
      query: {'page': '$page'},
    ),
    ApiModels.skill,
  );
  @override
  Future<List<Skill>> all() async => ApiModels.list(
    (await api.request('GET', '/skills/skills_from_user'))['skills'],
    ApiModels.skill,
  );
  @override
  Future<Skill> get(int id) async => ApiModels.skill(
    (await api.request('GET', '/skills/skill_by_id/$id'))['skill']
        as Map<String, dynamic>,
  );
  @override
  Future<String> create(String name, int daily) => api.message(
    'POST',
    '/skills/create_skill',
    body: {'name': name, 'daily': daily},
  );
  @override
  Future<String> update(int id, String name, int daily) => api.message(
    'PUT',
    '/skills/update_skill_by_id/$id',
    body: {'name': name, 'daily': daily},
  );
  @override
  Future<String> delete(int id) =>
      api.message('DELETE', '/skills/delete_skill_by_id/$id');
}
