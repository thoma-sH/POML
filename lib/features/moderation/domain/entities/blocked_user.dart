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
