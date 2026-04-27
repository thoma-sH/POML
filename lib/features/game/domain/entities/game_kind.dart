// The set of games Lacuna currently supports. The wireKey strings match
// the `game_kind_enum` declared in the Supabase schema — never rename
// one without writing a migration. `isPlayable` lets the games hub
// render "coming soon" tiles for kinds that don't have a widget yet.
enum GameKind {
  ticTacToe,
  eightBall,
  friendOrFoe,
  fitsOrDoesnt,
}

extension GameKindX on GameKind {
  String get displayName {
    switch (this) {
      case GameKind.ticTacToe:
        return 'Tic-tac-toe';
      case GameKind.eightBall:
        return '8-ball';
      case GameKind.friendOrFoe:
        return 'Friend or Foe';
      case GameKind.fitsOrDoesnt:
        return 'Fits or Doesn\'t';
    }
  }

  String get tagline {
    switch (this) {
      case GameKind.ticTacToe:
        return 'three in a row, the old way';
      case GameKind.eightBall:
        return 'rack \'em — track the score';
      case GameKind.friendOrFoe:
        return 'how well do you know them';
      case GameKind.fitsOrDoesnt:
        return 'guess the verdict together';
    }
  }

  String get wireKey {
    switch (this) {
      case GameKind.ticTacToe:
        return 'tic_tac_toe';
      case GameKind.eightBall:
        return 'eight_ball';
      case GameKind.friendOrFoe:
        return 'friend_or_foe';
      case GameKind.fitsOrDoesnt:
        return 'fits_or_doesnt';
    }
  }

  // True when there's a real widget to render this game. The games hub
  // shows "coming soon" badges on tiles where this is false.
  bool get isPlayable {
    switch (this) {
      case GameKind.ticTacToe:
      case GameKind.eightBall:
        return true;
      case GameKind.friendOrFoe:
      case GameKind.fitsOrDoesnt:
        return false;
    }
  }

  static GameKind fromWire(String wireKey) {
    switch (wireKey) {
      case 'tic_tac_toe':
        return GameKind.ticTacToe;
      case 'eight_ball':
        return GameKind.eightBall;
      case 'friend_or_foe':
        return GameKind.friendOrFoe;
      case 'fits_or_doesnt':
        return GameKind.fitsOrDoesnt;
      default:
        throw ArgumentError('Unknown game kind: $wireKey');
    }
  }
}
