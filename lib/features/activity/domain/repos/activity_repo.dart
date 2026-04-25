import 'package:first_flutter_app/features/activity/domain/entities/activity_trace.dart';

/// Reads the viewer's own activity history (their "traces") in reverse-chrono.
/// Keyset pagination: pass the oldest createdAt seen as `cursor` for the next page.
abstract class ActivityRepo {
  Future<List<ActivityTrace>> getMyTraces({
    DateTime? cursor,
    int limit = 30,
  });
}
