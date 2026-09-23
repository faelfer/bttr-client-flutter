import '../../core/utils/app_exception.dart';
import '../entities/paged_result.dart';
import '../entities/skill.dart';
import '../entities/time_entry.dart';
import '../repositories/skill_repository.dart';
import '../repositories/time_repository.dart';
import 'validation.dart';

class TimeFormData {
  const TimeFormData(this.skills, this.entry, this.selectedSkillId);
  final List<Skill> skills;
  final TimeEntry? entry;
  final int? selectedSkillId;
}

class TimeUseCases {
  const TimeUseCases(this.repository, this.skills);
  final TimeRepository repository;
  final SkillRepository skills;
  Future<PagedResult<TimeEntry>> list(int page) =>
      repository.list(page < 1 ? 1 : page);
  Future<TimeFormData> loadForm({int? id, int? selectedSkillId}) async {
    final results = await Future.wait<Object?>([
      skills.all(),
      if (id != null) repository.get(id),
    ]);
    final options = results[0] as List<Skill>;
    final entry = id == null ? null : results[1] as TimeEntry;
    final candidate = entry?.skill.id ?? selectedSkillId;
    return TimeFormData(
      options,
      entry,
      options.any((skill) => skill.id == candidate) ? candidate : null,
    );
  }

  Future<String> save({int? id, required int skillId, required int minutes}) {
    if (skillId <= 0) throw const AppException('Selecione uma habilidade.');
    Validation.require(Validation.minutes('$minutes'));
    return id == null
        ? repository.create(skillId, minutes)
        : repository.update(id, skillId, minutes);
  }

  Future<String> delete(int id) => repository.delete(id);
}
