import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/form/form_notifier.dart';

typedef Resetter<I> = Future<void> Function(I input);
typedef SetModelCallback = Function(VoidCallback);
typedef FormBuilder<I, O, N extends FormNotifier<I, O>> =
    Widget Function(BuildContext context, FormBuilderSnapshot<I, O, N> snapshot);

class FormBuilderSnapshot<I, O, N extends FormNotifier<I, O>> {
  final bool Function() validate;
  final N notifier;
  final I model;

  FormBuilderSnapshot({
    required this.validate,
    required this.notifier,
    required this.model,
  });
}

class ManualForm<I, O, N extends FormNotifier<I, O>> extends StatelessWidget {
  const ManualForm(this.provider, {super.key, required this.formBuilder});

  final AutoDisposeStateNotifierProvider<N, I> provider;
  final FormBuilder<I, O, N> formBuilder;

  @override
  Widget build(BuildContext context) {
    return _InnerManualForm<I, O, N>(
      provider: provider,
      formBuilder: formBuilder,
    );
  }
}

class _InnerManualForm<I, O, N extends FormNotifier<I, O>>
    extends ConsumerStatefulWidget {
  const _InnerManualForm({
    required this.provider,
    this.disableSubmitOnInvalid = false,
    required this.formBuilder,
  });

  final AutoDisposeStateNotifierProvider<N, I> provider;
  final bool disableSubmitOnInvalid;
  final FormBuilder<I, O, N> formBuilder;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _InnerManualFormState<I, O, N>();
}

class _InnerManualFormState<I, O, N extends FormNotifier<I, O>>
    extends ConsumerState<_InnerManualForm<I, O, N>> {
  final GlobalKey<FormState> _form = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(widget.provider.notifier);
    final model = ref.watch(widget.provider);

    return Form(
      key: _form,
      child: widget.formBuilder(
        context,
        FormBuilderSnapshot(
          notifier: notifier,
          model: model,
          validate: () => _validate(notifier),
        ),
      ),
    );
  }

  bool _validate(N notifier) {
    if (_form.currentState!.validate()) {
      _form.currentState!.save();

      return true;
    }

    return false;
  }
}
