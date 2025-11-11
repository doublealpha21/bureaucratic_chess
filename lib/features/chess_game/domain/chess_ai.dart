import 'dart:math';
import 'package:bureaucratic_chess/features/chess_game/data/models/piece_model.dart';
import 'package:bureaucratic_chess/features/chess_game/domain/ai_evaluator.dart';
import 'package:bureaucratic_chess/features/chess_game/domain/chess_engine.dart';
import 'package:flutter/foundation.dart';

// Top-level function for isolate
List<int>? _runAInBackground(Map<String, dynamic> params) {
  final String fen = params['fen'];
  final int depth = params['depth'];

  final ChessEngine aiEngine = ChessEngine();
  aiEngine.loadFromFen(fen);

  final ChessAI ai = ChessAI();
  return ai.findBestMove(aiEngine, depth);
}

class ChessAI {
  static const int _positiveInfinity = 9999999;
  static const int _negativeInfinity = -_positiveInfinity;

  int _nodesSearched = 0;

  Future<List<int>?> findBestMoveAsync(String fen, int depth) async {
    return await compute(_runAInBackground, {
      'fen': fen,
      'depth': depth,
    });
  }

  /// Finds the best move - simplified, no iterative deepening
  List<int>? findBestMove(ChessEngine engine, int maxDepth) {
    _nodesSearched = 0;
    List<int>? bestMove;
    int bestScore = _negativeInfinity;

    final allMoves = _getAllValidMoves(engine, engine.currentPlayer);

    // ORDER MOVES for better pruning
    _orderMoves(engine, allMoves);

    for (final moveTuple in allMoves) {
      final fromRow = moveTuple[0], fromCol = moveTuple[1],
          toRow = moveTuple[2], toCol = moveTuple[3];

      engine.makeMove(fromRow, fromCol, toRow, toCol);

      int score = -_minimax(
        engine,
        maxDepth - 1,
        -_positiveInfinity,
        -_negativeInfinity,
      );

      engine.undoMove();

      if (score > bestScore) {
        bestScore = score;
        bestMove = moveTuple;
      }
    }

    return bestMove;
  }

  /// Order moves in place (most promising first)
  void _orderMoves(ChessEngine engine, List<List<int>> moves) {
    moves.sort((a, b) {
      int scoreA = _quickMoveScore(engine, a);
      int scoreB = _quickMoveScore(engine, b);
      return scoreB.compareTo(scoreA);
    });
  }

  /// Quick move scoring (no simulation, just heuristics)
  int _quickMoveScore(ChessEngine engine, List<int> move) {
    int score = 0;
    final fromRow = move[0], fromCol = move[1];
    final toRow = move[2], toCol = move[3];

    final piece = engine.board[fromRow][fromCol];
    final capturedPiece = engine.board[toRow][toCol];

    if (piece == null) return score;

    // Prioritize captures (MVV-LVA)
    if (capturedPiece != null) {
      int victimValue = _getPieceValue(capturedPiece.type);
      int attackerValue = _getPieceValue(piece.type);
      score += 10000 + victimValue * 10 - attackerValue;
    }

    // Center bonus
    int centerDist = (toRow - 3).abs() + (toCol - 3).abs();
    score += (6 - centerDist) * 5;

    // Pawn advancement
    if (piece.type == PieceType.pawn) {
      score += piece.color == PieceColor.white ? (7 - toRow) * 10 : toRow * 10;
    }

    return score;
  }

  /// Get simple piece value
  int _getPieceValue(PieceType type) {
    switch (type) {
      case PieceType.pawn: return 100;
      case PieceType.knight: return 320;
      case PieceType.bishop: return 330;
      case PieceType.rook: return 500;
      case PieceType.queen: return 900;
      case PieceType.king: return 20000;
      case PieceType.bureaucrat: return 0;
    }
  }

  /// Simplified minimax - negamax style for cleaner code
  int _minimax(ChessEngine engine, int depth, int alpha, int beta) {
    _nodesSearched++;

    engine.updateGameStatus();
    if (engine.isGameOver()) {
      if (engine.gameStatus.contains("wins")) {
        // If current player lost (opponent won), return very negative
        return engine.gameStatus.contains(engine.currentPlayer == PieceColor.white ? "Black" : "White")
            ? -_positiveInfinity
            : _positiveInfinity;
      }
      return 0; // Draw
    }

    if (depth == 0) {
      return AIEvaluator.evaluate(engine);
    }

    int maxScore = _negativeInfinity;
    final allMoves = _getAllValidMoves(engine, engine.currentPlayer);

    // Quick pruning: if too many moves, only search promising ones
    if (allMoves.length > 35 && depth > 1) {
      _orderMoves(engine, allMoves);
      allMoves.removeRange(35, allMoves.length);
    } else {
      _orderMoves(engine, allMoves);
    }

    for (final moveTuple in allMoves) {
      engine.makeMove(moveTuple[0], moveTuple[1], moveTuple[2], moveTuple[3]);
      int score = -_minimax(engine, depth - 1, -beta, -alpha);
      engine.undoMove();

      maxScore = max(maxScore, score);
      alpha = max(alpha, score);

      if (alpha >= beta) {
        break; // Beta cutoff
      }
    }

    return maxScore;
  }

  /// Get all valid moves for a color
  List<List<int>> _getAllValidMoves(ChessEngine engine, PieceColor color) {
    final List<List<int>> allMoves = [];

    // Regular piece moves
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final piece = engine.board[r][c];
        if (piece != null && piece.color == color) {
          final validTargets = engine.getValidMoves(r, c);
          for (final target in validTargets) {
            allMoves.add([r, c, target[0], target[1]]);
          }
        }
      }
    }
    return allMoves;
  }
}
