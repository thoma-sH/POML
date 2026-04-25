import 'package:first_flutter_app/features/moderation/domain/entities/blocked_user.dart';
import 'package:first_flutter_app/features/moderation/domain/entities/report_reason.dart';

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
