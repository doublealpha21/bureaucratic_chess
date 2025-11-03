import 'package:bureaucratic_chess/features/chess_game/presentation/view_model/chess_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MoveHistory extends StatelessWidget {
  const MoveHistory({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ChessViewModel>();
    if (viewModel.engine.moveHistory.isEmpty) return const SizedBox.shrink();

    return Container(
      width: 300,
      height: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Move History",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Divider(color: Colors.white30),
          Expanded(
            child: ListView.builder(
              itemCount: (viewModel.engine.moveHistory.length / 2).ceil(),
              itemBuilder: (context, index) {
                final whiteMove = viewModel.engine.moveHistory[index * 2];
                final blackMove =
                    index * 2 + 1 < viewModel.engine.moveHistory.length
                    ? viewModel.engine.moveHistory[index * 2 + 1]
                    : null;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 30,
                        child: Text(
                          '${index + 1}.',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                      Expanded(child: Text(viewModel.formatMove(whiteMove))),
                      if (blackMove != null)
                        Expanded(child: Text(viewModel.formatMove(blackMove)))
                      else
                        const Spacer(),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
