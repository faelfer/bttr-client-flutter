import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/dependencies.dart';
import '../../../domain/usecases/validation.dart';
import '../../core/bloc/operation_bloc.dart';
import '../../core/design/app_theme.dart';
import '../../widgets/common.dart';

enum AuthMode { signIn, signUp, forgot }

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.mode});
  final AuthMode mode;
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _bloc = OperationBloc<void>(initiallyLoaded: true);
  bool get signIn => widget.mode == AuthMode.signIn;
  bool get signUp => widget.mode == AuthMode.signUp;
  String get title => signIn
      ? 'Bom ter você\nde volta.'
      : signUp
      ? 'Comece sua\nevolução.'
      : 'Vamos recuperar\nseu acesso.';
  String get subtitle => signIn
      ? 'Entre para continuar investindo em você.'
      : signUp
      ? 'Crie sua conta e dê espaço a novas habilidades.'
      : 'Enviaremos um link para redefinir sua senha por e-mail.';
  String get submitLabel => signIn
      ? 'Entrar'
      : signUp
      ? 'Criar minha conta'
      : 'Enviar link de recuperação';

  void _submit() {
    if (_bloc.state.busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final auth = context.read<Dependencies>().auth;
    final email = _email.text, password = _password.text, name = _name.text;
    _bloc.add(
      MutationRequested(() async {
        if (signIn) {
          await auth.signIn(email, password);
          return 'Bem-vindo de volta!';
        }
        if (signUp) return auth.signUp(name, email, password);
        return auth.forgotPassword(email);
      }),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: BttrColors.forest,
              padding: const EdgeInsets.all(26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Brand(light: true),
                  const SizedBox(height: 22),
                  const Text(
                    'Talento é um começo.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      letterSpacing: -0.7,
                    ),
                  ),
                  const Text(
                    'Constância é o caminho.',
                    style: TextStyle(
                      color: Color(0xFFD3E7B3),
                      fontSize: 24,
                      fontFamily: 'serif',
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Uma habilidade, um dia de cada vez.',
                    style: TextStyle(color: Color(0xFFB9D1C5), fontSize: 12),
                  ),
                ],
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(26, 32, 26, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PageHeading(
                        eyebrow: 'BEM-VINDO AO BTTR',
                        title: title,
                        subtitle: subtitle,
                      ),
                      OperationView<void>(
                        bloc: _bloc,
                        onSuccess: (_) {
                          if (!signIn) context.go('/');
                        },
                        builder: (context, state) => Form(
                          key: _form,
                          child: AutofillGroup(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (signUp) ...[
                                  TextFormField(
                                    controller: _name,
                                    validator: Validation.name,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    autofillHints: const [
                                      AutofillHints.username,
                                    ],
                                    textInputAction: TextInputAction.next,
                                    decoration: const InputDecoration(
                                      labelText: 'Nome de usuário',
                                      hintText: 'Como podemos chamar você?',
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                ],
                                Semantics(
                                  identifier: 'bttr.auth.email',
                                  child: TextFormField(
                                    controller: _email,
                                    validator: Validation.email,
                                    keyboardType: TextInputType.emailAddress,
                                    autofillHints: const [AutofillHints.email],
                                    autocorrect: false,
                                    textInputAction: TextInputAction.next,
                                    decoration: const InputDecoration(
                                      labelText: 'E-mail',
                                      hintText: 'voce@exemplo.com',
                                    ),
                                  ),
                                ),
                                if (widget.mode != AuthMode.forgot) ...[
                                  const SizedBox(height: 22),
                                  PasswordField(
                                    controller: _password,
                                    identifier: 'bttr.auth.password',
                                    label: 'Senha',
                                    isNew: signUp,
                                    validator: (value) => Validation.password(
                                      value,
                                      isNew: signUp,
                                    ),
                                    onSubmitted: _submit,
                                  ),
                                  if (signUp)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 8),
                                      child: Text(
                                        'De 4 a 128 caracteres, com maiúscula, minúscula, número e símbolo.',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                ],
                                if (signIn)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: state.busy
                                          ? null
                                          : () =>
                                                context.go('/forgot-password'),
                                      child: const Text('Esqueceu a senha?'),
                                    ),
                                  ),
                                const SizedBox(height: 20),
                                PrimaryButton(
                                  label: submitLabel,
                                  identifier: signIn
                                      ? 'bttr.auth.signIn'
                                      : null,
                                  onPressed: _submit,
                                  busy: state.busy,
                                ),
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: state.busy
                                      ? null
                                      : () => context.go(
                                          signIn ? '/sign-up' : '/',
                                        ),
                                  child: Text(
                                    signIn
                                        ? 'Ainda não tem conta? Cadastre-se'
                                        : 'Voltar ao login',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Seu tempo merece um propósito.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
