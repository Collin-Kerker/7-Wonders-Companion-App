import 'package:cloud_firestore/cloud_firestore.dart';

enum WonderType {
  NoWonder,
  Alexandria,
  Gizah,
  Halikarnassos,
  Ephesos,
  Babylon,
  Rhodes,
  Olympia,
}

extension WonderTypeLabel on WonderType {
  String get label {
    switch (this) {
      case WonderType.NoWonder:
        return 'No Wonder';
      case WonderType.Alexandria:
        return 'Alexandria';
      case WonderType.Gizah:
        return 'Gizah';
      case WonderType.Halikarnassos:
        return 'Halikarnassos';
      case WonderType.Ephesos:
        return 'Ephesos';
      case WonderType.Babylon:
        return 'Babylon';
      case WonderType.Rhodes:
        return 'Rhodes';
      case WonderType.Olympia:
        return 'Olympia';
    }
  }
}

class WonderTypeSerialization {
  static WonderType fromLabel(String label) {
    switch (label) {
      case 'No Wonder':
        return WonderType.NoWonder;
      case 'Alexandria':
        return WonderType.Alexandria;
      case 'Gizah':
        return WonderType.Gizah;
      case 'Halikarnassos':
        return WonderType.Halikarnassos;
      case 'Ephesos':
        return WonderType.Ephesos;
      case 'Babylon':
        return WonderType.Babylon;
      case 'Rhodes':
        return WonderType.Rhodes;
      case 'Olympia':
        return WonderType.Olympia;
      default:
        return WonderType.NoWonder;
    }
  }
}

class Scores {
  // War points
  final int military;
  // Coins
  final int treasury;
  // Points from wonders
  final int wonders;
  // Blue cards
  final int civilian;
  // Yellow cards
  final int commerce;
  // Purple cards
  final int guilds;
  // Green cards
  final int science;

  // component breakdown for science
  final int scienceCompass;
  final int scienceGear;
  final int scienceTablet;

  const Scores({
    this.military = 0,
    this.treasury = 0,
    this.wonders = 0,
    this.civilian = 0,
    this.commerce = 0,
    this.guilds = 0,
    this.science = 0,
    this.scienceCompass = 0,
    this.scienceGear = 0,
    this.scienceTablet = 0,
  });

  int get total =>
      military + treasury + wonders + civilian + commerce + guilds + science;

  Map<String, dynamic> toMap() {
    return {
      'military': military,
      'treasury': treasury,
      'wonders': wonders,
      'civilian': civilian,
      'commerce': commerce,
      'guilds': guilds,
      'science': science,
      'science_compass': scienceCompass,
      'science_gear': scienceGear,
      'science_tablet': scienceTablet,
    };
  }

  factory Scores.fromMap(Map<String, dynamic> map) {
    return Scores(
      military: (map['military'] ?? 0) as int,
      treasury: (map['treasury'] ?? 0) as int,
      wonders: (map['wonders'] ?? 0) as int,
      civilian: (map['civilian'] ?? 0) as int,
      commerce: (map['commerce'] ?? 0) as int,
      guilds: (map['guilds'] ?? 0) as int,
      science: (map['science'] ?? 0) as int,
      scienceCompass: (map['science_compass'] ?? 0) as int,
      scienceGear: (map['science_gear'] ?? 0) as int,
      scienceTablet: (map['science_tablet'] ?? 0) as int,
    );
  }
}

class PlayerScore {
  final String id;
  final String playerId;
  final WonderType wonder;
  final Scores scores;

  const PlayerScore({
    required this.id,
    required this.playerId,
    required this.wonder,
    required this.scores,
  });

  int get total => scores.total;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'playerId': playerId,
      'wonder': wonder.label,
      'scores': scores.toMap(),
    };
  }

  factory PlayerScore.fromMap(Map<String, dynamic> map) {
    return PlayerScore(
      id: map['id'] ?? '',
      playerId: map['playerId'] ?? '',
      wonder: WonderTypeSerialization.fromLabel(map['wonder'] ?? 'NoWonder'),
      scores: Scores.fromMap(
        (map['scores'] ?? <String, dynamic>{}) as Map<String, dynamic>,
      ),
    );
  }
}
