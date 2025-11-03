import 'package:bureaucratic_chess/features/chess_game/presentation/view_model/chess_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StatusBanner extends StatelessWidget {
  const StatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ChessViewModel>();
    final bool isCheck = viewModel.engine.gameStatus.contains('check');
    final bool isWin = viewModel.engine.gameStatus.contains('wins');
    final Color color = isWin
        ? Colors.green.shade900
        : (isCheck ? Colors.red.shade900 : Colors.blueGrey.shade800);
    final Color borderColor = isWin
        ? Colors.green.shade400
        : (isCheck ? Colors.red.shade400 : Colors.blueGrey.shade400);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        viewModel.engine.gameStatus,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class DeploymentBanner extends StatelessWidget {
  const DeploymentBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.shade900,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.shade300),
      ),
      child: const Text(
        'Click any empty square to deploy your Bureaucrat',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
