import 'dart:async';

import 'package:first_flutter_app/features/game/domain/entities/game_invite.dart';
import 'package:first_flutter_app/features/game/domain/entities/game_kind.dart';
import 'package:first_flutter_app/features/game/domain/entities/game_session.dart';
import 'package:first_flutter_app/features/game/domain/repos/game_repo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Production game repo. Reads / writes via the `game_invites` and
// `game_sessions` tables (RLS scopes both to involved users) and routes
// state-changing actions through the security-definer RPCs declared in
// the schema. Realtime updates come from Supabase Realtime — every
// session gets its own channel keyed by session id.
class SupabaseGameRepo implements GameRepo {
  final _client = Supabase.instance.client;

  String get _uid {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw Exception('not_authenticated');
    return id;
  }

  @override
  Future<List<InvitableFriend>> getInvitableFriends() async {
    // Pull the people the viewer follows; they're the candidates for an
    // invite. The join hits the existing `users_public` view to honor
    // soft-deletes.
    final rows = await _client
        .from('follows')
        .select('following_id, profile:following_id ( username )')
        .eq('follower_id', _uid)
        .order('created_at', ascending: false);
    return rows.map((r) {
      final p = (r['profile'] as Map<String, dynamic>?) ?? const {};
      return InvitableFriend(
        userId: r['following_id'] as String,
        username: (p['username'] as String?) ?? '',
      );
    }).toList(growable: false);
  }

  @override
  Future<List<GameInvite>> getPendingInvites() async {
    final rows = await _client
        .from('game_invites')
        .select()
        .eq('to_id', _uid)
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return rows.map(GameInvite.fromRow).toList(growable: false);
  }

  @override
  Future<List<GameSession>> getActiveSessions() async {
    final rows = await _client
        .from('game_sessions')
        .select()
        .or('player_a_id.eq.$_uid,player_b_id.eq.$_uid')
        .eq('status', 'active')
        .order('updated_at', ascending: false);
    return rows.map(GameSession.fromRow).toList(growable: false);
  }

  @override
  Future<String> createInvite({
    required String toUserId,
    required GameKind kind,
  }) async {
    final id = await _client.rpc(
      'create_game_invite',
      params: {'_to_id': toUserId, '_kind': kind.wireKey},
    );
    return id as String;
  }

  @override
  Future<String> acceptInvite(String inviteId) async {
    final id = await _client.rpc(
      'accept_game_invite',
      params: {'_invite_id': inviteId},
    );
    return id as String;
  }

  @override
  Future<void> declineInvite(String inviteId) async {
    await _client.rpc(
      'decline_game_invite',
      params: {'_invite_id': inviteId},
    );
  }

  @override
  Future<GameSession> getSession(String sessionId) async {
    final row = await _client
        .from('game_sessions')
        .select()
        .eq('id', sessionId)
        .maybeSingle();
    if (row == null) throw Exception('not_found');
    return GameSession.fromRow(row);
  }

  @override
  Future<void> submitMove({
    required String sessionId,
    required Map<String, dynamic> newState,
    String? nextTurnId,
    String? winnerId,
  }) async {
    await _client.rpc('submit_game_move', params: {
      '_session_id': sessionId,
      '_new_state': newState,
      '_next_turn': nextTurnId,
      '_winner_id': winnerId,
    });
  }

  @override
  Future<void> forfeit(String sessionId) async {
    await _client.rpc('forfeit_game', params: {'_session_id': sessionId});
  }

  @override
  Stream<GameSession> watchSession(String sessionId) {
    // Use a broadcast controller so the page rebuilds whenever a row
    // change comes in over the Realtime channel. The seed value is an
    // immediate fetch so the UI doesn't flash empty while waiting for
    // the first Postgres event.
    final controller = StreamController<GameSession>.broadcast();
    final channel = _client.channel('game:$sessionId');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'game_sessions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: sessionId,
          ),
          callback: (payload) {
            final row = payload.newRecord;
            controller.add(GameSession.fromRow(row));
          },
        )
        .subscribe();

    getSession(sessionId).then(controller.add).catchError(controller.addError);

    controller.onCancel = () => channel.unsubscribe();
    return controller.stream;
  }
}
