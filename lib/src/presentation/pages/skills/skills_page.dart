import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/dependencies.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/paged_result.dart';
import '../../../domain/entities/skill.dart';
import '../../core/bloc/operation_bloc.dart';
import '../../core/design/app_theme.dart';
import '../../widgets/common.dart';

class SkillsPage extends StatefulWidget {
  const SkillsPage({super.key});
  @override
  State<SkillsPage> createState() => _SkillsPageState();
}

class _SkillsPageState extends State<SkillsPage> {
  final _bloc = OperationBloc<PagedResult<Skill>>();
  int _page = 1;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _bloc.add(
    LoadRequested(() => context.read<Dependencies>().skills.list(_page)),
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
        eyebrow: 'PRATIQUE. APRENDA. EVOLUA.',
        title: 'Minhas habilidades',
        subtitle: 'O que você quer fazer um pouco melhor hoje?',
        action: PrimaryButton(
          label: 'Nova habilidade',
          identifier: 'bttr.skills.new',
          icon: Icons.add,
          onPressed: () => context.go('/skills/create'),
        ),
      ),
      Panel(
        color: BttrColors.lightGreen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CONSTRUA SUA CONSTÂNCIA',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.5,
                color: BttrColors.green,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Seu futuro começa\ncom o tempo de hoje.',
              style: TextStyle(
                fontSize: 27,
                height: 1.15,
                fontFamily: 'serif',
                color: BttrColors.ink,
              ),
            ),
            const SizedBox(height: 10),
            const Text('Escolha uma habilidade e dê o próximo passo.'),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => context.go('/times/create'),
              icon: const Icon(Icons.north_east, size: 18),
              label: const Text('Registrar meu tempo'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 28),
      OperationView(
        bloc: _bloc,
        retry: _load,
        builder: (context, state) {
          final data = state.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Suas habilidades · ${data.count}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              if (data.results.isEmpty)
                const EmptyPanel(
                  title: 'Sua próxima habilidade começa aqui.',
                  description:
                      'Crie uma habilidade e defina sua meta diária de prática.',
                  action: 'Criar primeira habilidade',
                  location: '/skills/create',
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 650 ? 2 : 1;
                    final width =
                        (constraints.maxWidth - 16 * (columns - 1)) / columns;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        for (var i = 0; i < data.results.length; i++)
                          SizedBox(
                            width: width,
                            child: _SkillCard(skill: data.results[i], index: i),
                          ),
                      ],
                    );
                  },
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

class _SkillCard extends StatelessWidget {
  const _SkillCard({required this.skill, required this.index});
  final Skill skill;
  final int index;
  static const icons = [
    Icons.menu_book_outlined,
    Icons.code,
    Icons.palette_outlined,
    Icons.translate,
    Icons.star_outline,
  ];
  static const colors = [
    Color(0xFFEDF4E4),
    Color(0xFFF0EBF6),
    Color(0xFFFBEEE3),
  ];
  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors[index % 3],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icons[index % icons.length], color: BttrColors.green),
            ),
            IconButton(
              tooltip: 'Editar ${skill.name}',
              onPressed: () => context.go('/skills/${skill.id}/update'),
              icon: const Icon(Icons.edit_outlined, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(skill.name, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Text('${durationLabel(skill.daily)} / dia útil'),
        const SizedBox(height: 18),
        const Divider(),
        TextButton.icon(
          onPressed: () => context.go('/skills/${skill.id}/statistic'),
          icon: const Icon(Icons.arrow_forward, size: 18),
          label: const Text('Ver estatísticas'),
        ),
      ],
    ),
  );
}
