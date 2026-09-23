import '../../domain/entities/paged_result.dart';
import '../../domain/entities/time_entry.dart';
import '../../domain/repositories/time_repository.dart';
import '../datasources/api_client.dart';
import '../models/api_models.dart';

class TimeRepositoryImpl implements TimeRepository {
  const TimeRepositoryImpl(this.api);
  final ApiClient api;
  @override
  Future<PagedResult<TimeEntry>> list(int page) async => ApiModels.page(
    await api.request('GET', '/times/times_by_page', query: {'page': '$page'}),
    ApiModels.time,
  );
  @override
  Future<List<TimeEntry>> byDate(
    int skillId,
    DateTime initial,
    DateTime end,
  ) async => ApiModels.list(
    (await api.request(
      'GET',
      '/times/times_by_date',
      query: {
        'skill_id': '$skillId',
        'date_initial': initial.toUtc().toIso8601String(),
        'date_final': end.toUtc().toIso8601String(),
      },
    ))['times'],
    ApiModels.time,
  );
  @override
  Future<TimeEntry> get(int id) async => ApiModels.time(
    (await api.request('GET', '/times/time_by_id/$id'))['time']
        as Map<String, dynamic>,
  );
  @override
  Future<String> create(int skillId, int minutes) => api.message(
    'POST',
    '/times/create_time',
    body: {'skill_id': skillId, 'minutes': minutes},
  );
  @override
  Future<String> update(int id, int skillId, int minutes) => api.message(
    'PUT',
    '/times/update_time_by_id/$id',
    body: {'skill_id': skillId, 'minutes': minutes},
  );
  @override
  Future<String> delete(int id) =>
      api.message('DELETE', '/times/delete_time_by_id/$id');
}
