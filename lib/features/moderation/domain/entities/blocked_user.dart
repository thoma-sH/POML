// A flat row for the Blocked Accounts list. Pulled from the `blocks`
// table joined with the blocked user's profile so the UI can render
// avatar + username without a second roundtrip.
class BlockedUser {
  const BlockedUser({
    required this.userId,
    required this.username,
    required this.blockedAt,
    this.avatarUrl,
  });

  final String userId;
  final String username;
  final String? avatarUrl;
  final DateTime blockedAt;
}
