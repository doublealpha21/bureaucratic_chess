import 'dart:math';

import 'package:bureaucratic_chess/features/chess_game/data/models/piece_model.dart';
import 'package:bureaucratic_chess/features/chess_game/domain/ai_evaluator.dart';
import 'package:bureaucratic_chess/features/chess_game/domain/chess_engine.dart';
import 'package:flutter/foundation.dart'; // Import for compute

// --- NEW TOP-LEVEL FUNCTION FOR ISOLATE ---
// This function must be top-level or static.
List<int>? _runAInBackground(Map<String, dynamic> params) {
  final String fen = params['fen'];
  final int depth = params['depth'];

  // Create new instances *inside* the isolate
  final ChessEngine aiEngine = ChessEngine();
  aiEngine.loadFromFen(fen);

  final ChessAI ai = ChessAI();
  return ai.findBestMove(aiEngine, depth);
}
// --- END NEW FUNCTION ---

class ChessAI {
  // Use large (but not infinite) values to prevent integer overflow.
  static const int _positiveInfinity = 9999999;
  static const int _negativeInfinity = -_positiveInfinity;

  // --- NEW PUBLIC METHOD for compute ---
  Future<List<int>?> findBestMoveAsync(String fen, int depth) async {
    return await compute(_runAInBackground, {
      'fen': fen,
      'depth': depth,
    });
  }
  // --- END NEW METHOD ---


  /// Finds the best move for the current player.
  /// Returns a List [fromRow, fromCol, toRow, toCol]
  List<int>? findBestMove(ChessEngine engine, int depth) {
    List<int>? bestMove;
    int bestScore = _negativeInfinity;

    // The AI is the 'Maximizing' player (it wants the highest score).
    // It assumes the opponent is the 'Minimizing' player.
    final allMoves = _getAllValidMoves(engine, engine.currentPlayer);
    // Optional: Shuffle moves to add variation in games
    allMoves.shuffle();

    for (final moveTuple in allMoves) {
      final fromRow = moveTuple[0],
          fromCol = moveTuple[1],
          toRow = moveTuple[2],
          toCol = moveTuple[3];

      // 1. Make the move
      engine.makeMove(fromRow, fromCol, toRow, toCol);

      // 2. Call minimax for the *opponent* (minimizing player)
      int score = _minimax(
        engine,
        depth - 1,
        _negativeInfinity,
        _positiveInfinity,
        false, // 'false' because it's now the minimizing player's turn
      );

      // 3. Undo the move to restore the board
      engine.undoMove();

      // 4. Update the best score
      if (score > bestScore) {
        bestScore = score;
        bestMove = moveTuple;
      }
    }
    return bestMove;
  }

  /// The recursive Minimax algorithm with Alpha-Beta Pruning.
  int _minimax(
      ChessEngine engine,
      int depth,
      int alpha,
      int beta,
      bool isMaximizingPlayer,
      ) {
    // --- Base Case: Check for game over or max depth ---
    engine.updateGameStatus();
    if (engine.isGameOver()) {
      if (engine.gameStatus.contains("White wins")) return _positiveInfinity;
      if (engine.gameStatus.contains("Black wins")) return _negativeInfinity;
      return 0; // Draw
    }

    if (depth == 0) {
      return AIEvaluator.evaluate(engine);
    }

    // --- Recursive Step ---

    if (isMaximizingPlayer) {
      int bestScore = _negativeInfinity;
      final allMoves = _getAllValidMoves(engine, engine.currentPlayer);

      for (final moveTuple in allMoves) {
        engine.makeMove(
            moveTuple[0], moveTuple[1], moveTuple[2], moveTuple[3]);
        int score = _minimax(engine, depth - 1, alpha, beta, false);
        engine.undoMove();

        bestScore = max(bestScore, score);
        alpha = max(alpha, bestScore);
        if (beta <= alpha) {
          break; // Beta cut-off
        }
      }
      return bestScore;
    }

    // else (isMinimizingPlayer)
    else {
      int bestScore = _positiveInfinity;
      final allMoves = _getAllValidMoves(engine, engine.currentPlayer);

      for (final moveTuple in allMoves) {
        engine.makeMove(
            moveTuple[0], moveTuple[1], moveTuple[2], moveTuple[3]);
        int score = _minimax(engine, depth - 1, alpha, beta, true);
        engine.undoMove();

        bestScore = min(bestScore, score);
        beta = min(beta, bestScore);
        if (beta <= alpha) {
          break; // Alpha cut-off
        }
      }
      return bestScore;
    }
  }

  /// Helper function to get all possible moves for a given color.
  /// Returns a list of [fromRow, fromCol, toRow, toCol]
  List<List<int>> _getAllValidMoves(ChessEngine engine, PieceColor color) {
    final List<List<int>> allMoves = [];
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