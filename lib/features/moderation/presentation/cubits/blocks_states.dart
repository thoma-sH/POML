import 'package:first_flutter_app/features/moderation/domain/entities/blocked_user.dart';

sealed class BlocksState {
  const BlocksState();
}

class BlocksInitial extends BlocksState {
  const BlocksInitial();
}

class BlocksLoading extends BlocksState {
  const BlocksLoading();
}

class BlocksLoaded extends BlocksState {
  const BlocksLoaded(this.blocked);
  final List<BlockedUser> blocked;
}

class BlocksFailure extends BlocksState {
  const BlocksFailure(this.message);
  final String message;
}
