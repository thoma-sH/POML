// Whether a post's media is a still photo or a clip. Mirrors the
// `media_type_enum` defined in the Supabase schema.
enum FeedMediaType { photo, video }

// Pure-Dart entity representing one row from the `get_following_feed` RPC.
// Holds everything a feed tile renders — author, album, media, counts,
// and the viewer's existing vote (null when the viewer hasn't voted).
// `aspectRatio` and `commentCount` are UI-only and default to 1.0 / 0
// because the database doesn't store them yet.
class FeedPost {
  const FeedPost({
    required this.postId,
    required this.authorId,
    required this.authorUsername,
    required this.mediaUrl,
    required this.mediaType,
    required this.fitsCount,
    required this.doesntFitCount,
    required this.savesCount,
    required this.netScore,
    required this.createdAt,
    this.authorAvatarUrl,
    this.albumId,
    this.albumTitle,
    this.albumDescription,
    this.albumColorArgb,
    this.caption,
    this.latitude,
    this.longitude,
    this.viewerVotedFits,
    this.locationLabel,
    this.aspectRatio = 1.0,
    this.commentCount = 0,
  });

  final String postId;
  final String authorId;
  final String authorUsername;
  final String? authorAvatarUrl;
  final String? albumId;
  final String? albumTitle;
  final String? albumDescription;
  final int? albumColorArgb;
  final String? caption;
  final String mediaUrl;
  final FeedMediaType mediaType;
  final double? latitude;
  final double? longitude;
  final int fitsCount;
  final int doesntFitCount;
  final int savesCount;
  final int netScore;
  final DateTime createdAt;
  final bool? viewerVotedFits;
  final String? locationLabel;
  final double aspectRatio;
  final int commentCount;

  // Builds a FeedPost from one row returned by `get_following_feed`.
  // Column names here must match the RPC's RETURNS TABLE declaration.
  factory FeedPost.fromRpcRow(Map<String, dynamic> row) {
    return FeedPost(
      postId: row['post_id'] as String,
      authorId: row['author_id'] as String,
      authorUsername: row['author_username'] as String,
      authorAvatarUrl: row['author_avatar_url'] as String?,
      albumId: row['album_id'] as String?,
      albumTitle: row['album_title'] as String?,
      albumDescription: row['album_description'] as String?,
      albumColorArgb: _parseHex(row['album_color'] as String?),
      caption: row['caption'] as String?,
      mediaUrl: row['media_url'] as String,
      mediaType: (row['media_type'] as String?) == 'video'
          ? FeedMediaType.video
          : FeedMediaType.photo,
      latitude: (row['latitude'] as num?)?.toDouble(),
      longitude: (row['longitude'] as num?)?.toDouble(),
      fitsCount: row['fits_count'] as int,
      doesntFitCount: row['doesnt_fit_count'] as int,
      savesCount: row['saves_count'] as int,
      netScore: row['net_score'] as int,
      createdAt: DateTime.parse(row['created_at'] as String),
      viewerVotedFits: row['viewer_voted_fits'] as bool?,
    );
  }

  // Compact relative timestamp ("2h", "3d", "now") derived from createdAt.
  // Computed at render time so it stays accurate without re-fetching.
  String get timeAgoString {
    final delta = DateTime.now().difference(createdAt);
    if (delta.inDays >= 1) return '${delta.inDays}d';
    if (delta.inHours >= 1) return '${delta.inHours}h';
    if (delta.inMinutes >= 1) return '${delta.inMinutes}m';
    return 'now';
  }

  static int? _parseHex(String? hex) {
    if (hex == null || !hex.startsWith('#') || hex.length != 7) return null;
    return int.tryParse('FF${hex.substring(1)}', radix: 16);
  }
}
