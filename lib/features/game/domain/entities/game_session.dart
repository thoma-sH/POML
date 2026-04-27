import 'package:first_flutter_app/features/game/domain/entities/game_kind.dart';

// Lifecycle of a session row. `active` is the only state where moves are
// accepted; `finished` is reached on a win, `forfeited` when one side
// quits early. Maps to `game_status_enum` server-side.
enum GameStatus { active, finished, forfeited }

extension GameStatusX on GameStatus {
  String get wireKey {
    switch (this) {
      case GameStatus.active:
        return 'active';
      case GameStatus.finished:
        return 'finished';
      case GameStatus.forfeited:
        return 'forfeited';
    }
  }

  static GameStatus fromWire(String wireKey) {
    switch (wireKey) {
      case 'active':
        return GameStatus.active;
      case 'finished':
        return GameStatus.finished;
      case 'forfeited':
        return GameStatus.forfeited;
      default:
        throw ArgumentError('Unknown game status: $wireKey');
    }
  }
}

// One row from the `game_sessions` table. The `state` jsonb is opaque
// at this layer — each game widget owns the shape of its own state and
// is responsible for parsing it. `currentTurnId` is null for games
// that don't use turn order (e.g. the 8-ball scorekeeper).
class GameSession {
  const GameSession({
    required this.id,
    required this.kind,
    required this.playerAId,
    required this.playerBId,
    required this.state,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.currentTurnId,
    this.winnerId,
    this.finishedAt,
  });

  final String id;
  final GameKind kind;
  final String playerAId;
  final String playerBId;
  final Map<String, dynamic> state;
  final String? currentTurnId;
  final GameStatus status;
  final String? winnerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? finishedAt;

  // Convenience: is the given user one of the two players in this session.
  bool involves(String userId) =>
      userId == playerAId || userId == playerBId;

  // The opponent's id from the perspective of `userId`. Throws if `userId`
  // isn't a player — callers should call `involves` first.
  String opponentOf(String userId) {
    if (userId == playerAId) return playerBId;
    if (userId == playerBId) return playerAId;
    throw ArgumentError('User $userId is not a player in this session');
  }

  // Builds a session from a `game_sessions` row (or an RPC return shape
  // with the same column names).
  factory GameSession.fromRow(Map<String, dynamic> row) {
    return GameSession(
      id: row['id'] as String,
      kind: GameKindX.fromWire(row['kind'] as String),
      playerAId: row['player_a_id'] as String,
      playerBId: row['player_b_id'] as String,
      state: Map<String, dynamic>.from(
        (row['state'] as Map?) ?? const <String, dynamic>{},
      ),
      currentTurnId: row['current_turn'] as String?,
      status: GameStatusX.fromWire(row['status'] as String),
      winnerId: row['winner_id'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
      finishedAt: row['finished_at'] == null
          ? null
          : DateTime.parse(row['finished_at'] as String),
    );
  }

  GameSession copyWith({
    Map<String, dynamic>? state,
    String? currentTurnId,
    GameStatus? status,
    String? winnerId,
    DateTime? updatedAt,
    DateTime? finishedAt,
  }) {
    return GameSession(
      id: id,
      kind: kind,
      playerAId: playerAId,
      playerBId: playerBId,
      state: state ?? this.state,
      currentTurnId: currentTurnId ?? this.currentTurnId,
      status: status ?? this.status,
      winnerId: winnerId ?? this.winnerId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      finishedAt: finishedAt ?? this.finishedAt,
    );
  }
}
