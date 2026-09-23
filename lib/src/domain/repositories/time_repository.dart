import '../entities/paged_result.dart';
import '../entities/time_entry.dart';

abstract interface class TimeRepository {
  Future<PagedResult<TimeEntry>> list(int page);
  Future<List<TimeEntry>> byDate(int skillId, DateTime initial, DateTime end);
  Future<TimeEntry> get(int id);
  Future<String> create(int skillId, int minutes);
  Future<String> update(int id, int skillId, int minutes);
  Future<String> delete(int id);
}
