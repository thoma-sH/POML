import 'package:first_flutter_app/features/activity/domain/entities/activity_trace.dart';

sealed class ActivityState {
  const ActivityState();
}

class ActivityInitial extends ActivityState {
  const ActivityInitial();
}

class ActivityLoading extends ActivityState {
  const ActivityLoading();
}

class ActivityLoaded extends ActivityState {
  const ActivityLoaded({
    required this.traces,
    required this.hasMore,
    required this.isLoadingMore,
    required this.cursor,
  });

  final List<ActivityTrace> traces;
  final bool hasMore;
  final bool isLoadingMore;
  final DateTime? cursor;

  ActivityLoaded copyWith({
    List<ActivityTrace>? traces,
    bool? hasMore,
    bool? isLoadingMore,
    DateTime? cursor,
  }) {
    return ActivityLoaded(
      traces: traces ?? this.traces,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      cursor: cursor ?? this.cursor,
    );
  }
}

class ActivityFailure extends ActivityState {
  const ActivityFailure(this.message);
  final String message;
}
