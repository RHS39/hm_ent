import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../catalog/domain/entities/product_entity.dart';
import '../../../catalog/data/datasources/catalog_remote_datasource.dart';

enum SearchStatus { initial, loading, success, empty, failure }

class SearchState extends Equatable {
  const SearchState({this.query = '', this.results = const [], this.status = SearchStatus.initial, this.recentSearches = const [], this.suggestions = const []});
  final String query;
  final List<ProductEntity> results;
  final SearchStatus status;
  final List<String> recentSearches;
  final List<String> suggestions;
  int get resultCount => results.length;
  SearchState copyWith({String? query, List<ProductEntity>? results, SearchStatus? status, List<String>? recentSearches, List<String>? suggestions}) => SearchState(query: query ?? this.query, results: results ?? this.results, status: status ?? this.status, recentSearches: recentSearches ?? this.recentSearches, suggestions: suggestions ?? this.suggestions);
  @override
  List<Object?> get props => [query, results, status, recentSearches, suggestions];
}

class SearchCubit extends Cubit<SearchState> {
  SearchCubit() : super(const SearchState()) {
    _loadRecent();
  }

  Timer? _debounce;
  final CatalogMockDataSource _ds = CatalogMockDataSource();

  void _loadRecent() {
    emit(state.copyWith(recentSearches: _recent.toList()));
  }

  static final List<String> _recent = ['jaggery', 'chikki', 'kakvi'];

  Future<void> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      emit(state.copyWith(query: '', results: [], status: SearchStatus.initial));
      return;
    }
    _debounce?.cancel();
    emit(state.copyWith(query: q, status: SearchStatus.loading));
    try {
      final results = await _ds.getProducts(query: q, limit: 50);
      if (results.isEmpty) {
        emit(state.copyWith(results: [], status: SearchStatus.empty));
      } else {
        emit(state.copyWith(results: results, status: SearchStatus.success));
      }
    } catch (e) {
      emit(state.copyWith(status: SearchStatus.failure));
    }
  }

  void searchDebounced(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => search(query));
  }

  void addRecent(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    _recent.remove(q);
    _recent.insert(0, q);
    if (_recent.length > 10) _recent.removeLast();
    emit(state.copyWith(recentSearches: List<String>.from(_recent)));
  }

  void removeRecent(String query) {
    _recent.remove(query);
    emit(state.copyWith(recentSearches: List<String>.from(_recent)));
  }

  void clearRecent() {
    _recent.clear();
    emit(state.copyWith(recentSearches: []));
  }

  void clear() {
    emit(state.copyWith(query: '', results: [], status: SearchStatus.initial));
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
