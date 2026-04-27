// The category of a trace. Used to pick an icon in the UI and to wire
// future server-side filtering. New kinds should be added at the end so
// existing on-device data with stored ordinals doesn't shift meaning.
enum TraceKind {
  votedFits,
  votedDoesntFit,
  saved,
  posted,
  wonGame,
  lostGame,
  followed,
  other,
}

// Pure-Dart representation of one row from the future `get_my_traces`
// RPC. The viewer's own action — voted, saved, posted, won a game, etc.
// `colorArgb` is optional accent (e.g. the blob color of the post the
// trace relates to); the row falls back to the theme accent when null.
class ActivityTrace {
  const ActivityTrace({
    required this.id,
    required this.kind,
    required this.text,
    required this.createdAt,
    this.colorArgb,
  });

  final String id;
  final TraceKind kind;
  final String text;
  final DateTime createdAt;
  final int? colorArgb;

  String get timeAgoString {
    final delta = DateTime.now().difference(createdAt);
    if (delta.inDays >= 7) return '${(delta.inDays / 7).floor()}w';
    if (delta.inDays >= 1) return '${delta.inDays}d';
    if (delta.inHours >= 1) return '${delta.inHours}h';
    if (delta.inMinutes >= 1) return '${delta.inMinutes}m';
    return 'now';
  }
}
