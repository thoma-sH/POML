import 'dart:async';

import 'package:first_flutter_app/features/game/domain/entities/game_invite.dart';
import 'package:first_flutter_app/features/game/domain/entities/game_kind.dart';
import 'package:first_flutter_app/features/game/domain/entities/game_session.dart';
import 'package:first_flutter_app/features/game/domain/repos/game_repo.dart';

// In-memory game repo used in debug builds. State is process-global so
// any place that constructs a fresh MockGameRepo sees the same sessions
// and invites. watchSession returns a broadcast stream backed by the
// same controllers each instance writes into on every move.
class MockGameRepo implements GameRepo {
  static const _viewerId = 'mock-viewer-self';

  static final List<GameInvite> _invites = [];
  static final Map<String, GameSession> _sessions = {};
  static final Map<String, StreamController<GameSession>> _watchers = {};

  // For dev-mode solo play: when the mock auto-accepts an invite the
  // inviter just sent, we record the resulting session id here so the
  // UI can navigate them straight into the game without waiting on a
  // second player.
  static String? _lastAutoStartedSessionId;
  static String? consumeLastAutoStartedSessionId() {
    final id = _lastAutoStartedSessionId;
    _lastAutoStartedSessionId = null;
    return id;
  }

  static const List<InvitableFriend> _friends = [
    InvitableFriend(userId: 'mock-author-sarah', username: 'sarah'),
    InvitableFriend(userId: 'mock-author-milo', username: 'milo'),
    InvitableFriend(userId: 'mock-author-ivy', username: 'ivy'),
    InvitableFriend(userId: 'mock-author-jun', username: 'jun'),
    InvitableFriend(userId: 'mock-author-cass', username: 'cass'),
    InvitableFriend(userId: 'mock-author-theo', username: 'theo.k'),
    InvitableFriend(userId: 'mock-author-mira', username: 'mira'),
  ];

  @override
  Future<List<InvitableFriend>> getInvitableFriends() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _friends;
  }

  @override
  Future<List<GameInvite>> getPendingInvites() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _invites
        .where((i) =>
            i.status == GameInviteStatus.pending && i.toId == _viewerId)
        .toList();
  }

  @override
  Future<List<GameSession>> getActiveSessions() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _sessions.values
        .where((s) =>
            s.status == GameStatus.active &&
            (s.playerAId == _viewerId || s.playerBId == _viewerId))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<String> createInvite({
    required String toUserId,
    required GameKind kind,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final id = 'invite-${DateTime.now().microsecondsSinceEpoch}';
    final invite = GameInvite(
      id: id,
      fromId: _viewerId,
      toId: toUserId,
      kind: kind,
      status: GameInviteStatus.pending,
      createdAt: DateTime.now(),
    );
    _invites.add(invite);
    // Solo dev mode: auto-accept synchronously so the sender lands in
    // the game without waiting for a real opponent. The session id is
    // stashed on the static field so the UI can pick it up and route.
    final sessionId = await acceptInvite(id);
    _lastAutoStartedSessionId = sessionId;
    return id;
  }

  @override
  Future<String> acceptInvite(String inviteId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final i = _invites.indexWhere((x) => x.id == inviteId);
    if (i < 0) throw Exception('not_found');
    final invite = _invites[i];
    final sid = 'session-${DateTime.now().microsecondsSinceEpoch}';
    final now = DateTime.now();
    final session = GameSession(
      id: sid,
      kind: invite.kind,
      playerAId: invite.fromId,
      playerBId: invite.toId,
      state: const {},
      currentTurnId: invite.fromId,
      status: GameStatus.active,
      createdAt: now,
      updatedAt: now,
    );
    _sessions[sid] = session;
    _invites[i] = GameInvite(
      id: invite.id,
      fromId: invite.fromId,
      toId: invite.toId,
      kind: invite.kind,
      status: GameInviteStatus.accepted,
      sessionId: sid,
      createdAt: invite.createdAt,
      respondedAt: now,
    );
    return sid;
  }

  @override
  Future<void> declineInvite(String inviteId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final i = _invites.indexWhere((x) => x.id == inviteId);
    if (i < 0) return;
    final invite = _invites[i];
    _invites[i] = GameInvite(
      id: invite.id,
      fromId: invite.fromId,
      toId: invite.toId,
      kind: invite.kind,
      status: GameInviteStatus.declined,
      createdAt: invite.createdAt,
      respondedAt: DateTime.now(),
    );
  }

  @override
  Future<GameSession> getSession(String sessionId) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final s = _sessions[sessionId];
    if (s == null) throw Exception('not_found');
    return s;
  }

  @override
  Future<void> submitMove({
    required String sessionId,
    required Map<String, dynamic> newState,
    String? nextTurnId,
    String? winnerId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final s = _sessions[sessionId];
    if (s == null) throw Exception('not_found');
    if (s.status != GameStatus.active) throw Exception('not_active');
    final updated = s.copyWith(
      state: newState,
      currentTurnId: nextTurnId ?? s.currentTurnId,
      status: winnerId == null ? GameStatus.active : GameStatus.finished,
      winnerId: winnerId,
      updatedAt: DateTime.now(),
      finishedAt: winnerId == null ? null : DateTime.now(),
    );
    _sessions[sessionId] = updated;
    _watchers[sessionId]?.add(updated);
  }

  @override
  Future<void> forfeit(String sessionId) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final s = _sessions[sessionId];
    if (s == null) throw Exception('not_found');
    final opponent = s.playerAId == _viewerId ? s.playerBId : s.playerAId;
    final updated = s.copyWith(
      status: GameStatus.forfeited,
      winnerId: opponent,
      updatedAt: DateTime.now(),
      finishedAt: DateTime.now(),
    );
    _sessions[sessionId] = updated;
    _watchers[sessionId]?.add(updated);
  }

  @override
  Stream<GameSession> watchSession(String sessionId) {
    final controller = _watchers.putIfAbsent(
      sessionId,
      () => StreamController<GameSession>.broadcast(),
    );
    final current = _sessions[sessionId];
    if (current != null) {
      Future<void>.microtask(() => controller.add(current));
    }
    return controller.stream;
  }

  // Stable id used as the "viewer" in mock-only flows. Real builds get
  // this from Supabase.auth.currentUser.id.
  static String get viewerId => _viewerId;
}
