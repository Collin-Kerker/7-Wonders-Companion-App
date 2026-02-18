import 'package:cloud_firestore/cloud_firestore.dart';
import 'player_score.dart';

class Game {
  final String id;
  final String name;
  final DateTime datePlayed;
  final List<PlayerScore> playerScores;
  final DateTime? lastEditedAt;

  Game({
    required this.id,
    required this.name,
    required this.datePlayed,
    required this.playerScores,
    this.lastEditedAt,
  });

  Map<String, dynamic> toMap() {
    final map = {
      'name': name,
      'datePlayed': Timestamp.fromDate(datePlayed),
      'playerScores': playerScores.map((ps) => ps.toMap()).toList(),
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (lastEditedAt != null) {
      map['lastEditedAt'] = Timestamp.fromDate(lastEditedAt!);
    }
    return map;
  }

  factory Game.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawScores = data['playerScores'] as List<dynamic>? ?? [];
    final lastEditedTs = data['lastEditedAt'] as Timestamp?;
    final lastEdited = lastEditedTs?.toDate();
    return Game(
      id: doc.id,
      name: data['name'] ?? 'Unnamed Game',
      datePlayed:
          (data['datePlayed'] as Timestamp?)?.toDate() ?? DateTime.now(),
      playerScores: rawScores
          .map((ps) => PlayerScore.fromMap((ps as Map<String, dynamic>)))
          .toList(),
      lastEditedAt: lastEdited,
    );
  }

  int get totalScore => playerScores.fold(0, (sum, ps) => sum + ps.total);
}
