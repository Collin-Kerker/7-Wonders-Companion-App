import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/player.dart';

class PlayerRepository {
  const PlayerRepository();

  CollectionReference<Map<String, dynamic>> get _playersRef =>
      FirebaseFirestore.instance.collection('players');

  /// Stream of players for the currently signed-in user.
  Stream<List<Player>> watchPlayers() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(const []);

    return _playersRef
        .where('ownerId', isEqualTo: uid)
        .orderBy('lastName')
        .orderBy('firstName')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => Player.fromDoc(doc)).toList());
  }

  Future<void> upsertPlayer(Player player) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final map = Map<String, dynamic>.from(player.toMap());
      if (uid != null) map['ownerId'] = uid;

      await _playersRef.doc(player.id).set(map, SetOptions(merge: true));
    } catch (e, st) {
      print('PlayerRepository.upsertPlayer error: $e\n$st');
      rethrow;
    }
  }

  Future<void> deletePlayer(String id) async {
    await _playersRef.doc(id).delete();
  }
}
