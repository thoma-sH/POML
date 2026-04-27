import 'package:first_flutter_app/features/game/domain/entities/game_invite.dart';
import 'package:first_flutter_app/features/game/domain/entities/game_kind.dart';
import 'package:first_flutter_app/features/game/domain/entities/game_session.dart';

// A simplified follow row used by the invite sheet to pick an opponent.
// Production SupabaseGameRepo populates this from the `follows` table;
// the mock returns a hardcoded set so dev builds work without a server.
class InvitableFriend {
  const InvitableFriend({required this.userId, required this.username});
  final String userId;
  final String username;
}

// Contract for the games feature. Covers the invite roundtrip, the
// active session, and the realtime push for opponent moves.
//
// Implementations are responsible for routing state correctly:
//  - createInvite returns the new invite id
//  - acceptInvite returns the resulting session id
//  - watchSession emits a fresh GameSession every time the row changes
//    (Supabase Realtime in production, an in-memory StreamController
//    in the mock so dev builds get the same UX)
abstract class GameRepo {
  Future<List<GameInvite>> getPendingInvites();
  Future<List<GameSession>> getActiveSessions();
  Future<List<InvitableFriend>> getInvitableFriends();

  Future<String> createInvite({
    required String toUserId,
    required GameKind kind,
  });
  Future<String> acceptInvite(String inviteId);
  Future<void> declineInvite(String inviteId);

  Future<GameSession> getSession(String sessionId);
  Future<void> submitMove({
    required String sessionId,
    required Map<String, dynamic> newState,
    String? nextTurnId,
    String? winnerId,
  });
  Future<void> forfeit(String sessionId);

  // Live updates for one session. Cancel by closing the subscription.
  Stream<GameSession> watchSession(String sessionId);
}
