import 'package:bureaucratic_chess/features/chess_game/presentation/view_model/chess_view_model.dart';
import 'package:bureaucratic_chess/features/chess_game/presentation/widgets/time_settings_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GameControls extends StatelessWidget {
  const GameControls({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ChessViewModel>();
    final canUndo = viewModel.engine.moveHistory.isNotEmpty &&
        !viewModel.engine.isGameOver() &&
        !viewModel.isThinking;
    final canResign = !viewModel.engine.isGameOver() && !viewModel.isThinking;
    final canGetHint = !viewModel.isThinking &&
        !viewModel.engine.isGameOver() &&
        (!viewModel.isAIGame ||
            viewModel.engine.currentPlayer == viewModel.playerColor);
    final canPause = viewModel.isTimerEnabled && !viewModel.engine.isGameOver();

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => const TimeSettingsDialog(),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal.shade700,
          ),
          icon: const Icon(Icons.refresh),
          label: const Text('New Game...'), // This is the main "New Game" button
        ),
        ElevatedButton.icon(
          onPressed: canUndo
              ? () => context.read<ChessViewModel>().undoMove()
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange.shade700,
          ),
          icon: const Icon(Icons.undo),
          label: const Text('Undo'),
        ),
        if (canPause)
          ElevatedButton.icon(
            onPressed: () => context.read<ChessViewModel>().togglePause(),
            style: ElevatedButton.styleFrom(
              backgroundColor:
              viewModel.isPaused ? Colors.green.shade700 : Colors.grey.shade700,
            ),
            icon: Icon(
                viewModel.isPaused ? Icons.play_arrow : Icons.pause),
            label: Text(viewModel.isPaused ? 'Resume' : 'Pause'),
          ),
        ElevatedButton.icon(
          onPressed: canGetHint
              ? () => context.read<ChessViewModel>().getHint()
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
          ),
          icon: const Icon(Icons.lightbulb_outline),
          label: const Text('Hint'),
        ),
        if (viewModel.engine.canDeployBureaucrat() &&
            !viewModel.deployingBureaucrat)
          ElevatedButton.icon(
            onPressed: () =>
                context.read<ChessViewModel>().toggleDeployingBureaucrat(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade700,
            ),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Deploy Bureaucrat'),
          ),
        ElevatedButton.icon(
          onPressed: canResign
              ? () => context.read<ChessViewModel>().resign()
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade900,
          ),
          icon: const Icon(Icons.flag),
          label: const Text('Resign'),
        ),
      ],
    );
  }
}