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
