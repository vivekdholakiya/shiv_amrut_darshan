import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ramayan_item.dart';
import 'language_provider.dart';

class HistoryNotifier extends StateNotifier<List<shivItem>> {
  final Ref _ref;

  HistoryNotifier(this._ref)
      : super(_ref.read(localStorageServiceProvider).getRecentlyViewed());

  Future<void> recordView(shivItem item) async {
    final storage = _ref.read(localStorageServiceProvider);
    await storage.addRecentlyViewed(item);
    await storage.setContinueReading(item);
    state = storage.getRecentlyViewed();
    _ref.read(continueReadingProvider.notifier).refresh();
  }

  void clear() {
    state = [];
  }
}

final historyProvider =
    StateNotifierProvider<HistoryNotifier, List<shivItem>>((ref) {
  return HistoryNotifier(ref);
});

class ContinueReadingNotifier extends StateNotifier<shivItem?> {
  final Ref _ref;

  ContinueReadingNotifier(this._ref)
      : super(_ref.read(localStorageServiceProvider).getContinueReading());

  void refresh() {
    state = _ref.read(localStorageServiceProvider).getContinueReading();
  }

  void clear() {
    state = null;
  }
}

final continueReadingProvider =
    StateNotifierProvider<ContinueReadingNotifier, shivItem?>((ref) {
  return ContinueReadingNotifier(ref);
});
