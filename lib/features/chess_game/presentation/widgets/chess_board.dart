import 'package:bureaucratic_chess/features/chess_game/data/models/piece_model.dart';
import 'package:bureaucratic_chess/features/chess_game/presentation/view_model/chess_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChessBoard extends StatelessWidget {
  const ChessBoard({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF4A3A2A), width: 6),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final squareSize = constraints.maxWidth / 8;
            return Stack(
              children: [
                GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                  ),
                  itemBuilder: (context, index) {
                    final row = index ~/ 8;
                    final col = index % 8;
                    return _buildSquare(context, row, col);
                  },
                  itemCount: 64,
                  physics: const NeverScrollableScrollPhysics(),
                ),
                ..._buildPieces(context, squareSize),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildPieces(BuildContext context, double squareSize) {
    final viewModel = context.watch<ChessViewModel>();
    final List<Widget> pieceWidgets = [];
    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        final piece = viewModel.engine.board[row][col];
        if (piece != null) {
          pieceWidgets.add(
            AnimatedPositioned(
              key: ValueKey(piece.id),
              duration: const Duration(milliseconds: 150),
              left: col * squareSize,
              top: row * squareSize,
              width: squareSize,
              height: squareSize,
              child: _buildPiece(context, piece, row, col, squareSize),
            ),
          );
        }
      }
    }
    return pieceWidgets;
  }

  Widget _buildPiece(
      BuildContext context,
      ChessPiece piece,
      int row,
      int col,
      double size,
      ) {
    final viewModel = context.read<ChessViewModel>();
    final pieceUI = Center(
      child: Text(
        piece.symbol,
        style: TextStyle(
          fontSize: size * 0.75,
          color: piece.color == PieceColor.white ? Colors.white : Colors.black,
          fontWeight: piece.type == PieceType.bureaucrat
              ? FontWeight.bold
              : FontWeight.normal,
          shadows: [
            Shadow(
              blurRadius: 3.0,
              color: piece.color == PieceColor.white
                  ? Colors.black.withOpacity(0.8)
                  : Colors.white.withOpacity(0.5),
              offset: const Offset(1.0, 1.0),
            ),
          ],
        ),
      ),
    );

    final isSelectedPiece = viewModel.isDragging &&
        row == viewModel.selectedRow &&
        col == viewModel.selectedCol;

    final draggable = Draggable<Map<String, int>>(
      data: {'row': row, 'col': col},
      feedback: SizedBox(width: size, height: size, child: pieceUI),
      childWhenDragging: Container(),
      onDragStarted: () => viewModel.onDragStarted(row, col),
      onDraggableCanceled: (_, __) => viewModel.onDragEnd(),
      onDragEnd: (_) => viewModel.onDragEnd(),
      child: GestureDetector(
        onTap: () => viewModel.onSquareTapped(row, col),
        child: pieceUI,
      ),
    );

    if (viewModel.isDragging && !isSelectedPiece) {
      return IgnorePointer(child: draggable);
    }

    return draggable;
  }

  Widget _buildSquare(BuildContext context, int row, int col) {
    final viewModel = context.watch<ChessViewModel>();
    final isLight = (row + col) % 2 == 0;
    final isSelected =
        viewModel.selectedRow == row && viewModel.selectedCol == col;
    final isValidMove = viewModel.validMoves.any(
          (move) => move[0] == row && move[1] == col,
    );
    final lastMove = viewModel.lastMove;
    final isLastMoveSquare = lastMove != null &&
        ((lastMove.fromRow == row && lastMove.fromCol == col) ||
            (lastMove.toRow == row && lastMove.toCol == col));

    // --- MODIFICATION START ---
    final hintMove = viewModel.hintMove;
    final isHintSquare = hintMove != null &&
        ((hintMove[0] == row && hintMove[1] == col) ||
            (hintMove[2] == row && hintMove[3] == col));
    // --- MODIFICATION END ---

    Color squareColor =
    isLight ? const Color(0xFFF0D9B5) : const Color(0xFFB58863);
    if (isLastMoveSquare) {
      squareColor = isLight ? const Color(0xFFCBC09A) : const Color(0xFFAAA27A);
    } else if (isHintSquare) {
      // --- MODIFICATION START ---
      squareColor =
      isLight ? Colors.cyan.shade100 : Colors.cyan.shade400;
      // --- MODIFICATION END ---
    }

    return DragTarget<Map<String, int>>(
      onWillAccept: (data) =>
          viewModel.validMoves.any((move) => move[0] == row && move[1] == col),
      onAccept: (data) => viewModel.onDrop(row, col),
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          onTap: () => viewModel.onSquareTapped(row, col),
          child: Container(
            decoration: BoxDecoration(
              color: squareColor,
              border: isSelected
                  ? Border.all(color: Colors.blue.shade400, width: 3)
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isValidMove)
                  Container(
                    decoration: BoxDecoration(
                      color: viewModel.engine.board[row][col] == null
                          ? Colors.green.withOpacity(0.4)
                          : Colors.red.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    margin: EdgeInsets.all(
                      viewModel.engine.board[row][col] == null ? 18 : 4,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}