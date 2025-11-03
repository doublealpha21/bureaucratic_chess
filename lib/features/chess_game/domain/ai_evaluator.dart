import 'package:bureaucratic_chess/features/chess_game/data/models/piece_model.dart';
import 'package:bureaucratic_chess/features/chess_game/domain/chess_engine.dart';

class AIEvaluator {
  // 1. Define the value of each piece.
  static const Map<PieceType, int> _pieceValues = {
    PieceType.pawn: 100,
    PieceType.knight: 320,
    PieceType.bishop: 330,
    PieceType.rook: 500,
    PieceType.queen: 900,
    PieceType.king: 20000,
    PieceType.bureaucrat: 50, // The Bureaucrat has no material value
  };

  /// Evaluates the current board state and returns a score.
  /// A positive score favors White, a negative score favors Black.
  static int evaluate(ChessEngine engine) {
    int score = 0;

    // 2. Loop through every square on the board.
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final piece = engine.board[r][c];
        if (piece != null) {
          // 3. Get the piece's value
          int pieceValue = _pieceValues[piece.type] ?? 0;

          // 4. Add to the score if White, subtract if Black.
          if (piece.color == PieceColor.white) {
            score += pieceValue;
          } else {
            score -= pieceValue;
          }
        }
      }
    }
    return score;
  }
}