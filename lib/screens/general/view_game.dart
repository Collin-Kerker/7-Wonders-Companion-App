import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/game.dart';
import '../../models/player_score.dart';
import '../../models/player.dart';
import '../../providers/provider_players.dart';
import '../../providers/provider_games.dart';
import 'alter_game.dart';

class viewGameScreen extends ConsumerStatefulWidget {
  static const routeName = '/viewgame';
  const viewGameScreen({super.key, required this.dummyGame});

  final Game dummyGame;

  @override
  ConsumerState<viewGameScreen> createState() => _ViewGameScreenState();
}

class _ViewGameScreenState extends ConsumerState<viewGameScreen> {
  @override
  Widget build(BuildContext context) {
    final allGames = ref.watch(gamesProvider);
    final playersList = ref.watch(playersProvider);

    // Find the current game by ID from the provider
    final game = allGames.firstWhere(
      (g) => g.id == widget.dummyGame.id,
      orElse: () => widget.dummyGame, // Fallback to original if not found
    );

    String nameForPlayerId(String id) {
      final p = playersList.firstWhere(
        (pl) => pl.id == id,
        orElse: () =>
            Player(id: id, firstName: 'Unknown', lastName: '', totalWins: 0),
      );
      return p.fullName;
    }

    final Map<String, List<PlayerScore>> grouped = {};
    for (final ps in game.playerScores) {
      grouped.putIfAbsent(ps.playerId, () => []);
      grouped[ps.playerId]!.add(ps);
    }

    // Calculate total scores and treasury coins for each player
    final playerTotals = <String, int>{};
    final playerTreasury = <String, int>{};
    for (final entry in grouped.entries) {
      playerTotals[entry.key] = entry.value.fold(0, (a, b) => a + b.total);
      playerTreasury[entry.key] = entry.value.fold(
        0,
        (a, b) => a + b.scores.treasury,
      );
    }

    // Sort players by total score
    final sortedEntries = grouped.entries.toList()
      ..sort((a, b) {
        final totalA = playerTotals[a.key] ?? 0;
        final totalB = playerTotals[b.key] ?? 0;
        if (totalA != totalB) return totalB.compareTo(totalA);

        final treasuryA = playerTreasury[a.key] ?? 0;
        final treasuryB = playerTreasury[b.key] ?? 0;
        if (treasuryA != treasuryB) return treasuryB.compareTo(treasuryA);

        // fallback to stable ordering by id
        return a.key.compareTo(b.key);
      });

    // Get the winner (highest score)
    final winnerId = sortedEntries.isNotEmpty ? sortedEntries.first.key : null;

    return Scaffold(
      appBar: AppBar(
        title: Text('${game.name} Players'),
        leading: const BackButton(),
        actions: [
          IconButton(
            tooltip: 'Edit Game',
            icon: const Icon(Icons.edit),
            onPressed: () {
              context.push(editGameScreen.routeName, extra: game);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: sortedEntries.map((entry) {
          final playerId = entry.key;
          final scores = entry.value;
          final isWinner = playerId == winnerId;
          final playerName = nameForPlayerId(playerId);
          final appBarColor =
              Theme.of(context).appBarTheme.backgroundColor ??
              Theme.of(context).colorScheme.primary;
          final hasNoWonder = scores.any(
            (ps) => ps.wonder == WonderType.NoWonder,
          );

          Widget buildWonderTile(PlayerScore ps) {
            final appBarColor =
                Theme.of(context).appBarTheme.backgroundColor ??
                Theme.of(context).colorScheme.primary;
            final appBarForeground =
                Theme.of(context).appBarTheme.foregroundColor ??
                Theme.of(context).colorScheme.onPrimary;
            // Build asset name from wonder label
            final assetName = ps.wonder.label.toLowerCase().replaceAll(
              ' ',
              '_',
            );
            final assetPath = 'images/wonders/$assetName.jpg';
            print(assetPath);

            return Container(
              height: 180,
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background image: show image if not NoWonder, otherwise use appBar color
                    ps.wonder == WonderType.NoWonder
                        ? Container(color: appBarColor)
                        : Image.asset(
                            assetPath,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx2, err2, st2) =>
                                Container(color: Colors.grey.shade300),
                          ),

                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 90,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.7),
                              Colors.black.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Content overlay
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ps.wonder.label,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: ps.wonder == WonderType.NoWonder
                                      ? appBarForeground
                                      : Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const Spacer(),

                          // bottom row: name on left, total on right
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      playerName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            color:
                                                ps.wonder == WonderType.NoWonder
                                                ? appBarForeground
                                                : Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    // Small chips for categories (show all types)
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 2,
                                      children: [
                                        Chip(
                                          label: Text(
                                            'M ${ps.scores.military}',
                                          ),
                                          backgroundColor:
                                              ps.wonder == WonderType.NoWonder
                                              ? appBarForeground.withOpacity(
                                                  0.12,
                                                )
                                              : Colors.white.withOpacity(0.18),
                                          labelStyle: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        Chip(
                                          label: Text('W ${ps.scores.wonders}'),
                                          backgroundColor:
                                              ps.wonder == WonderType.NoWonder
                                              ? appBarForeground.withOpacity(
                                                  0.12,
                                                )
                                              : Colors.white.withOpacity(0.18),
                                          labelStyle: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        Chip(
                                          label: Text(
                                            'Civ ${ps.scores.civilian}',
                                          ),
                                          backgroundColor:
                                              ps.wonder == WonderType.NoWonder
                                              ? appBarForeground.withOpacity(
                                                  0.12,
                                                )
                                              : Colors.white.withOpacity(0.18),
                                          labelStyle: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        Chip(
                                          label: Text(
                                            'Com ${ps.scores.commerce}',
                                          ),
                                          backgroundColor:
                                              ps.wonder == WonderType.NoWonder
                                              ? appBarForeground.withOpacity(
                                                  0.12,
                                                )
                                              : Colors.white.withOpacity(0.18),
                                          labelStyle: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        Chip(
                                          label: Text('G ${ps.scores.guilds}'),
                                          backgroundColor:
                                              ps.wonder == WonderType.NoWonder
                                              ? appBarForeground.withOpacity(
                                                  0.12,
                                                )
                                              : Colors.white.withOpacity(0.18),
                                          labelStyle: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        Chip(
                                          label: Text('S ${ps.scores.science}'),
                                          backgroundColor:
                                              ps.wonder == WonderType.NoWonder
                                              ? appBarForeground.withOpacity(
                                                  0.12,
                                                )
                                              : Colors.white.withOpacity(0.18),
                                          labelStyle: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isWinner)
                                    const Padding(
                                      padding: EdgeInsets.only(bottom: 6.0),
                                      child: Icon(
                                        Icons.emoji_events,
                                        color: Colors.amber,
                                        size: 22,
                                      ),
                                    ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: ps.wonder == WonderType.NoWonder
                                          ? appBarForeground.withOpacity(0.95)
                                          : Colors.white.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${ps.total}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    ps.wonder ==
                                                        WonderType.NoWonder
                                                    ? appBarColor
                                                    : Colors.black,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'pts',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: hasNoWonder ? appBarColor.withOpacity(0.12) : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  children: scores.map((ps) => buildWonderTile(ps)).toList(),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
