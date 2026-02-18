import 'package:cloud_firestore/cloud_firestore.dart';

class Player {
  final String id;
  final String firstName;
  final String lastName;
  final int totalWins;
  final String title;

  const Player({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.totalWins,
    this.title = '',
  });

  /// Map used when writing to Firestore.
  /// We *don’t* store the id inside the map; the document id is the id.
  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'totalWins': totalWins,
      'createdAt': FieldValue.serverTimestamp(),
      'title': title,
    };
  }

  factory Player.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return Player(
      id: doc.id,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      totalWins: data['totalWins'] ?? 0,
      title: data['title'] ?? '',
    );
  }

  String get fullName => "$firstName $lastName".trim();
}
