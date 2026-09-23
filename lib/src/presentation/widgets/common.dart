import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../core/bloc/operation_bloc.dart';
import '../core/design/app_theme.dart';

class Brand extends StatelessWidget {
  const Brand({super.key, this.light = false});
  final bool light;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: light ? const Color(0xFFD4E8B2) : BttrColors.green,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.bar_chart_rounded,
          color: light ? BttrColors.forest : Colors.white,
          size: 24,
        ),
      ),
      const SizedBox(width: 10),
      Flexible(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'bttr.',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5,
              color: light ? Colors.white : BttrColors.ink,
            ),
          ),
        ),
      ),
    ],
  );
}

class PageHeading extends StatelessWidget {
  const PageHeading({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.action,
  });
  final String eyebrow, title, subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: const TextStyle(
            fontSize: 10,
            letterSpacing: 1.8,
            fontWeight: FontWeight.w700,
            color: BttrColors.green,
          ),
        ),
        const SizedBox(height: 10),
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(subtitle),
        if (action != null) ...[const SizedBox(height: 20), action!],
      ],
    ),
  );
}

class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(22),
  });
  final Widget child;
  final Color color;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: BttrColors.line),
    ),
    child: child,
  );
}

class TipPanel extends StatelessWidget {
  const TipPanel({
    super.key,
    required this.title,
    required this.text,
    this.icon = Icons.auto_awesome_outlined,
  });
  final String title, text;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Panel(
    color: BttrColors.lightGreen,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: BttrColors.green),
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(text),
      ],
    ),
  );
}

class BackLink extends StatelessWidget {
  const BackLink(this.label, this.location, {super.key});
  final String label, location;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextButton.icon(
      onPressed: () => context.go(location),
      icon: const Icon(Icons.arrow_back, size: 18),
      label: Text(label),
    ),
  );
}

class EmptyPanel extends StatelessWidget {
  const EmptyPanel({
    super.key,
    required this.title,
    required this.description,
    required this.action,
    required this.location,
    this.icon = Icons.auto_awesome_outlined,
  });
  final String title, description, action, location;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      children: [
        const SizedBox(height: 16),
        Icon(icon, size: 40, color: BttrColors.green),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        Text(description, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () => context.go(location),
          icon: const Icon(Icons.add),
          label: Text(action),
        ),
        const SizedBox(height: 12),
      ],
    ),
  );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.icon = Icons.arrow_forward,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData icon;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton.icon(
      onPressed: busy ? null : onPressed,
      icon: busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, size: 20),
      label: Text(label, textAlign: TextAlign.center),
    ),
  );
}

class OperationView<T> extends StatelessWidget {
  const OperationView({
    super.key,
    required this.bloc,
    required this.builder,
    this.retry,
    this.onSuccess,
  });
  final OperationBloc<T> bloc;
  final Widget Function(BuildContext, OperationState<T>) builder;
  final VoidCallback? retry;
  final void Function(String)? onSuccess;
  @override
  Widget build(BuildContext context) =>
      BlocConsumer<OperationBloc<T>, OperationState<T>>(
        bloc: bloc,
        listener: (context, state) {
          if (state.success != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.success!)));
            onSuccess?.call(state.success!);
          }
        },
        builder: (context, state) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.busy)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: LinearProgressIndicator(semanticsLabel: 'Carregando'),
              ),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Semantics(
                  liveRegion: true,
                  child: Panel(
                    color: const Color(0xFFFFF3F3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        if (!state.loaded && retry != null)
                          TextButton.icon(
                            onPressed: state.busy ? null : retry,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Tentar novamente'),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            if (state.loaded) builder(context, state),
          ],
        ),
      );
}

class Pagination extends StatelessWidget {
  const Pagination({
    super.key,
    required this.page,
    required this.count,
    required this.onChange,
  });
  final int page, count;
  final ValueChanged<int> onChange;
  @override
  Widget build(BuildContext context) {
    if (count <= 5) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            tooltip: 'Página anterior',
            onPressed: page > 1 ? () => onChange(page - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Página $page de ${(count / 5).ceil()}'),
          ),
          IconButton(
            tooltip: 'Próxima página',
            onPressed: page * 5 < count ? () => onChange(page + 1) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

Future<bool> confirmDelete(BuildContext context, String message) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sim, excluir'),
          ),
        ],
      ),
    ) ??
    false;

class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    required this.validator,
    this.isNew = false,
    this.onSubmitted,
  });
  final TextEditingController controller;
  final String label;
  final String? Function(String?) validator;
  final bool isNew;
  final VoidCallback? onSubmitted;
  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool hidden = true;
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: widget.controller,
    obscureText: hidden,
    autocorrect: false,
    enableSuggestions: false,
    validator: widget.validator,
    autofillHints: [
      widget.isNew ? AutofillHints.newPassword : AutofillHints.password,
    ],
    onFieldSubmitted: (_) => widget.onSubmitted?.call(),
    decoration: InputDecoration(
      labelText: widget.label,
      suffixIcon: IconButton(
        tooltip: hidden
            ? 'Mostrar ${widget.label.toLowerCase()}'
            : 'Ocultar ${widget.label.toLowerCase()}',
        onPressed: () => setState(() => hidden = !hidden),
        icon: Icon(
          hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
      ),
    ),
  );
}
