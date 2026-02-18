// -----------------------------------------------------------------------
// Filename: screen_home.dart
// Original Author: Dan Grissom
// Creation Date: 10/31/2024
// Description: This file contains the screen for a dummy home screen
//               history screen.

//////////////////////////////////////////////////////////////////////////
// Imports
//////////////////////////////////////////////////////////////////////////

// Flutter imports
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';

// Flutter external package imports
import '/providers/provider_games.dart';
import '/models/game.dart';
import '../general/view_game.dart';
import '../general/alter_game.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

//////////////////////////////////////////////////////////////////////////
// StateFUL widget which manages state. Simply initializes the state object.
//////////////////////////////////////////////////////////////////////////
class ScreenHome extends ConsumerWidget {
  static const routeName = '/home';

  const ScreenHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Game> games = ref.watch(gamesProvider);
    // Sort games by date played, newest first
    final List<Game> sortedGames = List<Game>.from(games)
      ..sort((a, b) => b.datePlayed.compareTo(a.datePlayed));

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        shape: ShapeBorder.lerp(
          const CircleBorder(),
          const StadiumBorder(),
          0.5,
        ),
        onPressed: () {
          context.push(editGameScreen.routeName);
        },
        splashColor: Theme.of(context).primaryColor,
        child: const Icon(FontAwesomeIcons.plus),
      ),

      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 20),
        itemCount: sortedGames.length,
        itemBuilder: (context, index) {
          final Game g = sortedGames[index];

          return Container(
            height: 65,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              tileColor: Theme.of(context).colorScheme.surfaceVariant,
              title: Text(g.name),
              onTap: () => context.push(viewGameScreen.routeName, extra: g),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  final ok =
                      await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Game'),
                          content: const Text(
                            'Are you sure you want to delete this game?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      ) ??
                      false;

                  if (!ok) return;

                  try {
                    await ref.read(gamesProvider.notifier).deleteGame(g.id);
                  } catch (e) {}
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
