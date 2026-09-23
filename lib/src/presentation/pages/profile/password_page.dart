import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/dependencies.dart';
import '../../../domain/usecases/validation.dart';
import '../../core/bloc/operation_bloc.dart';
import '../../widgets/common.dart';

class PasswordPage extends StatefulWidget {
  const PasswordPage({super.key});
  @override
  State<PasswordPage> createState() => _PasswordPageState();
}

class _PasswordPageState extends State<PasswordPage> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirmation = TextEditingController();
  final _bloc = OperationBloc<void>(initiallyLoaded: true);
  void _save() {
    if (_bloc.state.busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final auth = context.read<Dependencies>().auth;
    final current = _current.text,
        next = _next.text,
        confirmation = _confirmation.text;
    _bloc.add(
      MutationRequested(
        () => auth.redefinePassword(current, next, confirmation),
      ),
    );
  }

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirmation.dispose();
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const BackLink('Voltar ao perfil', '/profile'),
      const PageHeading(
        eyebrow: 'SEGURANÇA',
        title: 'Alterar senha',
        subtitle: 'Escolha uma nova senha para proteger sua conta.',
      ),
      OperationView(
        bloc: _bloc,
        onSuccess: (_) => context.go('/profile'),
        builder: (context, state) => Panel(
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PasswordField(
                  controller: _current,
                  label: 'Senha atual',
                  validator: Validation.password,
                ),
                const SizedBox(height: 24),
                PasswordField(
                  controller: _next,
                  label: 'Nova senha',
                  isNew: true,
                  validator: (value) => Validation.password(value, isNew: true),
                ),
                const SizedBox(height: 8),
                const Text(
                  'De 4 a 128 caracteres, com maiúscula, minúscula, número e símbolo.',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 24),
                PasswordField(
                  controller: _confirmation,
                  label: 'Confirmar nova senha',
                  isNew: true,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Confirme sua nova senha.'
                      : value != _next.text
                      ? 'As senhas não coincidem.'
                      : null,
                  onSubmitted: _save,
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Salvar nova senha',
                  icon: Icons.check,
                  onPressed: _save,
                  busy: state.busy,
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}
