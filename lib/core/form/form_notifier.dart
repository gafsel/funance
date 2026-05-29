import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class FormNotifier<I, O> extends StateNotifier<I> {
  FormNotifier(super.state);

  Future<O> submit();
}
