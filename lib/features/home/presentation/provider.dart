import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/home/presentation/controller/overview_notifier.dart';
import 'package:funances/features/home/presentation/model/overview_view_model.dart';

class HomeViewProviders {
  static final period = StateProvider((ref) => DateTime.now());

  static final viewType = StateProvider((ref) => SummaryViewType.effective);

  static final summary = NotifierProvider<SummaryNotifier, SummaryState>(() => SummaryNotifier());
}
