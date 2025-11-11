import 'package:bureaucratic_chess/features/chess_game/data/models/piece_model.dart';
import 'package:bureaucratic_chess/features/chess_game/domain/chess_engine.dart';

class AIEvaluator {
  // Piece values
  static const Map<PieceType, int> _pieceValues = {
    PieceType.pawn: 100,
    PieceType.knight: 320,
    PieceType.bishop: 330,
    PieceType.rook: 500,
    PieceType.queen: 900,
    PieceType.king: 20000,
    PieceType.bureaucrat: 0,
  };

  // Simplified piece-square tables (center values only)
  static const List<int> _centerBonus = [
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 5, 5, 5, 5, 0, 0,
    0, 0, 5, 10, 10, 5, 0, 0,
    0, 0, 5, 10, 10, 5, 0, 0,
    0, 0, 5, 5, 5, 5, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
  ];

  /// Fast evaluation function
  static int evaluate(ChessEngine engine) {
    int score = 0;
    int whiteMaterial = 0;
    int blackMaterial = 0;

    // Material and basic positioning
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final piece = engine.board[r][c];
        if (piece == null) continue;

        int value = _pieceValues[piece.type] ?? 0;

        // Add positional bonuses
        if (piece.type != PieceType.king && piece.type != PieceType.bureaucrat) {
          // Center control bonus
          value += _centerBonus[r * 8 + c];

          // Pawn advancement bonus
          if (piece.type == PieceType.pawn) {
            value += piece.color == PieceColor.white ? (7 - r) * 5 : r * 5;
          }
        }

        // Bureaucrat strategic value
        if (piece.type == PieceType.bureaucrat) {
          value = _evaluateBureaucrat(engine, r, c, piece.color);
        }

        if (piece.color == PieceColor.white) {
          score += value;
          if (piece.type != PieceType.king && piece.type != PieceType.bureaucrat) {
            whiteMaterial += _pieceValues[piece.type]!;
          }
        } else {
          score -= value;
          if (piece.type != PieceType.king && piece.type != PieceType.bureaucrat) {
            blackMaterial += _pieceValues[piece.type]!;
          }
        }
      }
    }

    // Simple mobility bonus (piece count with moves > 0)
    int whiteMobility = 0;
    int blackMobility = 0;

    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final piece = engine.board[r][c];
        if (piece != null && piece.type != PieceType.bureaucrat) {
          int moveCount = engine.getValidMoves(r, c).length;
          if (moveCount > 0) {
            if (piece.color == PieceColor.white) {
              whiteMobility += moveCount;
            } else {
              blackMobility += moveCount;
            }
          }
        }
      }
    }

    score += (whiteMobility - blackMobility) * 3;

    return score;
  }

  /// Fast bureaucrat evaluation
  static int _evaluateBureaucrat(ChessEngine engine, int row, int col, PieceColor color) {
    int score = 0;

    // Reward central placement
    int centerDist = (row - 3).abs() + (col - 3).abs();
    score += (6 - centerDist) * 15;

    // Reward proximity to opponent king
    PieceColor opponentColor = color == PieceColor.white ? PieceColor.black : PieceColor.white;

    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final piece = engine.board[r][c];
        if (piece?.type == PieceType.king && piece?.color == opponentColor) {
          int distToKing = (row - r).abs() + (col - c).abs();
          if (distToKing <= 2) {
            score += 80; // Very close to enemy king
          } else if (distToKing <= 3) {
            score += 40;
          } else if (distToKing <= 4) {
            score += 20;
          }
          break;
        }
      }
    }

    // Reward blocking key central squares
    if ((row == 3 || row == 4) && (col >= 2 && col <= 5)) {
      score += 30;
    }

    return score;
  }
}