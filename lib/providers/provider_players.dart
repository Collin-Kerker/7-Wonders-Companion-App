import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/player.dart';
import '../firestore_repositories/player_repository.dart';

class PlayersNotifier extends Notifier<List<Player>> {
  final PlayerRepository _repo;
  StreamSubscription<List<Player>>? _sub;

  PlayersNotifier() : _repo = const PlayerRepository();

  @override
  List<Player> build() {
    _sub = _repo.watchPlayers().listen((playersList) {
      state = playersList;
    });

    ref.onDispose(() {
      _sub?.cancel();
    });

    return const [];
  }

  Future<void> upsertPlayer(Player player) async {
    try {
      print('PlayersNotifier.upsertPlayer: ${player.id} ${player.fullName}');
      await _repo.upsertPlayer(player);
    } catch (e, st) {
      print('PlayersNotifier.upsertPlayer error: $e\n$st');
      rethrow;
    }
  }

  Future<void> deletePlayer(String id) async {
    try {
      print('PlayersNotifier.deletePlayer: $id');
      await _repo.deletePlayer(id);
    } catch (e, st) {
      print('PlayersNotifier.deletePlayer error: $e\n$st');
      rethrow;
    }
  }
}

final playersProvider = NotifierProvider<PlayersNotifier, List<Player>>(
  () => PlayersNotifier(),
);
