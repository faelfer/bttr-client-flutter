import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/dependencies.dart';
import '../../../domain/entities/skill.dart';
import '../../../domain/usecases/validation.dart';
import '../../core/bloc/operation_bloc.dart';
import '../../widgets/common.dart';

class SkillFormPage extends StatefulWidget {
  const SkillFormPage({super.key, this.id});
  final int? id;
  @override
  State<SkillFormPage> createState() => _SkillFormPageState();
}

class _SkillFormPageState extends State<SkillFormPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _daily = TextEditingController(text: '30');
  late final _bloc = OperationBloc<Skill?>(initiallyLoaded: widget.id == null);
  @override
  void initState() {
    super.initState();
    if (widget.id != null) _load();
  }

  void _load() {
    final skills = context.read<Dependencies>().skills;
    _bloc.add(
      LoadRequested(() async {
        final skill = await skills.get(widget.id!);
        if (mounted) {
          _name.text = skill.name;
          _daily.text = '${skill.daily}';
        }
        return skill;
      }),
    );
  }

  void _save() {
    if (_bloc.state.busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final skills = context.read<Dependencies>().skills;
    final name = _name.text, daily = int.parse(_daily.text);
    _bloc.add(
      MutationRequested(
        () => skills.save(id: widget.id, name: name, daily: daily),
      ),
    );
  }

  Future<void> _delete() async {
    if (!await confirmDelete(
          context,
          'Excluir esta habilidade e todos os seus registros de tempo? Esta ação não pode ser desfeita.',
        ) ||
        !mounted) {
      return;
    }
    final skills = context.read<Dependencies>().skills;
    _bloc.add(MutationRequested(() => skills.delete(widget.id!)));
  }

  @override
  void dispose() {
    _name.dispose();
    _daily.dispose();
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const BackLink('Voltar às habilidades', '/home'),
      PageHeading(
        eyebrow: 'UM NOVO PASSO',
        title: widget.id == null ? 'Nova habilidade' : 'Editar habilidade',
        subtitle: 'Defina uma intenção. Transforme em prática.',
      ),
      OperationView(
        bloc: _bloc,
        retry: _load,
        onSuccess: (_) => context.go('/home'),
        builder: (context, state) => Panel(
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  identifier: 'bttr.skills.name',
                  child: TextFormField(
                    controller: _name,
                    validator: (value) => Validation.name(value, max: 120),
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Nome da habilidade',
                      hintText: 'Ex.: Inglês, programação, violão…',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Semantics(
                  identifier: 'bttr.skills.daily',
                  child: TextFormField(
                    controller: _daily,
                    validator: Validation.minutes,
                    keyboardType: TextInputType.number,
                    onFieldSubmitted: (_) => _save(),
                    decoration: const InputDecoration(
                      labelText: 'Meta diária em minutos',
                      helperText:
                          'Tempo que você deseja dedicar em cada dia útil.',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: widget.id == null
                      ? 'Criar habilidade'
                      : 'Salvar alterações',
                  identifier: widget.id == null ? 'bttr.skills.create' : null,
                  icon: Icons.check,
                  onPressed: _save,
                  busy: state.busy,
                ),
                TextButton(
                  onPressed: state.busy ? null : () => context.go('/home'),
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
                    label: const Text('Excluir habilidade'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 24),
      const TipPanel(
        title: 'Comece com uma meta possível.',
        text:
            'Quinze minutos por dia já fazem diferença. O mais importante é conseguir voltar amanhã.',
        icon: Icons.lightbulb_outline,
      ),
    ],
  );
}
