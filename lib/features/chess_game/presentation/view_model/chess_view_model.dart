import 'dart:async';
import 'package:bureaucratic_chess/features/chess_game/data/models/move_model.dart';
import 'package:bureaucratic_chess/features/chess_game/data/models/piece_model.dart';
import 'package:bureaucratic_chess/features/chess_game/domain/chess_ai.dart';
import 'package:bureaucratic_chess/features/chess_game/domain/chess_engine.dart';
import 'package:flutter/foundation.dart';

class ChessViewModel extends ChangeNotifier {
  final ChessEngine _engine = ChessEngine();
  ChessEngine get engine => _engine;

  // --- AI & HINT MODIFICATION START ---
  final ChessAI _ai = ChessAI();
  bool _isAIGame = false;
  int _aiDifficulty = 3; // Default level 3
  bool _isThinking = false; // To show a loading spinner
  List<int>? _hintMove; // [fromRow, fromCol, toRow, toCol]

  // --- NEW: Player Color & Pause State ---
  PieceColor _playerColor = PieceColor.white;
  PieceColor get playerColor => _playerColor;
  bool _isPaused = false;
  bool get isPaused => _isPaused;
  // --- END NEW ---

  bool get isAIGame => _isAIGame;
  bool get isThinking => _isThinking;
  List<int>? get hintMove => _hintMove;
  // --- AI & HINT MODIFICATION END ---

  // UI State
  int? _selectedRow, _selectedCol;
  int? get selectedRow => _selectedRow;
  int? get selectedCol => _selectedCol;

  List<List<int>> _validMoves = [];
  List<List<int>> get validMoves => _validMoves;

  bool _isPromotionDialogVisible = false;
  bool get isPromotionDialogVisible => _isPromotionDialogVisible;

  Move? _pendingPromotionMove;
  Move? get pendingPromotionMove => _pendingPromotionMove;

  Move? _lastMove;
  Move? get lastMove => _lastMove;

  bool _showHelp = false;
  bool get showHelp => _showHelp;

  bool _deployingBureaucrat = false;
  bool get deployingBureaucrat => _deployingBureaucrat;

  bool _isDragging = false;
  bool get isDragging => _isDragging;

  // Timer State
  Duration _whiteTime = Duration.zero;
  Duration _blackTime = Duration.zero;
  Timer? _timer;

  Duration get whiteTime => _whiteTime;
  Duration get blackTime => _blackTime;

  // 1. Default to timer being disabled.
  bool _isTimerEnabled = false;
  bool get isTimerEnabled => _isTimerEnabled;

  Duration _initialTimeSetting = const Duration(minutes: 5);

  // 2. The constructor is now empty as the game starts untimed.
  ChessViewModel();

  // --- AI & PLAYER COLOR MODIFICATION ---
  // 3. This method now handles starting a new game with ALL settings.
  void updateTimeSetting(
      Duration? newTime, {
        bool isAIGame = false,
        int aiDifficulty = 3,
        PieceColor playerColor = PieceColor.white,
      }) {
    if (newTime == null) {
      _isTimerEnabled = false;
    } else {
      _isTimerEnabled = true;
      _initialTimeSetting = newTime;
    }

    // Set AI state
    _isAIGame = isAIGame;
    _aiDifficulty = aiDifficulty;
    _playerColor = playerColor;

    // Perform a full game reset
    _engine.initializeBoard();
    _lastMove = null;
    _validMoves.clear();
    _selectedRow = null;
    _selectedCol = null;
    _deployingBureaucrat = false;
    _isThinking = false;
    _hintMove = null;
    _isPaused = false;
    _initializeTimers();
    notifyListeners();

    // --- NEW: If AI is White, it moves first ---
    _makeAIMove();
  }
  // --- AI MODIFICATION END ---

  // 4. The "New Game" button now resets to an untimed, human vs human game.
  void resetGame() {
    updateTimeSetting(null, isAIGame: false);
  }

  void _initializeTimers() {
    _stopTimer();
    if (!_isTimerEnabled) {
      _whiteTime = Duration.zero;
      _blackTime = Duration.zero;
      return;
    }
    _whiteTime = _initialTimeSetting;
    _blackTime = _initialTimeSetting;
    _startTimer();
  }

  void _startTimer() {
    if (!_isTimerEnabled) return;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      // --- PAUSE MODIFICATION ---
      if (_isPaused) return;
      // --- END PAUSE ---

      if (_engine.isGameOver()) {
        _stopTimer();
        return;
      }

      if (_engine.currentPlayer == PieceColor.white) {
        if (_whiteTime.inSeconds == 0) {
          _engine.gameStatus = 'Black wins on time!';
          _stopTimer();
        } else {
          _whiteTime -= const Duration(seconds: 1);
        }
      } else {
        if (_blackTime.inSeconds == 0) {
          _engine.gameStatus = 'White wins on time!';
          _stopTimer();
        } else {
          _blackTime -= const Duration(seconds: 1);
        }
      }
      notifyListeners();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void onSquareTapped(int row, int col) {
    // --- AI/PAUSE MODIFICATION ---
    // Clear hint on any tap
    if (_hintMove != null) _hintMove = null;

    // Don't allow moves if paused, AI is thinking, or it's not player's turn
    if (_isPaused ||
        _isThinking ||
        _engine.isGameOver() ||
        _isPromotionDialogVisible ||
        (_isAIGame && _engine.currentPlayer != _playerColor)) {
      notifyListeners(); // To clear the hint
      return;
    }
    // --- AI/PAUSE MODIFICATION END ---

    if (_deployingBureaucrat) {
      if (_engine.board[row][col] == null) {
        _lastMove = _engine.deployBureaucrat(row, col);
        _deployingBureaucrat = false;
      } else {
        _deployingBureaucrat = false;
      }
      notifyListeners();
      // --- AI MODIFICATION ---
      // We made a move, so let the AI move.
      _makeAIMove();
      // --- AI MODIFICATION END ---
      return;
    }

    if (_selectedRow != null && _selectedCol != null) {
      if (_validMoves.any((move) => move[0] == row && move[1] == col)) {
        _handleMove(_selectedRow!, _selectedCol!, row, col);
      } else {
        final piece = _engine.board[row][col];
        if (piece != null && piece.color == _engine.currentPlayer) {
          _selectedRow = row;
          _selectedCol = col;
          _validMoves = _engine.getValidMoves(row, col);
        } else {
          _selectedRow = null;
          _selectedCol = null;
          _validMoves = [];
        }
      }
    } else {
      final piece = _engine.board[row][col];
      if (piece != null && piece.color == _engine.currentPlayer) {
        _selectedRow = row;
        _selectedCol = col;
        _validMoves = _engine.getValidMoves(row, col);
      }
    }
    notifyListeners();
  }

  void onDragStarted(int row, int col) {
    // --- AI/PAUSE MODIFICATION ---
    if (_isPaused ||
        _isThinking ||
        _engine.isGameOver() ||
        (_isAIGame && _engine.currentPlayer != _playerColor)) return;
    // --- AI/PAUSE MODIFICATION END ---

    final piece = _engine.board[row][col];
    if (piece != null && piece.color == _engine.currentPlayer) {
      _selectedRow = row;
      _selectedCol = col;
      _validMoves = _engine.getValidMoves(row, col);
      _isDragging = true;
      notifyListeners();
    }
  }

  void onDrop(int toRow, int toCol) {
    if (_selectedRow != null && _selectedCol != null) {
      if (_validMoves.any((m) => m[0] == toRow && m[1] == toCol)) {
        _handleMove(_selectedRow!, _selectedCol!, toRow, toCol);
      }
    }
    _resetSelection();
  }

  void onDragEnd() {
    _resetSelection();
  }

  void _resetSelection() {
    _selectedRow = null;
    _selectedCol = null;
    _validMoves = [];
    _isDragging = false;
    notifyListeners();
  }

  Future<void> _handleMove(int fromRow, int fromCol, int toRow, int toCol) async {
    final piece = _engine.board[fromRow][fromCol]!;
    if (piece.type == PieceType.pawn && (toRow == 0 || toRow == 7)) {
      _pendingPromotionMove = Move(
        fromRow, fromCol, toRow, toCol,
        piece: piece,
        pieceHadMoved: piece.hasMoved,
        fiftyMoveRuleCounter: _engine.fiftyMoveRuleCounter,
        capturedPiece: _engine.board[toRow][toCol],
        previousEnPassantCol: _engine.enPassantCol,
        castlingRights: [_engine.whiteKingSideCastle, _engine.whiteQueenSideCastle, _engine.blackKingSideCastle, _engine.blackQueenSideCastle],
      );
      _isPromotionDialogVisible = true;
    } else {
      await completeMove(fromRow, fromCol, toRow, toCol);
    }
    notifyListeners();
  }

  Future<void> completeMove(int fromRow, int fromCol, int toRow, int toCol,
      {PieceType? promotionChoice}) async {
    _lastMove = _engine.makeMove(fromRow, fromCol, toRow, toCol,
        promotionChoice: promotionChoice);
    _selectedRow = null;
    _selectedCol = null;
    _validMoves = [];
    _isPromotionDialogVisible = false;
    _pendingPromotionMove = null;

    if (_engine.isGameOver()) {
      _stopTimer();
    }
    notifyListeners();

    // After the human move is completed, trigger the AI move.
    await _makeAIMove();
  }

  void undoMove() {
    if (_isThinking) return; // Don't undo while AI is thinking

    _engine.undoMove();

    // If it's an AI game and there are moves left
    if (_isAIGame && _engine.moveHistory.isNotEmpty) {
      _engine.undoMove(); // Undo the AI's move as well
    }

    _lastMove = _engine.moveHistory.isNotEmpty ? _engine.moveHistory.last : null;
    _validMoves.clear();
    _selectedRow = null;
    _selectedCol = null;
    _deployingBureaucrat = false;
    notifyListeners();
  }

  void resign() {
    _engine.resign();
    _stopTimer();
    notifyListeners();
  }

  // --- NEW PAUSE METHOD ---
  void togglePause() {
    _isPaused = !_isPaused;
    notifyListeners();
  }
  // --- END NEW METHOD ---

  void toggleHelp() {
    _showHelp = !_showHelp;
    notifyListeners();
  }

  void toggleDeployingBureaucrat() {
    _deployingBureaucrat = true;
    notifyListeners();
  }

  String formatMove(Move move) {
    if (move.fromRow == -1)
      return "B @ ${_getAlgebraic(move.toRow, move.toCol)}";
    final pieceType = move.piece.type;
    String pieceSymbol = "";
    if (pieceType != PieceType.pawn) {
      pieceSymbol = ChessPiece(pieceType, PieceColor.white).symbol[0];
      if (pieceType == PieceType.knight) pieceSymbol = "N";
    }

    if (move.isCastling) return move.toCol > move.fromCol ? 'O-O' : 'O-O-O';
    final to = _getAlgebraic(move.toRow, move.toCol);
    final captured = move.capturedPiece != null ? 'x' : '';
    return "$pieceSymbol$captured$to";
  }

  String _getAlgebraic(int row, int col) {
    final files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    return '${files[col]}${8 - row}';
  }

  // --- AI & HINT METHODS START ---

  /// Triggers the AI to make a move.
  Future<void> _makeAIMove() async {
    // Only run if it's an AI game, it's AI's turn, and game is not over.
    if (!_isAIGame ||
        _engine.currentPlayer == _playerColor ||
        _engine.isGameOver() ||
        _isPaused) {
      return;
    }

    _isThinking = true;
    notifyListeners();

    // --- MODIFICATION: Run AI in background ---
    final String currentFen = _engine.getBoardFen();
    final List<int>? bestMove =
    await _ai.findBestMoveAsync(currentFen, _aiDifficulty);
    // --- END MODIFICATION ---

    _isThinking = false;

    // Check if game state changed (e.g., user reset) while AI was thinking
    if (_engine.getBoardFen() != currentFen) {
      return;
    }

    if (bestMove != null) {
      _engine.makeMove(bestMove[0], bestMove[1], bestMove[2], bestMove[3]);
    } else {
      // AI couldn't find a move (e.g., stalemate/checkmate)
      _engine.updateGameStatus();
    }

    if (_engine.isGameOver()) {
      _stopTimer();
    }
    notifyListeners();
  }

  /// Finds and highlights a hint move.
  Future<void> getHint() async {
    if (_isThinking) return;

    _isThinking = true;
    _hintMove = null;
    notifyListeners();

    // --- MODIFICATION: Run Hint AI in background ---
    final String currentFen = _engine.getBoardFen();
    // Use a medium depth for hints so it's relatively fast.
    final List<int>? hint = await _ai.findBestMoveAsync(currentFen, 3);
    // --- END MODIFICATION ---

    _isThinking = false;

    // Check if game state changed
    if (_engine.getBoardFen() != currentFen) {
      return;
    }

    if (hint != null) {
      _hintMove = hint;
    }
    notifyListeners();

    // Clear the hint after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (_hintMove == hint) {
        _hintMove = null;
        notifyListeners();
      }
    });
  }
// --- AI & HINT METHODS END ---
}