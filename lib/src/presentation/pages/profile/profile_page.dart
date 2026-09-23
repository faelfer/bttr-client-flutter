import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/dependencies.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/usecases/validation.dart';
import '../../core/bloc/operation_bloc.dart';
import '../../widgets/common.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _bloc = OperationBloc<User>();
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final auth = context.read<Dependencies>().auth;
    _bloc.add(
      LoadRequested(() async {
        final user = await auth.profile();
        if (mounted) {
          _name.text = user.username;
          _email.text = user.email;
        }
        return user;
      }),
    );
  }

  void _save() {
    if (_bloc.state.busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final auth = context.read<Dependencies>().auth;
    final name = _name.text, email = _email.text;
    _bloc.add(MutationRequested(() => auth.updateProfile(name, email)));
  }

  Future<void> _delete() async {
    if (!await confirmDelete(
          context,
          'Excluir sua conta, habilidades e todos os seus registros de tempo? Esta ação não pode ser desfeita.',
        ) ||
        !mounted) {
      return;
    }
    final auth = context.read<Dependencies>().auth;
    _bloc.add(MutationRequested(auth.deleteProfile));
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const PageHeading(
        eyebrow: 'SUA CONTA',
        title: 'Meu perfil',
        subtitle: 'Um espaço para cuidar das suas informações.',
      ),
      OperationView(
        bloc: _bloc,
        retry: _load,
        builder: (context, state) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Panel(
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Informações pessoais',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _name,
                      validator: Validation.name,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.username],
                      decoration: const InputDecoration(
                        labelText: 'Nome de usuário',
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _email,
                      validator: Validation.email,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(labelText: 'E-mail'),
                      onFieldSubmitted: (_) => _save(),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Salvar alterações',
                      icon: Icons.check,
                      onPressed: _save,
                      busy: state.busy,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Segurança',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text('Atualize sua senha sempre que precisar.'),
                  TextButton.icon(
                    onPressed: state.busy
                        ? null
                        : () => context.go('/redefine-password'),
                    icon: const Icon(Icons.lock_outline),
                    label: const Text('Alterar senha'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Excluir conta',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sua conta, habilidades e registros de tempo serão apagados permanentemente.',
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: state.busy ? null : _delete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Excluir minha conta'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
