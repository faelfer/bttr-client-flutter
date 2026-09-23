import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/config/dependencies.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/practice_statistics.dart';
import '../../core/bloc/operation_bloc.dart';
import '../../core/design/app_theme.dart';
import '../../widgets/common.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key, required this.id});
  final int id;
  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final _bloc = OperationBloc<PracticeStatistics>();
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _bloc.add(
    LoadRequested(() => context.read<Dependencies>().statistics(widget.id)),
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
      const BackLink('Voltar às habilidades', '/home'),
      OperationView(
        bloc: _bloc,
        retry: _load,
        builder: (context, state) {
          final stats = state.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeading(
                eyebrow: 'SEU PROGRESSO EM FOCO',
                title: stats.skill.name,
                subtitle:
                    '${DateFormat('MMMM yyyy', 'pt_BR').format(stats.date)} · Cada prática aproxima você da sua meta.',
                action: PrimaryButton(
                  label: 'Registrar tempo',
                  icon: Icons.add,
                  onPressed: () =>
                      context.go('/times/create?skillId=${widget.id}'),
                ),
              ),
              _Metric(
                label: 'Tempo dedicado no mês',
                value: durationLabel(stats.total),
                caption: 'Todo esforço conta',
              ),
              const SizedBox(height: 12),
              _Metric(
                label: 'Meta mensal',
                value: durationLabel(stats.goal),
                caption: '${stats.businessDays} dias úteis de prática',
              ),
              const SizedBox(height: 12),
              _Metric(
                label: 'Meta diária',
                value: durationLabel(stats.skill.daily),
                caption: 'De segunda a sexta-feira',
              ),
              const SizedBox(height: 24),
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sua evolução neste mês',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    Text(stats.message),
                    const SizedBox(height: 20),
                    Text(
                      '${stats.percentage}%',
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w600,
                        color: BttrColors.green,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (stats.percentage / 100).clamp(0.0, 1.0),
                        minHeight: 10,
                        semanticsLabel: 'Progresso da meta mensal',
                        semanticsValue: '${stats.percentage.clamp(0, 100)}',
                        backgroundColor: BttrColors.lightGreen,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '${durationLabel(stats.total)} de prática · Meta: ${durationLabel(stats.goal)}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seu ritmo até hoje',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _Detail('Acumulado esperado', stats.ideal),
                    const Divider(),
                    _Detail('Falta para o acumulado de hoje', stats.missing),
                    const Divider(),
                    _Detail('Falta para a meta do mês', stats.remaining),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TipPanel(
                title: stats.remaining > 0
                    ? 'Uma sugestão para seguir.'
                    : 'Você chegou lá!',
                text: stats.remaining > 0
                    ? 'Dedique cerca de ${durationLabel(stats.suggestion)} por dia útil restante para alcançar sua meta mensal.'
                    : 'Sua meta mensal foi alcançada. Aproveite essa conquista e continue aprendendo.',
              ),
              const SizedBox(height: 12),
              const Text(
                'As metas consideram segunda a sexta, sem descontar feriados.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          );
        },
      ),
    ],
  );
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.caption,
  });
  final String label, value, caption;
  @override
  Widget build(BuildContext context) => Panel(
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label),
            const SizedBox(height: 4),
            Text(caption, style: const TextStyle(fontSize: 12)),
          ],
        ),
        Text(value, style: Theme.of(context).textTheme.headlineMedium),
      ],
    ),
  );
}

class _Detail extends StatelessWidget {
  const _Detail(this.label, this.minutes);
  final String label;
  final int minutes;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 16),
        Text(
          durationLabel(minutes),
          style: const TextStyle(
            color: BttrColors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
