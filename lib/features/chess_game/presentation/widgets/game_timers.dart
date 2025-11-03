import 'package:bureaucratic_chess/features/chess_game/data/models/piece_model.dart';
import 'package:bureaucratic_chess/features/chess_game/presentation/view_model/chess_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GameTimers extends StatelessWidget {
  const GameTimers({super.key});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ChessViewModel>();
    final isWhiteTurn = viewModel.engine.currentPlayer == PieceColor.white;
    final bool isActive = !viewModel.engine.isGameOver() && !viewModel.isPaused;

    // --- MODIFICATION START ---
    if (viewModel.isPaused) {
      return Center(
        child: Text(
          '-- PAUSED --',
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      );
    }
    // --- MODIFICATION END ---

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildTimerBox(
          'Black',
          _formatDuration(viewModel.blackTime),
          !isWhiteTurn && isActive,
        ),
        _buildTimerBox(
          'White',
          _formatDuration(viewModel.whiteTime),
          isWhiteTurn && isActive,
        ),
      ],
    );
  }

  Widget _buildTimerBox(String playerName, String time, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: isActive ? Colors.blue.shade800 : Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? Colors.blue.shade300 : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            playerName,
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}