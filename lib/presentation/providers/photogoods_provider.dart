import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_result.dart';
import '../../data/models/photogoods/search_photogoods.dart';
import '../../data/repositories/photogoods_repository.dart';

class PhotogoodsState {
  final List<SearchPhotogoods> items;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final int currentPage;
  final String currentQuery;

  const PhotogoodsState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.currentPage = 1,
    this.currentQuery = '',
  });

  PhotogoodsState copyWith({
    List<SearchPhotogoods>? items,
    bool? isLoading,
    String? error,
    bool? hasMore,
    int? currentPage,
    String? currentQuery,
    bool clearError = false,
  }) {
    return PhotogoodsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      currentQuery: currentQuery ?? this.currentQuery,
    );
  }
}

class PhotogoodsNotifier extends StateNotifier<PhotogoodsState> {
  final PhotogoodsRepository _repository;
  static const int _limit = 20;

  PhotogoodsNotifier(this._repository) : super(const PhotogoodsState());

  Future<void> searchPhotogoods(String query, {bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(
        items: [],
        currentPage: 1,
        hasMore: true,
        currentQuery: query,
        clearError: true,
      );
    }

    if (state.isLoading || (!refresh && !state.hasMore)) return;

    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.searchPhotogoods(
      query: query,
      page: state.currentPage.toString(),
      limit: _limit.toString(),
    );

    switch (result) {
      case ApiSuccess<SearchPhotogoodsData>(data: final data):
        final newItems = data.data;
        final allItems = refresh ? newItems : [...state.items, ...newItems];

        state = state.copyWith(
          items: allItems,
          isLoading: false,
          currentPage: state.currentPage + 1,
          hasMore: newItems.length == _limit,
          currentQuery: query,
        );
        break;
      case ApiError<SearchPhotogoodsData>(message: final message):
        state = state.copyWith(error: message, isLoading: false);
        break;
      case ApiLoading<SearchPhotogoodsData>():
        break;
    }
  }

  Future<void> loadMore() async {
    if (state.currentQuery.isNotEmpty) {
      await searchPhotogoods(state.currentQuery);
    }
  }

  void clearResults() {
    state = const PhotogoodsState();
  }
}

final photogoodsProvider = StateNotifierProvider<PhotogoodsNotifier, PhotogoodsState>((ref) {
  final repository = ref.read(photogoodsRepositoryProvider);
  return PhotogoodsNotifier(repository);
});

final photogoodsItemsProvider = Provider<List<SearchPhotogoods>>((ref) {
  return ref.watch(photogoodsProvider).items;
});

final photogoodsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(photogoodsProvider).isLoading;
});

final photogoodsErrorProvider = Provider<String?>((ref) {
  return ref.watch(photogoodsProvider).error;
});

final photogoodsHasMoreProvider = Provider<bool>((ref) {
  return ref.watch(photogoodsProvider).hasMore;
});