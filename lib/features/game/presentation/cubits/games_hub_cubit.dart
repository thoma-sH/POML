import 'package:first_flutter_app/features/game/domain/entities/game_kind.dart';
import 'package:first_flutter_app/features/game/domain/repos/game_repo.dart';
import 'package:first_flutter_app/features/game/presentation/cubits/games_hub_states.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Drives the games hub landing page. Holds the viewer's active sessions
// (games already in progress) and pending invites (challenges waiting on
// a yes/no). Mutating actions — creating, accepting, declining invites —
// re-fetch on success so the hub stays consistent with the server.
class GamesHubCubit extends Cubit<GamesHubState> {
  GamesHubCubit({required GameRepo repo})
      : _repo = repo,
        super(const GamesHubInitial());

  final GameRepo _repo;

  // Initial fetch + retry-from-failure.
  Future<void> load() async {
    emit(const GamesHubLoading());
    try {
      final sessions = await _repo.getActiveSessions();
      final invites = await _repo.getPendingInvites();
      emit(GamesHubLoaded(
        activeSessions: sessions,
        pendingInvites: invites,
      ));
    } catch (e) {
      emit(GamesHubFailure(_friendly(e)));
    }
  }

  // Sends a new challenge. Returns the new invite id on success so the
  // caller can show a confirmation toast.
  Future<String?> createInvite({
    required String toUserId,
    required GameKind kind,
  }) async {
    try {
      final id = await _repo.createInvite(toUserId: toUserId, kind: kind);
      await load();
      return id;
    } catch (e) {
      emit(GamesHubFailure(_friendly(e)));
      return null;
    }
  }

  // Accepts a challenge and returns the resulting session id so the
  // caller can navigate straight into the session.
  Future<String?> accept(String inviteId) async {
    try {
      final sid = await _repo.acceptInvite(inviteId);
      await load();
      return sid;
    } catch (e) {
      emit(GamesHubFailure(_friendly(e)));
      return null;
    }
  }

  Future<void> decline(String inviteId) async {
    try {
      await _repo.declineInvite(inviteId);
      await load();
    } catch (e) {
      emit(GamesHubFailure(_friendly(e)));
    }
  }

  String _friendly(Object e) {
    final msg = e.toString();
    if (msg.contains('not_authenticated')) return 'Sign in to play.';
    if (msg.contains('rate_limited')) return 'Too many invites — slow down.';
    if (msg.contains('self_invite')) return 'Pick someone other than yourself.';
    return 'Something went wrong. Try again.';
  }
}
