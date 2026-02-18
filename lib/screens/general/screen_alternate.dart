// -----------------------------------------------------------------------
// Filename: screen_alternative.dart
// Description: Screen for viewing players and adding new ones.
// -----------------------------------------------------------------------

import 'dart:async';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/player.dart';
import '../../models/game.dart';
import '../../models/player_score.dart';
import '../../providers/provider_players.dart';
import '../../providers/provider_games.dart';
import '../general/player_information_screen.dart';

class ScreenAlternate extends ConsumerStatefulWidget {
  static const routeName = '/alternative';

  @override
  ConsumerState<ScreenAlternate> createState() => _ScreenAlternateState();
}

class _ScreenAlternateState extends ConsumerState<ScreenAlternate> {
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    if (_isInit) {
      _isInit = false;
      super.didChangeDependencies();
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Player> players = ref.watch(playersProvider);
    final List<Game> games = ref.watch(gamesProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        shape: ShapeBorder.lerp(
          const CircleBorder(),
          const StadiumBorder(),
          0.5,
        ),
        onPressed: () {
          final firstNameController = TextEditingController();
          final lastNameController = TextEditingController();

          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (BuildContext ctx) {
              return Padding(
                padding:
                    MediaQuery.of(ctx).viewInsets + const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Add New Player',
                      style: Theme.of(ctx).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                      ),
                    ),
                    const SizedBox(height: 8),

                    TextField(
                      controller: lastNameController,
                      decoration: const InputDecoration(labelText: 'Last Name'),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            final first = firstNameController.text.trim();
                            final last = lastNameController.text.trim();
                            if (first.isEmpty && last.isEmpty) return;

                            final newPlayer = Player(
                              id: 'p_${DateTime.now().millisecondsSinceEpoch}',
                              firstName: first,
                              lastName: last,
                              totalWins: 0,
                            );

                            try {
                              await ref
                                  .read(playersProvider.notifier)
                                  .upsertPlayer(newPlayer);
                              Navigator.pop(ctx);
                            } catch (e) {
                              final msg = 'Failed to save player: $e';
                              print(msg);
                              if (mounted) {
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(SnackBar(content: Text(msg)));
                              }
                            }
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
        child: const Icon(FontAwesomeIcons.plus),
      ),

      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 20),
        itemCount: players.length,
        itemBuilder: (context, index) {
          final player = players[index];

          // Collect all PlayerScores for this player across all games
          final List<PlayerScore> playerScores = [
            for (final g in games)
              ...g.playerScores.where((ps) => ps.playerId == player.id),
          ];

          return Container(
            height: 65,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              tileColor: Theme.of(context).colorScheme.surfaceVariant,
              trailing: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: const Icon(Icons.delete, size: 20),
                onPressed: () async {
                  try {
                    await ref
                        .read(playersProvider.notifier)
                        .deletePlayer(player.id);
                  } catch (e) {
                    print('Failed to delete player: $e');
                  }
                },
              ),
              title: Text(player.fullName),
              subtitle: player.title.isNotEmpty
                  ? Text(
                      player.title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  : null,
              onTap: () => context.push(
                PlayerInformationScreen.routeName,
                extra: {'player': player, 'playerScores': playerScores},
              ),
            ),
          );
        },
      ),
    );
  }
}
