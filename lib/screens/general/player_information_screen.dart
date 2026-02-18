import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphic/graphic.dart';
// import 'package:intl/intl.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:final_project_app/providers/provider_players.dart';

import 'package:final_project_app/models/player_score.dart';
import 'package:final_project_app/models/player.dart';
import 'package:final_project_app/models/game.dart';
import 'package:final_project_app/providers/provider_games.dart';

/// Represents a data point for the over-time chart
class ChartDataPoint {
  final DateTime datePlayed;
  final int score;
  final String gameId;

  ChartDataPoint({
    required this.datePlayed,
    required this.score,
    required this.gameId,
  });
}

/// Graphic chart widget to display player scores over time
class PlayerScoreChart extends StatelessWidget {
  final List<ChartDataPoint> dataPoints;
  final Color lineColor;

  const PlayerScoreChart({
    Key? key,
    required this.dataPoints,
    required this.lineColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Convert to maps for graphic
    final seqData = List.generate(
      dataPoints.length,
      (i) => {'index': i + 1, 'score': dataPoints[i].score},
    );
    // final chartData = dataPoints
    //     .map((p) => {'date': p.datePlayed, 'score': p.score})
    //     .toList();

    return SizedBox(
      height: 250,
      child: Chart(
        // use sequential index data so points are evenly spaced by game order
        data: seqData,
        variables: {
          'game': Variable(
            accessor: (Map m) => m['index'] as int,
            scale: LinearScale(min: 1),
          ),
          'score': Variable(
            accessor: (Map m) => m['score'] as num,
            scale: LinearScale(min: 0), // start Y axis at 0
          ),
        },

        marks: [
          LineMark(
            position: Varset('game') * Varset('score'),
            shape: ShapeEncode(value: BasicLineShape()),
            size: SizeEncode(value: 2),
            color: ColorEncode(value: lineColor),
          ),
          PointMark(
            position: Varset('game') * Varset('score'),
            size: SizeEncode(value: 4),
            color: ColorEncode(value: lineColor),
          ),
        ],
        // I'm not sure this actually does anything
        axes: [
          Defaults.horizontalAxis
            ..labelMapper = (_, axis, value) {
              return LabelStyle(
                textStyle: TextStyle(color: Colors.black87, fontSize: 12),
              );
            },
          Defaults.verticalAxis
            ..labelMapper = (_, axis, value) {
              return LabelStyle(
                textStyle: TextStyle(color: Colors.black87, fontSize: 12),
              );
            },
        ],
      ),
    );
  }
}

class PlayerInformationScreen extends ConsumerStatefulWidget {
  static const routeName = '/playerinformation';

  const PlayerInformationScreen({super.key, required this.playerData});

  final Map<String, dynamic> playerData;

  @override
  ConsumerState<PlayerInformationScreen> createState() =>
      _PlayerInformationScreenState();
}

class _PlayerInformationScreenState
    extends ConsumerState<PlayerInformationScreen> {
  WonderType? _selectedWonder;
  String _selectedScoreType = 'all';
  bool _generatingTitle = false;
  String? _playerTitle;

  @override
  void initState() {
    super.initState();
    _selectedWonder = null;
    final p = widget.playerData['player'] as Player?;
    _playerTitle = p?.title;
  }

  int _getScoreByType(Scores scores, String type) {
    switch (type) {
      case 'military':
        return scores.military;
      case 'treasury':
        return scores.treasury;
      case 'wonders':
        return scores.wonders;
      case 'civilian':
        return scores.civilian;
      case 'commerce':
        return scores.commerce;
      case 'guilds':
        return scores.guilds;
      case 'science':
        return scores.science;
      default:
        return scores.total;
    }
  }

  double _calculateAverageScore(List<PlayerScore> playerScores) {
    if (playerScores.isEmpty) return 0;
    var filtered = playerScores;
    if (_selectedWonder != null) {
      filtered = filtered.where((ps) => ps.wonder == _selectedWonder).toList();
    }
    if (filtered.isEmpty) return 0;
    int total = 0;
    for (final ps in filtered) {
      if (_selectedScoreType == 'all') {
        total += ps.scores.total;
      } else {
        total += _getScoreByType(ps.scores, _selectedScoreType);
      }
    }
    return total / filtered.length;
  }

  List<Game> _getFilteredGames(List<Game> allGames, String playerId) {
    var filtered = allGames
        .where((g) => g.playerScores.any((ps) => ps.playerId == playerId))
        .toList();
    if (_selectedWonder != null) {
      filtered = filtered.where((g) {
        return g.playerScores.any(
          (ps) => ps.playerId == playerId && ps.wonder == _selectedWonder,
        );
      }).toList();
    }
    filtered.sort((a, b) => b.datePlayed.compareTo(a.datePlayed));
    return filtered;
  }

  List<ChartDataPoint> _buildChartData(List<Game> games, String playerId) {
    final points = <ChartDataPoint>[];
    for (final game in games) {
      final psList = game.playerScores
          .where((ps) => ps.playerId == playerId)
          .toList();
      if (psList.isEmpty) continue;
      final ps = psList.first;
      final score = _selectedScoreType == 'all'
          ? ps.scores.total
          : _getScoreByType(ps.scores, _selectedScoreType);
      points.add(
        ChartDataPoint(
          datePlayed: game.datePlayed,
          score: score,
          gameId: game.id,
        ),
      );
    }
    // sort oldest to newest for chart
    points.sort((a, b) => a.datePlayed.compareTo(b.datePlayed));
    return points;
  }

  Future<String> _makeTitle(String playerId) async {
    // Compute per-category averages from gamesProvider for the given playerId
    final allGames = ref.read(gamesProvider);

    int count = 0;
    int sumMilitary = 0;
    int sumTreasury = 0;
    int sumWonders = 0;
    int sumCivilian = 0;
    int sumCommerce = 0;
    int sumGuilds = 0;
    int sumScience = 0;

    for (final game in allGames) {
      for (final ps in game.playerScores) {
        if (ps.playerId != playerId) continue;
        count++;
        sumMilitary += ps.scores.military;
        sumTreasury += ps.scores.treasury;
        sumWonders += ps.scores.wonders;
        sumCivilian += ps.scores.civilian;
        sumCommerce += ps.scores.commerce;
        sumGuilds += ps.scores.guilds;
        sumScience += ps.scores.science;
      }
    }

    if (count == 0) return 'No games';

    final averages = {
      'Military': (sumMilitary / count),
      'Treasury': (sumTreasury / count),
      'Wonders': (sumWonders / count),
      'Civilian': (sumCivilian / count),
      'Commerce': (sumCommerce / count),
      'Guild': (sumGuilds / count),
      'Science': (sumScience / count),
    };

    final averageText = averages.entries
        .map((e) => "${e.key}: ${e.value.toStringAsFixed(1)}")
        .join("\n");

    final prompt =
        """
You are generating a very short creative title (2-4 words) based on the player's strongest scoring traits in the boardgame 7 Wonders.

You will receive the player's average score in these categories (each number is an average score):
- Military
- Treasury
- Wonders
- Civilian
- Commerce
- Guild
- Science

Look at which categories are highest, then generate a short creative title that captures the player's strengths.
I.e. if the player is strongest in Military and Science, you might generate "The Scholarly Warlord". 
If the player is strongest in Wonders and Treasury, you might generate "The Opulent Architect".
Do NOT explain. Do NOT give sentences. ONLY output a short title.

Here are the averages:
$averageText
""";

    final result = await Gemini.instance.prompt(parts: [Part.text(prompt)]);
    return result?.output?.trim() ?? 'No title';
  }

  Future<void> _generateAndSaveTitle(Player player) async {
    setState(() => _generatingTitle = true);
    try {
      final newTitle = await _makeTitle(player.id);
      if (newTitle.isNotEmpty && newTitle != 'No games') {
        final updated = Player(
          id: player.id,
          firstName: player.firstName,
          lastName: player.lastName,
          totalWins: player.totalWins,
          title: newTitle,
        );
        await ref.read(playersProvider.notifier).upsertPlayer(updated);
        setState(() => _playerTitle = newTitle);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate/save title: $e')),
        );
      }
    } finally {
      setState(() => _generatingTitle = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Gemini.init(apiKey: 'AIzaSyCQekCQ8gaTcM4crHwJl666GtOVnk7JXkA');
    final player = widget.playerData['player'] as Player;
    final playerScores =
        widget.playerData['playerScores'] as List<PlayerScore>? ?? [];
    final allGames = ref.watch(gamesProvider);

    final filteredGames = _getFilteredGames(allGames, player.id);
    final chartData = _buildChartData(filteredGames, player.id);
    final averageScore = _calculateAverageScore(playerScores);

    // get list of wonders used
    final wondersSet = playerScores.map((ps) => ps.wonder).toSet().toList();

    final scoreTypes = [
      'all',
      'military',
      'treasury',
      'wonders',
      'civilian',
      'commerce',
      'guilds',
      'science',
    ];
    final scoreTypeLabels = {
      'all': 'Total',
      'military': 'Military',
      'treasury': 'Treasury',
      'wonders': 'Wonders',
      'civilian': 'Civilian',
      'commerce': 'Commerce',
      'guilds': 'Guilds',
      'science': 'Science',
    };

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${player.fullName}'s Information"),
            // if ((_playerTitle ?? '').isNotEmpty)
            //   Text(
            //     _playerTitle!,
            //     style: Theme.of(
            //       context,
            //     ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
            //   ),
          ],
        ),
        // actions: [
        //   _generatingTitle
        //       ? Padding(
        //           padding: const EdgeInsets.symmetric(horizontal: 12.0),
        //           child: Center(
        //             child: SizedBox(
        //               width: 20,
        //               height: 20,
        //               child: CircularProgressIndicator(strokeWidth: 2),
        //             ),
        //           ),
        //         )
        //       : IconButton(
        //           tooltip: 'Generate Title',
        //           icon: const Icon(Icons.auto_awesome),
        //           onPressed: () => _generateAndSaveTitle(player),
        //         ),
        // ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(top: 12.0, bottom: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Player title card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                //Title
                                Text(
                                  (_playerTitle ?? '').isNotEmpty
                                      ? _playerTitle!
                                      : 'No title yet',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            icon: _generatingTitle
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.auto_awesome),
                            label: const Text('Generate Title'),
                            onPressed: _generatingTitle
                                ? null
                                : () => _generateAndSaveTitle(player),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Chart section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Card(
                    color: Color.fromARGB(255, 206, 218, 224),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Score Over Time',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          if (chartData.isNotEmpty)
                            PlayerScoreChart(
                              dataPoints: chartData,
                              lineColor: Theme.of(context).primaryColor,
                            )
                          else
                            SizedBox(
                              height: 150,
                              child: Center(
                                child: Text(
                                  'No games available',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Wonder dropdown
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: DropdownButtonFormField<WonderType?>(
                    value: _selectedWonder,
                    decoration: const InputDecoration(
                      labelText: 'Select Wonder',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.fromLTRB(12, 14, 12, 14),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Wonders'),
                      ),
                      ...wondersSet.map(
                        (w) => DropdownMenuItem(value: w, child: Text(w.label)),
                      ),
                    ],
                    onChanged: (v) => setState(() => _selectedWonder = v),
                  ),
                ),
                const SizedBox(height: 8),
                // Score type dropdown
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: DropdownButtonFormField<String>(
                    value: _selectedScoreType,
                    decoration: const InputDecoration(
                      labelText: 'Select Score Type',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.fromLTRB(12, 14, 12, 14),
                    ),
                    items: scoreTypes
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(scoreTypeLabels[t] ?? t),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedScoreType = v ?? 'all'),
                  ),
                ),
                const SizedBox(height: 10),
                // Average score card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Average Score:',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            averageScore.toStringAsFixed(2),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Games list heading
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    'Games',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: filteredGames.isEmpty ? 1 : filteredGames.length,
              itemBuilder: (context, idx) {
                if (filteredGames.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: Text('No games played with the selected filters.'),
                    ),
                  );
                }
                final game = filteredGames[idx];
                final ps = game.playerScores.firstWhere(
                  (ps) => ps.playerId == player.id,
                );
                final score = _selectedScoreType == 'all'
                    ? ps.scores.total
                    : _getScoreByType(ps.scores, _selectedScoreType);

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(
                      game.name,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    subtitle: Text(
                      '${game.datePlayed.toString().split('.')[0]} • ${ps.wonder.label}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    trailing: Text(
                      '$score',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    dense: true,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
