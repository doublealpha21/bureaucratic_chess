import 'package:bureaucratic_chess/features/chess_game/data/models/piece_model.dart';
import 'package:bureaucratic_chess/features/chess_game/presentation/view_model/chess_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CapturedPieces extends StatelessWidget {
  final PieceColor color;

  const CapturedPieces({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ChessViewModel>();
    final pieces = color == PieceColor.white
        ? viewModel.engine.whiteCaptured
        : viewModel.engine.blackCaptured;

    return Container(
      height: 30,
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Text(
            color == PieceColor.white ? 'White captured: ' : 'Black captured: ',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          ...pieces
              .map(
                (p) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(p.symbol, style: const TextStyle(fontSize: 20)),
                ),
              )
              .toList(),
        ],
      ),
    );
  }
}
