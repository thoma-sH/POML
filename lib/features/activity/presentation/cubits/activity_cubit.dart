import 'package:first_flutter_app/features/activity/domain/repos/activity_repo.dart';
import 'package:first_flutter_app/features/activity/presentation/cubits/activity_states.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ActivityCubit extends Cubit<ActivityState> {
  ActivityCubit({required ActivityRepo repo})
      : _repo = repo,
        super(const ActivityInitial());

  final ActivityRepo _repo;
  static const _pageSize = 30;

  Future<void> loadInitial() async {
    if (state is ActivityLoading) return;
    emit(const ActivityLoading());
    try {
      final traces = await _repo.getMyTraces(limit: _pageSize);
      emit(ActivityLoaded(
        traces: traces,
        hasMore: traces.length == _pageSize,
        isLoadingMore: false,
        cursor: traces.isEmpty ? null : traces.last.createdAt,
      ));
    } catch (_) {
      emit(const ActivityFailure('Couldn\'t load your traces.'));
    }
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! ActivityLoaded) return;
    if (!current.hasMore || current.isLoadingMore || current.cursor == null) {
      return;
    }
    emit(current.copyWith(isLoadingMore: true));
    try {
      final next = await _repo.getMyTraces(
        cursor: current.cursor,
        limit: _pageSize,
      );
      emit(current.copyWith(
        traces: [...current.traces, ...next],
        hasMore: next.length == _pageSize,
        isLoadingMore: false,
        cursor: next.isEmpty ? current.cursor : next.last.createdAt,
      ));
    } catch (_) {
      emit(current.copyWith(isLoadingMore: false));
    }
  }

  Future<void> refresh() => loadInitial();
}
