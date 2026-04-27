import 'package:first_flutter_app/features/activity/domain/entities/activity_trace.dart';
import 'package:first_flutter_app/features/activity/domain/repos/activity_repo.dart';

// In-memory activity source backed by a fixed list spanning the last
// month, used in debug builds and to drive the profile preview while
// the production `get_my_traces` RPC isn't wired yet.
class MockActivityRepo implements ActivityRepo {
  @override
  Future<List<ActivityTrace>> getMyTraces({
    DateTime? cursor,
    int limit = 30,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final filtered = cursor == null
        ? _all
        : _all.where((t) => t.createdAt.isBefore(cursor)).toList();
    return filtered.take(limit).toList();
  }
}

final _now = DateTime.now();

final _all = <ActivityTrace>[
  ActivityTrace(
    id: 't1',
    kind: TraceKind.votedFits,
    text: 'voted FITS on sarah\'s sunsets post',
    createdAt: _now.subtract(const Duration(minutes: 12)),
    colorArgb: 0xFFE08A4D,
  ),
  ActivityTrace(
    id: 't2',
    kind: TraceKind.saved,
    text: 'saved a post in ivy\'s mossy',
    createdAt: _now.subtract(const Duration(hours: 1)),
    colorArgb: 0xFF6B8E6B,
  ),
  ActivityTrace(
    id: 't3',
    kind: TraceKind.wonGame,
    text: 'beat theo.k at chess (+1)',
    createdAt: _now.subtract(const Duration(hours: 3)),
    colorArgb: 0xFFB7A6F0,
  ),
  ActivityTrace(
    id: 't4',
    kind: TraceKind.posted,
    text: 'posted to your roadtrip shelf',
    createdAt: _now.subtract(const Duration(hours: 6)),
    colorArgb: 0xFF8C6CC4,
  ),
  ActivityTrace(
    id: 't5',
    kind: TraceKind.votedDoesntFit,
    text: 'voted DOESN\'T FIT on cass\'s coffee',
    createdAt: _now.subtract(const Duration(hours: 22)),
    colorArgb: 0xFFD17B8E,
  ),
  ActivityTrace(
    id: 't6',
    kind: TraceKind.followed,
    text: 'followed milo',
    createdAt: _now.subtract(const Duration(days: 1, hours: 4)),
    colorArgb: 0xFF6B7A8F,
  ),
  ActivityTrace(
    id: 't7',
    kind: TraceKind.votedFits,
    text: 'voted FITS on jun\'s highway post',
    createdAt: _now.subtract(const Duration(days: 1, hours: 8)),
    colorArgb: 0xFF8C6CC4,
  ),
  ActivityTrace(
    id: 't8',
    kind: TraceKind.posted,
    text: 'posted to your quiet shelf',
    createdAt: _now.subtract(const Duration(days: 2, hours: 1)),
    colorArgb: 0xFF6B7A8F,
  ),
  ActivityTrace(
    id: 't9',
    kind: TraceKind.saved,
    text: 'saved a post in milo\'s quiet',
    createdAt: _now.subtract(const Duration(days: 2, hours: 5)),
    colorArgb: 0xFF6B7A8F,
  ),
  ActivityTrace(
    id: 't10',
    kind: TraceKind.lostGame,
    text: 'lost a chess game to mira',
    createdAt: _now.subtract(const Duration(days: 3)),
    colorArgb: 0xFFB7A6F0,
  ),
  ActivityTrace(
    id: 't11',
    kind: TraceKind.votedFits,
    text: 'voted FITS on ivy\'s mossy post',
    createdAt: _now.subtract(const Duration(days: 3, hours: 6)),
    colorArgb: 0xFF6B8E6B,
  ),
  ActivityTrace(
    id: 't12',
    kind: TraceKind.followed,
    text: 'followed sarah',
    createdAt: _now.subtract(const Duration(days: 4)),
    colorArgb: 0xFFE08A4D,
  ),
  ActivityTrace(
    id: 't13',
    kind: TraceKind.posted,
    text: 'posted to your coffee shelf',
    createdAt: _now.subtract(const Duration(days: 5)),
    colorArgb: 0xFF8B5E3C,
  ),
  ActivityTrace(
    id: 't14',
    kind: TraceKind.wonGame,
    text: 'beat june at chess (+1)',
    createdAt: _now.subtract(const Duration(days: 6)),
    colorArgb: 0xFFB7A6F0,
  ),
  ActivityTrace(
    id: 't15',
    kind: TraceKind.saved,
    text: 'saved 3 posts in sarah\'s sunsets',
    createdAt: _now.subtract(const Duration(days: 8)),
    colorArgb: 0xFFE08A4D,
  ),
  ActivityTrace(
    id: 't16',
    kind: TraceKind.posted,
    text: 'posted to your sad shelf',
    createdAt: _now.subtract(const Duration(days: 11)),
    colorArgb: 0xFF3A3760,
  ),
  ActivityTrace(
    id: 't17',
    kind: TraceKind.votedFits,
    text: 'voted FITS on cass\'s coffee post',
    createdAt: _now.subtract(const Duration(days: 14)),
    colorArgb: 0xFF8B5E3C,
  ),
  ActivityTrace(
    id: 't18',
    kind: TraceKind.followed,
    text: 'followed jun',
    createdAt: _now.subtract(const Duration(days: 18)),
    colorArgb: 0xFF8C6CC4,
  ),
  ActivityTrace(
    id: 't19',
    kind: TraceKind.posted,
    text: 'posted to your highway shelf',
    createdAt: _now.subtract(const Duration(days: 22)),
    colorArgb: 0xFF8C6CC4,
  ),
  ActivityTrace(
    id: 't20',
    kind: TraceKind.other,
    text: 'joined lacuna',
    createdAt: _now.subtract(const Duration(days: 31)),
    colorArgb: 0xFFB7A6F0,
  ),
];
