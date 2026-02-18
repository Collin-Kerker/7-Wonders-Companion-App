//Screen for altering or adding a game
// -----------------------------------------------------------------------
// Filename: alter_game.dart

import 'dart:async';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import 'package:final_project_app/widgets/navigation/widget_primary_app_bar.dart';
import '../../models/game.dart';
import '../../models/player_score.dart';
import '../../models/player.dart';
import '../../widgets/general/widget_edit_player_score.dart';
import '../../providers/provider_games.dart';
import '../../providers/provider_players.dart';
import '../../util/date_time/util_time.dart';

class editGameScreen extends ConsumerStatefulWidget {
  static const routeName = '/editgame';

  const editGameScreen({Key? key, this.game}) : super(key: key);

  final Game? game;

  @override
  ConsumerState<editGameScreen> createState() => _EditGameScreenState();
}

class _EditGameScreenState extends ConsumerState<editGameScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isInit = true;

  late String _workingGameId;
  late String _workingGameName;
  late List<PlayerScore> _workingPlayerScores;
  late DateTime _workingGameDate;

  @override
  void didChangeDependencies() {
    if (_isInit) {
      _isInit = false;
      super.didChangeDependencies();
    }
  }

  @override
  void initState() {
    super.initState();
    final incoming = widget.game;
    if (incoming != null) {
      _workingGameName = incoming.name;
      _workingPlayerScores = List<PlayerScore>.from(incoming.playerScores);
      _workingGameId = incoming.id;
      _workingGameDate = incoming.datePlayed;
      _nameController.text = _workingGameName;
    } else {
      _workingGameId = 'g_${DateTime.now().millisecondsSinceEpoch}';
      _workingGameName = 'New Game';
      _workingPlayerScores = [];
      _workingGameDate = DateTime.now();
      _nameController.text = _workingGameName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _playerNameFor(PlayerScore ps, List<Player> players) {
    final p = players.firstWhere(
      (pl) => pl.id == ps.playerId,
      orElse: () => Player(
        id: ps.playerId,
        firstName: 'Unknown',
        lastName: '',
        totalWins: 0,
      ),
    );
    return p.fullName;
  }

  @override
  Widget build(BuildContext context) {
    final players = ref.watch(playersProvider);

    return Scaffold(
      appBar: WidgetPrimaryAppBar(
        title: TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: 'Game Name',
          ),
          onChanged: (value) => setState(() => _workingGameName = value),
        ),
        actionButtons: [
          TextButton(
            onPressed: () async {
              final newGame = Game(
                id: _workingGameId,
                name: _workingGameName,
                datePlayed: _workingGameDate,
                playerScores: List<PlayerScore>.from(_workingPlayerScores),
                lastEditedAt: DateTime.now(),
              );

              try {
                await ref.read(gamesProvider.notifier).upsertGame(newGame);
                Navigator.of(context).pop();
              } catch (e) {
                // Show error to user and print to console
                final msg = 'Failed to save game: $e';
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

      floatingActionButton: FloatingActionButton(
        shape: ShapeBorder.lerp(
          const CircleBorder(),
          const StadiumBorder(),
          0.5,
        ),
        onPressed: () {
          WonderType selectedWonder = WonderType.NoWonder;
          String? selectedPlayerId = players.isNotEmpty
              ? players.first.id
              : null;

          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (ctx) {
              return Padding(
                padding:
                    MediaQuery.of(ctx).viewInsets + const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedPlayerId,
                      decoration: const InputDecoration(
                        labelText: 'Select Player',
                      ),
                      items: players
                          .map(
                            (p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(p.fullName),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => selectedPlayerId = v,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<WonderType>(
                      value: selectedWonder,
                      decoration: const InputDecoration(labelText: 'Wonder'),
                      items: WonderType.values
                          .map(
                            (w) => DropdownMenuItem(
                              value: w,
                              child: Text(w.label),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          selectedWonder = v ?? WonderType.NoWonder,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (selectedPlayerId == null) return;

                        final newPS = PlayerScore(
                          id: 'ps_${DateTime.now().millisecondsSinceEpoch}',
                          playerId: selectedPlayerId!,
                          wonder: selectedWonder,
                          scores: const Scores(),
                        );

                        final existing = _workingPlayerScores.indexWhere(
                          (ps) => ps.playerId == selectedPlayerId,
                        );
                        if (existing >= 0) {
                          _workingPlayerScores[existing] = newPS;
                        } else {
                          _workingPlayerScores.add(newPS);
                        }

                        print(
                          'alter_game: added/updated player in working game: ${selectedPlayerId} (${selectedWonder.label})',
                        );

                        Navigator.pop(ctx);
                        setState(() {});
                      },
                      child: const Text('Add Player'),
                    ),
                  ],
                ),
              );
            },
          );
        },
        child: const Icon(FontAwesomeIcons.plus),
      ),

      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children:
            <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: ListTile(
                  title: const Text('Date Played'),
                  subtitle: Text(
                    UtilTime.utcToString(
                      _workingGameDate,
                      convertToLocal: true,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      await showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (ctx) {
                          DateTime tempDate = _workingGameDate;
                          TimeOfDay tempTime = TimeOfDay.fromDateTime(
                            _workingGameDate,
                          );
                          return Padding(
                            padding:
                                MediaQuery.of(ctx).viewInsets +
                                const EdgeInsets.all(16.0),
                            child: StatefulBuilder(
                              builder: (contextSb, setStateSb) {
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      height: 300,
                                      child: CalendarDatePicker(
                                        initialDate: tempDate,
                                        firstDate: DateTime(1970),
                                        lastDate: DateTime(2100),
                                        onDateChanged: (d) {
                                          setStateSb(() {
                                            tempDate = DateTime(
                                              d.year,
                                              d.month,
                                              d.day,
                                              tempTime.hour,
                                              tempTime.minute,
                                            );
                                          });
                                        },
                                      ),
                                    ),
                                    ListTile(
                                      title: const Text('Time'),
                                      trailing: TextButton(
                                        child: Text(tempTime.format(contextSb)),
                                        onPressed: () async {
                                          final pickedTime =
                                              await showTimePicker(
                                                context: contextSb,
                                                initialTime: tempTime,
                                              );
                                          if (pickedTime != null)
                                            setStateSb(
                                              () => tempTime = pickedTime,
                                            );
                                        },
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              _workingGameDate = DateTime(
                                                tempDate.year,
                                                tempDate.month,
                                                tempDate.day,
                                                tempTime.hour,
                                                tempTime.minute,
                                              );
                                            });
                                            Navigator.pop(ctx);
                                          },
                                          child: const Text('Save'),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ] +
            _workingPlayerScores.map((ps) {
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _playerNameFor(ps, players),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(ps.wonder.label),
                            const SizedBox(height: 4),
                            Text(
                              'M:${ps.scores.military} '
                              'T:${ps.scores.treasury} '
                              'W:${ps.scores.wonders} '
                              'C:${ps.scores.civilian} '
                              'Com:${ps.scores.commerce} '
                              'G:${ps.scores.guilds} '
                              'S:${ps.scores.science}',
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            '${ps.total}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (context) => EditPlayerScoreDialog(
                                  playerScore: ps,
                                  onSave: (updated) {
                                    final idx = _workingPlayerScores.indexWhere(
                                      (x) =>
                                          x.id == ps.id ||
                                          x.playerId == ps.playerId,
                                    );
                                    if (idx >= 0) {
                                      _workingPlayerScores[idx] = updated;
                                    }
                                    setState(() {});
                                  },
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                _workingPlayerScores.removeWhere(
                                  (x) => x.id == ps.id,
                                );
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}
