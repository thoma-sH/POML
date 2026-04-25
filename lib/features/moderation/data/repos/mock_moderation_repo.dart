import 'package:first_flutter_app/features/moderation/domain/entities/blocked_user.dart';
import 'package:first_flutter_app/features/moderation/domain/entities/report_reason.dart';
import 'package:first_flutter_app/features/moderation/domain/repos/moderation_repo.dart';

/// In-memory mock. The block set is process-global so the mock feed repo
/// can read it for filtering — they share state across the app session.
class MockModerationRepo implements ModerationRepo {
  static final Map<String, BlockedUser> _blocks = {};

  static bool isUserBlocked(String userId) => _blocks.containsKey(userId);

  @override
  Future<List<BlockedUser>> getBlockedUsers() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final list = _blocks.values.toList()
      ..sort((a, b) => b.blockedAt.compareTo(a.blockedAt));
    return list;
  }

  @override
  Future<void> blockUser({
    required String userId,
    required String username,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    _blocks[userId] = BlockedUser(
      userId: userId,
      username: username,
      blockedAt: DateTime.now(),
    );
  }

  @override
  Future<void> unblockUser(String userId) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    _blocks.remove(userId);
  }

  @override
  Future<void> reportPost({
    required String postId,
    required ReportReason reason,
    String? note,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }

  @override
  Future<void> reportUser({
    required String userId,
    required ReportReason reason,
    String? note,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }

  @override
  bool isBlocked(String userId) => _blocks.containsKey(userId);
}
