import 'package:flutter/material.dart';
import '../../models/player_score.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:math';

typedef OnSavePlayerScore = void Function(PlayerScore updated);

class EditPlayerScoreDialog extends StatefulWidget {
  final PlayerScore playerScore;
  final OnSavePlayerScore onSave;

  const EditPlayerScoreDialog({
    super.key,
    required this.playerScore,
    required this.onSave,
  });

  @override
  State<EditPlayerScoreDialog> createState() => _EditPlayerScoreDialogState();
}

class _EditPlayerScoreDialogState extends State<EditPlayerScoreDialog> {
  late WonderType _wonder;
  late int _military;
  late int _treasury;
  late int _wonders;
  late int _civilian;
  late int _commerce;
  late int _guilds;
  late int _science;
  late int _scienceCompass;
  late int _scienceGear;
  late int _scienceTablet;

  // manual science input (for backward compatibility)
  final TextEditingController _manualScienceController =
      TextEditingController();
  bool _manualScienceEdited = false;
  // toggle: when true use manual total input, when false use component carousels
  bool _useManualScience = true;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final s = widget.playerScore.scores;

    _wonder = widget.playerScore.wonder;
    _military = s.military;
    _treasury = s.treasury;
    _wonders = s.wonders;
    _civilian = s.civilian;
    _commerce = s.commerce;
    _guilds = s.guilds;
    _science = s.science;

    // Initialize components from Scores (new model fields). If any component is non-zero
    // prefer component entry mode; otherwise default to manual entry for backward compatibility.
    _scienceCompass = s.scienceCompass;
    _scienceGear = s.scienceGear;
    _scienceTablet = s.scienceTablet;

    _useManualScience =
        !(_scienceCompass > 0 || _scienceGear > 0 || _scienceTablet > 0);

    _manualScienceController.text = _science.toString();
  }

  @override
  void dispose() {
    _manualScienceController.dispose();
    super.dispose();
  }

  Widget _numberField(
    String label,
    int initial,
    ValueChanged<int> onChanged, {
    int min = -6,
    int max = 100,
    double height = 60,
    double fontSize = 20,
    IconData icon = FontAwesomeIcons.hashtag,
  }) {
    final numbers = List<int>.generate(max - min + 1, (i) => min + i);
    final initialIndex = numbers.indexOf(initial.clamp(min, max));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        SizedBox(
          height: height,
          child: CarouselSlider(
            items: numbers
                .map(
                  (n) => Center(
                    child: Text(
                      n.toString(),
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                )
                .toList(),
            options: CarouselOptions(
              height: height,
              enlargeCenterPage: true,
              enableInfiniteScroll: false,
              viewportFraction: 0.2,
              enlargeFactor: .7,
              initialPage: initialIndex < 0 ? 0 : initialIndex,
              onPageChanged: (index, reason) {
                onChanged(numbers[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    // Decide final science value based on mode (manual vs components)
    final c = _scienceCompass;
    final g = _scienceGear;
    final t = _scienceTablet;
    final nSets = min(c, min(g, t)); // returns the # of complete sets cause the min is the limiting factor
    // PER THE RULES:
    // Science is calculated as each of different symbols squared plus 7 points per complete set.
    int finalScience;
    if (_useManualScience) {
      final text = _manualScienceController.text.trim();
      if (text.isNotEmpty && int.tryParse(text) != null) {
        finalScience = int.parse(text);
      } else {
        finalScience = c * c + g * g + t * t + 7 * nSets;
      }
    } else {
      finalScience = c * c + g * g + t * t + 7 * nSets;
    }

    final newScores = Scores(
      military: _military,
      treasury: _treasury,
      wonders: _wonders,
      civilian: _civilian,
      commerce: _commerce,
      guilds: _guilds,
      science: finalScience,
      scienceCompass: c,
      scienceGear: g,
      scienceTablet: t,
    );

    final updated = PlayerScore(
      id: widget.playerScore.id,
      playerId: widget.playerScore.playerId,
      wonder: _wonder,
      scores: newScores,
    );

    widget.onSave(updated);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets + const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Edit Scores (${widget.playerScore.wonder.label})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  DropdownButtonFormField<WonderType>(
                    value: _wonder,
                    decoration: const InputDecoration(labelText: 'Wonder'),
                    items: WonderType.values
                        .map(
                          (w) =>
                              DropdownMenuItem(value: w, child: Text(w.label)),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _wonder = v!),
                  ),

                  // War points
                  _numberField(
                    'Military',
                    
                    _military,
                    (v) => setState(() => _military = v),
                    min: -6,
                    max: 18,
                    icon: Icons.shield, // no sword :(
                  ),
                  // Coins (total coins / 3 (but I assume the player can do that on their own))
                  _numberField(
                    'Treasury',
                    _treasury,
                    (v) => setState(() => _treasury = v),
                    min: 0,
                    max: 50,
                    icon: FontAwesomeIcons.coins,
                  ),
                  // Wonders like points from wonder
                  _numberField(
                    'Wonders',
                    _wonders,
                    (v) => setState(() => _wonders = v),
                    min: 0,
                    max: 20,
                    icon: FontAwesomeIcons.mountain,
                  ),
                  // Blue cards
                  _numberField(
                    'Civilian',
                    _civilian,
                    (v) => setState(() => _civilian = v),
                    min: 0,
                    max: 50,
                    icon: FontAwesomeIcons.monument,
                  ),
                  // Yellow cards
                  _numberField(
                    'Commerce',
                    _commerce,
                    (v) => setState(() => _commerce = v),
                    min: 0,
                    max: 50,
                    icon: FontAwesomeIcons.shop,
                  ),
                  // Purple cards
                  _numberField(
                    'Guilds',
                    _guilds,
                    (v) => setState(() => _guilds = v),
                    min: 0,
                    max: 50,
                    icon: FontAwesomeIcons.buildingColumns,
                  ),
                  // Toggle between manual total input and component carousels
                  SwitchListTile(
                    title: const Text('Manual science input'),
                    subtitle: const Text(
                      'Use a single total value instead of components',
                    ),
                    value: _useManualScience,
                    onChanged: (v) => setState(() => _useManualScience = v),
                  ),

                  if (_useManualScience) ...[
                    // Manual science input (backwards compatible with older saved totals)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: TextFormField(
                        controller: _manualScienceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Science (total)',
                          helperText:
                              'Enter total science (will be saved as-is).',
                        ),
                        onChanged: (v) {
                          setState(() => _manualScienceEdited = true);
                        },
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter a number';
                          if (int.tryParse(v) == null) return 'Invalid number';
                          return null;
                        },
                      ),
                    ),
                  ] else ...[
                    // Science: three compact carousels side-by-side (Compass, Gear, Tablet)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.center,
                            child: Text(
                              'Science Components',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Compass
                              _compactNumberCarousel(
                                FontAwesomeIcons.compassDrafting,
                                _scienceCompass,
                                (v) => setState(() => _scienceCompass = v),
                                min: 0,
                                max: 10,
                              ),
                              // Gear
                              _compactNumberCarousel(
                                FontAwesomeIcons.gear,
                                _scienceGear,
                                (v) => setState(() => _scienceGear = v),
                                min: 0,
                                max: 10,
                              ),
                              // Tablet
                              _compactNumberCarousel(
                                FontAwesomeIcons.tablet,
                                _scienceTablet,
                                (v) => setState(() => _scienceTablet = v),
                                min: 0,
                                max: 10,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // live preview of computed science total
                          Builder(
                            builder: (_) {
                              final c = _scienceCompass;
                              final g = _scienceGear;
                              final t = _scienceTablet;
                              final nSets = [
                                c,
                                g,
                                t,
                              ].reduce((a, b) => a < b ? a : b);
                              final total = c * c + g * g + t * t + 7 * nSets;
                              return Text(
                                'Computed total: $total  (sets: $nSets)',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _onSave,
                        child: const Text('Save'),
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

  // compact number carousel used for science components
  Widget _compactNumberCarousel(
    IconData icon,
    int initial,
    ValueChanged<int> onChanged, {
    int min = 0,
    int max = 10,
    double height = 90,
    double fontSize = 22,
  }) {
    final numbers = List<int>.generate(max - min + 1, (i) => min + i);
    final initialIndex = numbers.indexOf(initial.clamp(min, max));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 26, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 6),
        SizedBox(
          height: height,
          width: 72,
          child: CarouselSlider(
            items: numbers
                .map(
                  (n) => Center(
                    child: Text(
                      n.toString(),
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
                .toList(),
            options: CarouselOptions(
              height: height,
              enlargeCenterPage: true,
              enableInfiniteScroll: false,
              initialPage: initialIndex < 0 ? 0 : initialIndex,
              viewportFraction: 0.4,
              onPageChanged: (index, reason) {
                onChanged(numbers[index]);
              },
            ),
          ),
        ),
      ],
    );
  }
}
