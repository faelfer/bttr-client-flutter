import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/dependencies.dart';
import '../../../domain/usecases/time_usecases.dart';
import '../../../domain/usecases/validation.dart';
import '../../core/bloc/operation_bloc.dart';
import '../../widgets/common.dart';

class TimeFormPage extends StatefulWidget {
  const TimeFormPage({super.key, this.id, this.skillId});
  final int? id, skillId;
  @override
  State<TimeFormPage> createState() => _TimeFormPageState();
}

class _TimeFormPageState extends State<TimeFormPage> {
  final _form = GlobalKey<FormState>();
  final _minutes = TextEditingController(text: '25');
  final _bloc = OperationBloc<TimeFormData>();
  int? _skillId;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final times = context.read<Dependencies>().times;
    _bloc.add(
      LoadRequested(() async {
        final data = await times.loadForm(
          id: widget.id,
          selectedSkillId: widget.skillId,
        );
        if (mounted) {
          _skillId = data.selectedSkillId;
          _minutes.text = '${data.entry?.minutes ?? 25}';
        }
        return data;
      }),
    );
  }

  void _save() {
    if (_bloc.state.busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final times = context.read<Dependencies>().times;
    final minutes = int.parse(_minutes.text), skillId = _skillId!;
    _bloc.add(
      MutationRequested(
        () => times.save(id: widget.id, skillId: skillId, minutes: minutes),
      ),
    );
  }

  Future<void> _delete() async {
    if (!await confirmDelete(
          context,
          'Excluir este registro de tempo? Esta ação não pode ser desfeita.',
        ) ||
        !mounted) {
      return;
    }
    final times = context.read<Dependencies>().times;
    _bloc.add(MutationRequested(() => times.delete(widget.id!)));
  }

  @override
  void dispose() {
    _minutes.dispose();
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const BackLink('Voltar ao histórico', '/times'),
      PageHeading(
        eyebrow: 'TEMPO BEM INVESTIDO',
        title: widget.id == null ? 'Registrar tempo' : 'Editar tempo',
        subtitle: 'Celebre mais um momento dedicado a você.',
      ),
      OperationView(
        bloc: _bloc,
        retry: _load,
        onSuccess: (_) => context.go('/times'),
        builder: (context, state) {
          final data = state.data!;
          if (data.skills.isEmpty) {
            return const EmptyPanel(
              title: 'Primeiro, escolha o que quer aprender.',
              description:
                  'Você precisa criar uma habilidade antes de registrar tempo.',
              action: 'Criar habilidade',
              location: '/skills/create',
            );
          }
          return Panel(
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: _skillId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Habilidade'),
                    hint: const Text('Selecione uma habilidade'),
                    items: data.skills
                        .map(
                          (skill) => DropdownMenuItem(
                            value: skill.id,
                            child: Text(
                              skill.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: state.busy ? null : (value) => _skillId = value,
                    validator: (value) =>
                        value == null ? 'Selecione uma habilidade.' : null,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _minutes,
                    validator: Validation.minutes,
                    keyboardType: TextInputType.number,
                    onFieldSubmitted: (_) => _save(),
                    decoration: const InputDecoration(
                      labelText: 'Tempo dedicado em minutos',
                      helperText:
                          'O registro usa a data atual. A edição preserva a data original.',
                    ),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: widget.id == null
                        ? 'Registrar tempo'
                        : 'Salvar alterações',
                    icon: Icons.check,
                    onPressed: _save,
                    busy: state.busy,
                  ),
                  TextButton(
                    onPressed: state.busy ? null : () => context.go('/times'),
                    child: const Text('Cancelar'),
                  ),
                  if (widget.id != null) ...[
                    const Divider(),
                    TextButton.icon(
                      onPressed: state.busy ? null : _delete,
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Excluir registro'),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
      const SizedBox(height: 24),
      const TipPanel(
        title: 'Todo tempo dedicado é progresso.',
        text:
            'Uma sessão curta também conta. Registre sua prática e acompanhe sua evolução ao longo do mês.',
        icon: Icons.schedule,
      ),
    ],
  );
}
