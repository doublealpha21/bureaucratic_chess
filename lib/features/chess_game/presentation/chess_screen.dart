import 'package:bureaucratic_chess/features/chess_game/data/models/piece_model.dart';
import 'package:bureaucratic_chess/features/chess_game/presentation/view_model/chess_view_model.dart';
import 'package:bureaucratic_chess/features/chess_game/presentation/widgets/captured_pieces.dart';
import 'package:bureaucratic_chess/features/chess_game/presentation/widgets/chess_board.dart';
import 'package:bureaucratic_chess/features/chess_game/presentation/widgets/game_controls.dart';
import 'package:bureaucratic_chess/features/chess_game/presentation/widgets/game_timers.dart';
import 'package:bureaucratic_chess/features/chess_game/presentation/widgets/move_history.dart';
import 'package:bureaucratic_chess/features/chess_game/presentation/widgets/promotion_dialog.dart';
import 'package:bureaucratic_chess/features/chess_game/presentation/widgets/status_banners.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChessScreen extends StatelessWidget {
  const ChessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ChessViewModel>();

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final bool isDesktop = constraints.maxWidth > 800;

                    final mainGameColumn = Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        _buildHeader(viewModel),
                        const SizedBox(height: 16),
                        const GameControls(),
                        const SizedBox(height: 16),
                        if (viewModel.engine.gameStatus.isNotEmpty)
                          const StatusBanner(),
                        if (viewModel.deployingBureaucrat)
                          const DeploymentBanner(),
                        if (viewModel.isThinking)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 8),
                                Text(
                                  'AI is thinking...',
                                  style: TextStyle(color: Colors.white54),
                                ),
                              ],
                            ),
                          )
                        else
                          const SizedBox(height: 16),
                        const CapturedPieces(color: PieceColor.black),
                        const SizedBox(height: 8),
                        if (viewModel.isTimerEnabled) const GameTimers(),
                        const SizedBox(height: 8),
                        const ChessBoard(),
                        const SizedBox(height: 8),
                        const CapturedPieces(color: PieceColor.white),
                        if (!isDesktop && viewModel.showHelp) ...[
                          const SizedBox(height: 24),
                          _buildHelp(),
                        ],
                        const SizedBox(height: 24),
                        const MoveHistory(),
                      ],
                    );

                    final helpPanel = viewModel.showHelp
                        ? SizedBox(width: 300, child: _buildHelp())
                        : const SizedBox(width: 300);

                    return Stack(
                      children: [
                        if (isDesktop)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: mainGameColumn),
                              const SizedBox(width: 24),
                              helpPanel,
                            ],
                          )
                        else
                          mainGameColumn,
                        if (viewModel.isPromotionDialogVisible)
                          const PromotionDialog(),
                        // --- MODIFICATION START ---
                        if (viewModel.isPaused)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withOpacity(0.7),
                              child: Center(
                                child: Text(
                                  'PAUSED',
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ChessViewModel viewModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bureaucrat Chess',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Move ${(viewModel.engine.moveHistory.length / 2).ceil() + 1} • ${viewModel.engine.currentPlayer.name[0].toUpperCase()}${viewModel.engine.currentPlayer.name.substring(1)} to move',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
        IconButton(
          icon: Icon(
            viewModel.showHelp ? Icons.close : Icons.help_outline,
            color: Colors.blue.shade300,
          ),
          onPressed: () => viewModel.toggleHelp(),
        ),
      ],
    );
  }

  Widget _buildHelp() {
    return Container(
      // Use top margin only for mobile layout compatibility
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade800, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bureaucratic Chess',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade300,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'This is a version of chess with a twist, it adds a new piece called The Bureaucrat. It can move to any unoccupied position on the board, but cannot capture pieces. It\'s just there to get in the way and slow things down.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          _buildHelpItem(
            'The Bureaucrat (B) is available after white\'s 7th move (turn 8).',
          ),
          _buildHelpItem(
            'It can be placed on any empty square as a full turn.',
          ),
          _buildHelpItem('It moves by teleporting to any other empty square.'),
          _buildHelpItem('It cannot capture or give check.'),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(color: Colors.white70, fontSize: 14)),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
      ],
    ),
  );
}
