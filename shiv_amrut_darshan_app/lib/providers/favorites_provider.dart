import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ramayan_item.dart';
import 'language_provider.dart';

class FavoritesNotifier extends StateNotifier<List<shivItem>> {
  final Ref _ref;

  FavoritesNotifier(this._ref)
      : super(_ref.read(localStorageServiceProvider).getFavorites());

  Future<void> toggleFavorite(shivItem item) async {
    final storage = _ref.read(localStorageServiceProvider);
    await storage.toggleFavorite(item);
    state = storage.getFavorites();
  }

  bool isFavorite(String itemId, String categoryId) {
    return state.any((item) => item.id == itemId && item.category == categoryId);
  }

  void clear() {
    state = [];
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, List<shivItem>>((ref) {
  return FavoritesNotifier(ref);
});
