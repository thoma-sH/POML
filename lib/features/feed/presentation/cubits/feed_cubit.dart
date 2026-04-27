import 'package:first_flutter_app/features/feed/domain/repos/feed_repo.dart';
import 'package:first_flutter_app/features/feed/presentation/cubits/feed_states.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Drives the feed page. Holds the current list of posts plus pagination
// state, and exposes loadInitial/loadMore/refresh as the only ways to
// mutate it. Friendly error messages translate raw Postgres exceptions
// (`not_authenticated`, `rate_limited`) into user-readable copy.
class FeedCubit extends Cubit<FeedState> {
  FeedCubit({required FeedRepo feedRepo})
      : _repo = feedRepo,
        super(const FeedInitial());

  final FeedRepo _repo;
  static const _pageSize = 20;

  // Fetches the first page. Used on cold start of the home feed; safe to
  // call again to retry from a Failure state.
  Future<void> loadInitial() async {
    if (state is FeedLoading) return;
    emit(const FeedLoading());
    try {
      final posts = await _repo.getFollowingFeed(limit: _pageSize);
      emit(FeedLoaded(
        posts: posts,
        hasMore: posts.length == _pageSize,
        isLoadingMore: false,
        cursor: posts.isEmpty ? null : posts.last.createdAt,
      ));
    } catch (e) {
      emit(FeedFailure(_friendly(e)));
    }
  }

  // Appends the next page using the oldest createdAt we've seen as the
  // cursor. No-ops if we're already loading more or there's nothing left.
  Future<void> loadMore() async {
    final current = state;
    if (current is! FeedLoaded) return;
    if (!current.hasMore || current.isLoadingMore || current.cursor == null) {
      return;
    }
    emit(current.copyWith(isLoadingMore: true));
    try {
      final next = await _repo.getFollowingFeed(
        cursor: current.cursor,
        limit: _pageSize,
      );
      emit(current.copyWith(
        posts: [...current.posts, ...next],
        hasMore: next.length == _pageSize,
        isLoadingMore: false,
        cursor: next.isEmpty ? current.cursor : next.last.createdAt,
      ));
    } catch (e) {
      emit(current.copyWith(isLoadingMore: false));
    }
  }

  // Replaces the current list with a fresh first page — used when a
  // user blocks someone and we need to drop their posts from view.
  Future<void> refresh() async {
    try {
      final posts = await _repo.getFollowingFeed(limit: _pageSize);
      emit(FeedLoaded(
        posts: posts,
        hasMore: posts.length == _pageSize,
        isLoadingMore: false,
        cursor: posts.isEmpty ? null : posts.last.createdAt,
      ));
    } catch (e) {
      emit(FeedFailure(_friendly(e)));
    }
  }

  String _friendly(Object e) {
    final msg = e.toString();
    if (msg.contains('not_authenticated')) return 'Sign in to see your feed.';
    if (msg.contains('rate_limited')) return 'Slow down — try again in a moment.';
    return 'Couldn\'t load the feed. Pull to retry.';
  }
}
