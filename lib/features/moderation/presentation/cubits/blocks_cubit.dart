import 'package:first_flutter_app/features/moderation/domain/repos/moderation_repo.dart';
import 'package:first_flutter_app/features/moderation/presentation/cubits/blocks_states.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Drives the Blocked Accounts settings page. Holds the current list of
// blocked users and exposes load/unblock — unblock re-runs load so the
// row disappears as soon as the server confirms.
class BlocksCubit extends Cubit<BlocksState> {
  BlocksCubit({required ModerationRepo repo})
      : _repo = repo,
        super(const BlocksInitial());

  final ModerationRepo _repo;

  Future<void> load() async {
    emit(const BlocksLoading());
    try {
      final list = await _repo.getBlockedUsers();
      emit(BlocksLoaded(list));
    } catch (e) {
      emit(BlocksFailure(_friendly(e)));
    }
  }

  Future<void> unblock(String userId) async {
    try {
      await _repo.unblockUser(userId);
      await load();
    } catch (e) {
      emit(BlocksFailure(_friendly(e)));
    }
  }

  String _friendly(Object e) =>
      e.toString().replaceFirst('Exception: ', '');
}
