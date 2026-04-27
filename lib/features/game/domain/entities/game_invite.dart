import 'package:first_flutter_app/features/game/domain/entities/game_kind.dart';

// Lifecycle of a challenge before it becomes a session. `pending` is the
// only state where the recipient can act; `accepted` carries the
// resulting session id back to the caller.
enum GameInviteStatus { pending, accepted, declined, expired }

extension GameInviteStatusX on GameInviteStatus {
  static GameInviteStatus fromWire(String wireKey) {
    switch (wireKey) {
      case 'pending':
        return GameInviteStatus.pending;
      case 'accepted':
        return GameInviteStatus.accepted;
      case 'declined':
        return GameInviteStatus.declined;
      case 'expired':
        return GameInviteStatus.expired;
      default:
        throw ArgumentError('Unknown invite status: $wireKey');
    }
  }
}

// A challenge from one user to another to play a specific game. The row
// gets created by `create_game_invite` and resolved by `accept_game_invite`
// or `decline_game_invite`. `sessionId` is set when the invite is accepted.
class GameInvite {
  const GameInvite({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.kind,
    required this.status,
    required this.createdAt,
    this.sessionId,
    this.respondedAt,
  });

  final String id;
  final String fromId;
  final String toId;
  final GameKind kind;
  final GameInviteStatus status;
  final String? sessionId;
  final DateTime createdAt;
  final DateTime? respondedAt;

  factory GameInvite.fromRow(Map<String, dynamic> row) {
    return GameInvite(
      id: row['id'] as String,
      fromId: row['from_id'] as String,
      toId: row['to_id'] as String,
      kind: GameKindX.fromWire(row['kind'] as String),
      status: GameInviteStatusX.fromWire(row['status'] as String),
      sessionId: row['session_id'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      respondedAt: row['responded_at'] == null
          ? null
          : DateTime.parse(row['responded_at'] as String),
    );
  }
}
