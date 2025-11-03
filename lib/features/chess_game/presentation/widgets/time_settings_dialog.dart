import 'package:bureaucratic_chess/features/chess_game/data/models/piece_model.dart';
import 'package:bureaucratic_chess/features/chess_game/presentation/view_model/chess_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TimeSettingsDialog extends StatefulWidget {
  const TimeSettingsDialog({super.key});

  @override
  State<TimeSettingsDialog> createState() => _TimeSettingsDialogState();
}

class _TimeSettingsDialogState extends State<TimeSettingsDialog> {
  final Map<String, Duration?> _timeOptions = {
    'No Timer': null,
    '1 Minute': const Duration(minutes: 1),
    '3 Minutes': const Duration(minutes: 3),
    '5 Minutes': const Duration(minutes: 5),
    '10 Minutes': const Duration(minutes: 10),
  };

  Duration? _selectedTime = const Duration(minutes: 5);
  bool _isAIGame = false;
  double _aiLevel = 3;
  PieceColor _playerColor = PieceColor.white;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0F172A),
      title: const Text(
        'New Game Settings',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time Control Section
            const Text(
              'Time Control',
              style: TextStyle(
                color: Colors.blueAccent,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: _timeOptions.entries.map((entry) {
                  final isSelected = _selectedTime == entry.value;
                  return InkWell(
                    onTap: () => setState(() => _selectedTime = entry.value),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.blue.shade900.withOpacity(0.3)
                            : null,
                        border: Border(
                          left: BorderSide(
                            color: isSelected
                                ? Colors.blueAccent
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: isSelected
                                ? Colors.blueAccent
                                : Colors.white54,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            entry.key,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontSize: 15,
                              fontWeight: isSelected
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),
            const Divider(color: Colors.white30),
            const SizedBox(height: 20),

            // Game Mode Section
            const Text(
              'Game Mode',
              style: TextStyle(
                color: Colors.blueAccent,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text(
                      'Play vs. AI',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                    subtitle: Text(
                      _isAIGame ? 'Computer opponent' : 'Two players',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                    value: _isAIGame,
                    onChanged: (val) => setState(() => _isAIGame = val),
                    activeColor: Colors.blueAccent,
                    contentPadding: EdgeInsets.zero,
                  ),

                  if (_isAIGame) ...[
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white30, height: 1),
                    const SizedBox(height: 16),

                    // Player Color Selection
                    const Text(
                      'Play as',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ColorButton(
                            label: 'White',
                            icon: Icons.circle_outlined,
                            isSelected: _playerColor == PieceColor.white,
                            onTap: () =>
                                setState(() => _playerColor = PieceColor.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ColorButton(
                            label: 'Black',
                            icon: Icons.circle,
                            isSelected: _playerColor == PieceColor.black,
                            onTap: () =>
                                setState(() => _playerColor = PieceColor.black),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // AI Difficulty
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'AI Difficulty',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blueAccent.withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            'Level ${_aiLevel.round()}',
                            style: const TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _aiLevel,
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: _aiLevel.round().toString(),
                      onChanged: (val) => setState(() => _aiLevel = val),
                      activeColor: Colors.blueAccent,
                      inactiveColor: Colors.white24,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Beginner',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            'Master',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: () {
            context.read<ChessViewModel>().updateTimeSetting(
              _selectedTime,
              isAIGame: _isAIGame,
              aiDifficulty: _aiLevel.round(),
              playerColor: _playerColor,
            );
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Start Game',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class _ColorButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blueAccent.withOpacity(0.2)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? Colors.blueAccent : Colors.white30,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blueAccent : Colors.white54,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.blueAccent : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
