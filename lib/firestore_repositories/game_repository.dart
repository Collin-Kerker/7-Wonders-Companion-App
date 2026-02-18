import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/game.dart';

class GameRepository {
  const GameRepository();

  CollectionReference<Map<String, dynamic>> get _gamesRef =>
      FirebaseFirestore.instance.collection('games');

  /// Stream of games for the currently signed-in user, newest first.
  Stream<List<Game>> watchGames() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(const []);

    return _gamesRef
        .where('ownerId', isEqualTo: uid)
        .orderBy('datePlayed', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => Game.fromDoc(doc)).toList());
  }

  Future<void> upsertGame(Game game) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final map = Map<String, dynamic>.from(game.toMap());
      if (uid != null) map['ownerId'] = uid;

      await _gamesRef.doc(game.id).set(map, SetOptions(merge: true));
    } catch (e, st) {
      print('GameRepository.upsertGame error: $e\n$st');
      rethrow;
    }
  }

  Future<void> deleteGame(String id) async {
    await _gamesRef.doc(id).delete();
  }
}
