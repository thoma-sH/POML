import 'package:first_flutter_app/features/moderation/domain/entities/blocked_user.dart';
import 'package:first_flutter_app/features/moderation/domain/entities/report_reason.dart';

// Contract for the user-safety surfaces required by App Store
// Guideline 1.2: blocking, unblocking, and reporting posts or users.
// Production implementations route through `block_user`, `unblock_user`,
// `report_post`, and `report_user` Postgres RPCs; the mock keeps state
// in memory so the dev feed can filter blocked authors locally.
abstract class ModerationRepo {
  Future<List<BlockedUser>> getBlockedUsers();
  Future<void> blockUser({required String userId, required String username});
  Future<void> unblockUser(String userId);

  Future<void> reportPost({
    required String postId,
    required ReportReason reason,
    String? note,
  });

  Future<void> reportUser({
    required String userId,
    required ReportReason reason,
    String? note,
  });

  /// True when the local viewer has blocked the given author. Mock-only signal
  /// so the mock feed can hide their posts; in production RLS / SQL filters do
  /// this server-side.
  bool isBlocked(String userId);
}
