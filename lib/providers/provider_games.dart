import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/game.dart';
import '../firestore_repositories/game_repository.dart';

class GamesNotifier extends Notifier<List<Game>> {
  final GameRepository _repo;
  StreamSubscription<List<Game>>? _sub;

  GamesNotifier() : _repo = const GameRepository();

  @override
  List<Game> build() {
    _sub = _repo.watchGames().listen((gamesList) {
      state = gamesList;
    });

    ref.onDispose(() {
      _sub?.cancel();
    });

    return const [];
  }

  Future<void> upsertGame(Game game) async {
    try {
      print('GamesNotifier.upsertGame: ${game.id} ${game.name}');
      await _repo.upsertGame(game);
    } catch (e, st) {
      print('GamesNotifier.upsertGame error: $e\n$st');
      rethrow;
    }
  }

  Future<void> deleteGame(String id) async {
    try {
      print('GamesNotifier.deleteGame: $id');
      await _repo.deleteGame(id);
    } catch (e, st) {
      print('GamesNotifier.deleteGame error: $e\n$st');
      rethrow;
    }
  }
}

final gamesProvider = NotifierProvider<GamesNotifier, List<Game>>(
  () => GamesNotifier(),
);
