// The reasons a user can pick from when reporting a post or another
// user. The set is intentionally small and stable; the wireKey strings
// are what get persisted in the `reports.reason` column on Supabase.
// Don't rename a wireKey without writing a migration.
enum ReportReason {
  spam,
  harassment,
  nudity,
  violence,
  intellectualProperty,
  selfHarm,
  hate,
  other,
}

extension ReportReasonX on ReportReason {
  String get label {
    switch (this) {
      case ReportReason.spam:
        return 'spam or scam';
      case ReportReason.harassment:
        return 'harassment or bullying';
      case ReportReason.nudity:
        return 'nudity or sexual content';
      case ReportReason.violence:
        return 'violence or threats';
      case ReportReason.intellectualProperty:
        return 'copyright or trademark';
      case ReportReason.selfHarm:
        return 'self-harm';
      case ReportReason.hate:
        return 'hate speech';
      case ReportReason.other:
        return 'something else';
    }
  }

  /// Stable wire identifier sent to the server. Don't rename without a
  /// migration — these end up in the `reports.reason` column.
  String get wireKey {
    switch (this) {
      case ReportReason.spam:
        return 'spam';
      case ReportReason.harassment:
        return 'harassment';
      case ReportReason.nudity:
        return 'nudity';
      case ReportReason.violence:
        return 'violence';
      case ReportReason.intellectualProperty:
        return 'ip';
      case ReportReason.selfHarm:
        return 'self_harm';
      case ReportReason.hate:
        return 'hate';
      case ReportReason.other:
        return 'other';
    }
  }
}
