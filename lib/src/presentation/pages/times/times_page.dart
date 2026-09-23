import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/dependencies.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/paged_result.dart';
import '../../../domain/entities/time_entry.dart';
import '../../core/bloc/operation_bloc.dart';
import '../../core/design/app_theme.dart';
import '../../widgets/common.dart';

class TimesPage extends StatefulWidget {
  const TimesPage({super.key});
  @override
  State<TimesPage> createState() => _TimesPageState();
}

class _TimesPageState extends State<TimesPage> {
  final _bloc = OperationBloc<PagedResult<TimeEntry>>();
  int _page = 1;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _bloc.add(
    LoadRequested(() => context.read<Dependencies>().times.list(_page)),
  );
  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      PageHeading(
        eyebrow: 'CADA MINUTO CONTA',
        title: 'Histórico de tempo',
        subtitle: 'Veja os pequenos passos que estão levando você adiante.',
        action: PrimaryButton(
          label: 'Registrar tempo',
          identifier: 'bttr.times.new',
          icon: Icons.add,
          onPressed: () => context.go('/times/create'),
        ),
      ),
      OperationView(
        bloc: _bloc,
        retry: _load,
        builder: (context, state) {
          final data = state.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Suas práticas · ${data.count}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              const Text(
                'Mais recentes primeiro',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 18),
              if (data.results.isEmpty)
                const EmptyPanel(
                  title: 'Seu tempo conta uma história.',
                  description: 'Registre sua primeira prática para começar.',
                  action: 'Registrar primeiro tempo',
                  location: '/times/create',
                  icon: Icons.schedule,
                ),
              for (final entry in data.results)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.menu_book_outlined,
                              color: BttrColors.green,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  alignment: Alignment.centerLeft,
                                ),
                                onPressed: () => context.go(
                                  '/skills/${entry.skill.id}/statistic',
                                ),
                                child: Text(entry.skill.name),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Editar registro de ${entry.skill.name}',
                              onPressed: () =>
                                  context.go('/times/${entry.id}/update'),
                              icon: const Icon(Icons.edit_outlined, size: 20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: BttrColors.lightGreen,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                durationLabel(entry.minutes),
                                style: const TextStyle(
                                  color: BttrColors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              dateLabel(entry.created),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              Pagination(
                page: _page,
                count: data.count,
                onChange: (page) {
                  if (_bloc.state.busy) return;
                  _page = page;
                  _load();
                },
              ),
            ],
          );
        },
      ),
    ],
  );
}
