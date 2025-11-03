import 'package:flutter/material.dart';

// Main entry point for the application
void main() {
  runApp(const BureaucratChessApp());
}

// The root widget of the application
class BureaucratChessApp extends StatelessWidget {
  const BureaucratChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bureaucrat Chess',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: const Color(0xFF3B82F6),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ),
      home: const ChessGame(),
      debugShowCheckedModeBanner: false,
    );
  }
}

//==============================================================================
// DATA MODELS
//==============================================================================

enum PieceType { king, queen, rook, bishop, knight, pawn, bureaucrat }

enum PieceColor { white, black }

class ChessPiece {
  static int _nextId = 0;
  final int id;
  final PieceType type;
  final PieceColor color;
  bool hasMoved;

  ChessPiece(this.type, this.color, {this.hasMoved = false}) : id = _nextId++;

  ChessPiece._copy(this.id, this.type, this.color, {this.hasMoved = false});

  ChessPiece copyWith({bool? hasMoved}) {
    return ChessPiece._copy(
      id,
      type,
      color,
      hasMoved: hasMoved ?? this.hasMoved,
    );
  }

  String get symbol {
    const symbols = {
      PieceType.king: {'white': '♔', 'black': '♚'},
      PieceType.queen: {'white': '♕', 'black': '♛'},
      PieceType.rook: {'white': '♖', 'black': '♜'},
      PieceType.bishop: {'white': '♗', 'black': '♝'},
      PieceType.knight: {'white': '♘', 'black': '♞'},
      PieceType.pawn: {'white': '♙', 'black': '♟'},
      PieceType.bureaucrat: {'white': 'B', 'black': 'B'},
    };
    return symbols[type]![color.name]!;
  }
}

class Move {
  final int fromRow, fromCol, toRow, toCol;
  final ChessPiece piece;
  ChessPiece? capturedPiece;
  bool isCastling;
  bool isEnPassant;
  PieceType? promotionType;
  final bool pieceHadMoved;
  final int? previousEnPassantCol;
  final int fiftyMoveRuleCounter;

  Move(
    this.fromRow,
    this.fromCol,
    this.toRow,
    this.toCol, {
    required this.piece,
    required this.pieceHadMoved,
    this.capturedPiece,
    this.isCastling = false,
    this.isEnPassant = false,
    this.promotionType,
    this.previousEnPassantCol,
    required this.fiftyMoveRuleCounter,
  });
}

//==============================================================================
// CHESS ENGINE (CORE LOGIC)
//==============================================================================

class ChessEngine {
  late List<List<ChessPiece?>> board;
  PieceColor currentPlayer = PieceColor.white;
  List<Move> moveHistory = [];
  String gameStatus = '';
  bool whiteBureaucratDeployed = false;
  bool blackBureaucratDeployed = false;
  int? enPassantCol;
  Map<String, int> boardStateHistory = {};
  int fiftyMoveRuleCounter = 0;
  List<ChessPiece> whiteCaptured = [];
  List<ChessPiece> blackCaptured = [];

  ChessEngine() {
    initializeBoard();
  }

  void initializeBoard() {
    board = List.generate(8, (_) => List.filled(8, null));
    // Pawns
    for (int i = 0; i < 8; i++) {
      board[1][i] = ChessPiece(PieceType.pawn, PieceColor.black);
      board[6][i] = ChessPiece(PieceType.pawn, PieceColor.white);
    }
    // Rooks, Knights, Bishops, Queens, Kings...
    const pieces = [
      PieceType.rook,
      PieceType.knight,
      PieceType.bishop,
      PieceType.queen,
      PieceType.king,
      PieceType.bishop,
      PieceType.knight,
      PieceType.rook,
    ];
    for (int i = 0; i < 8; i++) {
      board[0][i] = ChessPiece(pieces[i], PieceColor.black);
      board[7][i] = ChessPiece(pieces[i], PieceColor.white);
    }

    currentPlayer = PieceColor.white;
    moveHistory.clear();
    gameStatus = '';
    whiteBureaucratDeployed = false;
    blackBureaucratDeployed = false;
    enPassantCol = null;
    boardStateHistory.clear();
    fiftyMoveRuleCounter = 0;
    whiteCaptured.clear();
    blackCaptured.clear();
    _recordBoardState();
  }

  Move? makeMove(
    int fromRow,
    int fromCol,
    int toRow,
    int toCol, {
    PieceType? promotionChoice,
  }) {
    if (isGameOver()) return null;
    final piece = board[fromRow][fromCol]!;
    final capturedPiece = board[toRow][toCol];

    int currentFiftyMoveCounter = fiftyMoveRuleCounter;
    if (piece.type == PieceType.pawn || capturedPiece != null) {
      fiftyMoveRuleCounter = 0;
    } else {
      fiftyMoveRuleCounter++;
    }

    final move = Move(
      fromRow,
      fromCol,
      toRow,
      toCol,
      piece: piece,
      pieceHadMoved: piece.hasMoved,
      capturedPiece: capturedPiece,
      previousEnPassantCol: enPassantCol,
      promotionType: promotionChoice,
      fiftyMoveRuleCounter: currentFiftyMoveCounter,
    );

    if (move.capturedPiece != null) {
      (move.capturedPiece!.color == PieceColor.white
              ? whiteCaptured
              : blackCaptured)
          .add(move.capturedPiece!);
    }

    board[fromRow][fromCol] = null;

    if (piece.type == PieceType.king &&
        (move.toCol - move.fromCol).abs() == 2) {
      move.isCastling = true;
      if (move.toCol > move.fromCol) {
        board[move.toRow][5] = board[move.toRow][7];
        board[move.toRow][7] = null;
      } else {
        board[move.toRow][3] = board[move.toRow][0];
        board[move.toRow][0] = null;
      }
    }

    if (piece.type == PieceType.pawn &&
        move.fromCol != move.toCol &&
        move.capturedPiece == null) {
      final capturedRow = fromRow;
      move.isEnPassant = true;
      move.capturedPiece = board[capturedRow][move.toCol];
      if (move.capturedPiece != null) {
        (move.capturedPiece!.color == PieceColor.white
                ? whiteCaptured
                : blackCaptured)
            .add(move.capturedPiece!);
      }
      board[capturedRow][move.toCol] = null;
    }

    board[move.toRow][move.toCol] = move.promotionType != null
        ? ChessPiece(move.promotionType!, piece.color, hasMoved: true)
        : piece.copyWith(hasMoved: true);

    enPassantCol =
        (piece.type == PieceType.pawn && (move.toRow - move.fromRow).abs() == 2)
        ? move.fromCol
        : null;

    moveHistory.add(move);
    switchPlayer();
    _recordBoardState();
    updateGameStatus();
    return move;
  }

  Move? deployBureaucrat(int row, int col) {
    if (isGameOver() || board[row][col] != null) return null;

    final move = Move(
      -1,
      -1,
      row,
      col,
      piece: ChessPiece(PieceType.bureaucrat, currentPlayer),
      pieceHadMoved: false,
      previousEnPassantCol: enPassantCol,
      fiftyMoveRuleCounter: fiftyMoveRuleCounter,
    );

    fiftyMoveRuleCounter = 0;
    board[row][col] = move.piece;
    if (currentPlayer == PieceColor.white) {
      whiteBureaucratDeployed = true;
    } else {
      blackBureaucratDeployed = true;
    }

    moveHistory.add(move);
    switchPlayer();
    _recordBoardState();
    updateGameStatus();
    return move;
  }

  void undoMove() {
    if (moveHistory.isEmpty) return;
    final lastMove = moveHistory.removeLast();
    _unrecordBoardState();

    switchPlayer();
    fiftyMoveRuleCounter = lastMove.fiftyMoveRuleCounter;

    if (lastMove.fromRow == -1) {
      // Bureaucrat deployment
      board[lastMove.toRow][lastMove.toCol] = null;
      if (currentPlayer == PieceColor.white) {
        whiteBureaucratDeployed = false;
      } else {
        blackBureaucratDeployed = false;
      }
    } else {
      var pieceToMoveBack = lastMove.promotionType != null
          ? ChessPiece(PieceType.pawn, lastMove.piece.color)
          : lastMove.piece;

      board[lastMove.fromRow][lastMove.fromCol] = pieceToMoveBack;
      pieceToMoveBack.hasMoved = lastMove.pieceHadMoved;

      if (lastMove.isEnPassant) {
        board[lastMove.toRow][lastMove.toCol] = null;
        board[lastMove.fromRow][lastMove.toCol] = lastMove.capturedPiece;
      } else {
        board[lastMove.toRow][lastMove.toCol] = lastMove.capturedPiece;
      }

      if (lastMove.capturedPiece != null) {
        (lastMove.capturedPiece!.color == PieceColor.white
                ? whiteCaptured
                : blackCaptured)
            .removeLast();
      }

      if (lastMove.isCastling) {
        if (lastMove.toCol > lastMove.fromCol) {
          // Kingside
          board[lastMove.toRow][7] = board[lastMove.toRow][5];
          board[lastMove.toRow][5] = null;
          if (board[lastMove.toRow][7] != null)
            board[lastMove.toRow][7]!.hasMoved = false;
        } else {
          // Queenside
          board[lastMove.toRow][0] = board[lastMove.toRow][3];
          board[lastMove.toRow][3] = null;
          if (board[lastMove.toRow][0] != null)
            board[lastMove.toRow][0]!.hasMoved = false;
        }
      }
    }

    enPassantCol = lastMove.previousEnPassantCol;
    updateGameStatus();
  }

  void updateGameStatus() {
    if (isInCheck(currentPlayer)) {
      if (isCheckmate(currentPlayer)) {
        gameStatus =
            'Checkmate! ${currentPlayer == PieceColor.white ? 'Black' : 'White'} wins!';
      } else {
        gameStatus =
            '${currentPlayer == PieceColor.white ? 'White' : 'Black'} is in check!';
      }
    } else if (isStalemate(currentPlayer)) {
      gameStatus = 'Draw by Stalemate.';
    } else if (isInsufficientMaterial()) {
      gameStatus = 'Draw by Insufficient Material.';
    } else if (isThreefoldRepetition()) {
      gameStatus = 'Draw by Threefold Repetition.';
    } else if (isFiftyMoveRule()) {
      gameStatus = 'Draw by 50-Move Rule.';
    } else {
      gameStatus = '';
    }
  }

  bool isGameOver() =>
      gameStatus.contains('wins') || gameStatus.contains('Draw');

  String _getBoardFen() {
    return board
        .map((row) {
          int emptyCount = 0;
          String rowFen = '';
          for (var piece in row) {
            if (piece == null) {
              emptyCount++;
            } else {
              if (emptyCount > 0) {
                rowFen += emptyCount.toString();
                emptyCount = 0;
              }
              String pieceChar;
              switch (piece.type) {
                case PieceType.knight:
                  pieceChar = 'n';
                  break;
                case PieceType.pawn:
                  pieceChar = 'p';
                  break;
                default:
                  pieceChar = piece.type.name[0];
              }
              rowFen += piece.color == PieceColor.white
                  ? pieceChar.toUpperCase()
                  : pieceChar;
            }
          }
          if (emptyCount > 0) rowFen += emptyCount.toString();
          return rowFen;
        })
        .join('/');
  }

  void _recordBoardState() {
    final fen = _getBoardFen();
    boardStateHistory[fen] = (boardStateHistory[fen] ?? 0) + 1;
  }

  void _unrecordBoardState() {
    final fen = _getBoardFen();
    if (boardStateHistory.containsKey(fen)) {
      boardStateHistory[fen] = boardStateHistory[fen]! - 1;
      if (boardStateHistory[fen] == 0) boardStateHistory.remove(fen);
    }
  }

  bool isThreefoldRepetition() =>
      boardStateHistory.values.any((count) => count >= 3);

  bool isFiftyMoveRule() =>
      fiftyMoveRuleCounter >= 100; // 50 moves by each player
  bool canDeployBureaucrat() =>
      moveHistory.length >= 14 &&
      (currentPlayer == PieceColor.white
          ? !whiteBureaucratDeployed
          : !blackBureaucratDeployed);

  void switchPlayer() => currentPlayer = (currentPlayer == PieceColor.white)
      ? PieceColor.black
      : PieceColor.white;

  List<List<int>> getValidMoves(int row, int col) {
    if (isGameOver()) return [];
    final piece = board[row][col];
    if (piece == null || piece.color != currentPlayer) return [];

    List<List<int>> moves;
    switch (piece.type) {
      case PieceType.pawn:
        moves = _getPawnMoves(row, col, piece);
        break;
      case PieceType.rook:
        moves = _getSlidingMoves(row, col, piece, [
          [1, 0],
          [-1, 0],
          [0, 1],
          [0, -1],
        ]);
        break;
      case PieceType.bishop:
        moves = _getSlidingMoves(row, col, piece, [
          [1, 1],
          [1, -1],
          [-1, 1],
          [-1, -1],
        ]);
        break;
      case PieceType.queen:
        moves = _getSlidingMoves(row, col, piece, [
          [1, 0],
          [-1, 0],
          [0, 1],
          [0, -1],
          [1, 1],
          [1, -1],
          [-1, 1],
          [-1, -1],
        ]);
        break;
      case PieceType.knight:
        moves = _getKnightMoves(row, col, piece);
        break;
      case PieceType.king:
        moves = _getKingMoves(row, col, piece);
        break;
      case PieceType.bureaucrat:
        moves = _getBureaucratMoves();
        break;
    }

    if (piece.type == PieceType.bureaucrat)
      return moves; // Bureaucrat moves don't need check validation
    return moves
        .where((move) => !_wouldBeInCheckAfterMove(row, col, move[0], move[1]))
        .toList();
  }

  List<List<int>> _getBureaucratMoves() {
    List<List<int>> moves = [];
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        if (board[r][c] == null) moves.add([r, c]);
      }
    }
    return moves;
  }

  List<List<int>> _getPawnMoves(int row, int col, ChessPiece piece) {
    List<List<int>> moves = [];
    final direction = piece.color == PieceColor.white ? -1 : 1;
    final startRow = piece.color == PieceColor.white ? 6 : 1;

    if (isValidSquare(row + direction, col) &&
        board[row + direction][col] == null) {
      moves.add([row + direction, col]);
      if (row == startRow && board[row + 2 * direction][col] == null) {
        moves.add([row + 2 * direction, col]);
      }
    }
    for (var dc in [-1, 1]) {
      if (isValidSquare(row + direction, col + dc)) {
        final target = board[row + direction][col + dc];
        if (target != null && target.color != piece.color)
          moves.add([row + direction, col + dc]);
      }
    }
    if (enPassantCol != null && (col - enPassantCol!).abs() == 1) {
      final captureRow = piece.color == PieceColor.white ? 3 : 4;
      if (row == captureRow && isValidSquare(row + direction, enPassantCol!)) {
        moves.add([row + direction, enPassantCol!]);
      }
    }
    return moves;
  }

  List<List<int>> _getKnightMoves(int row, int col, ChessPiece piece) {
    List<List<int>> moves = [];
    final offsets = [
      [2, 1],
      [2, -1],
      [-2, 1],
      [-2, -1],
      [1, 2],
      [1, -2],
      [-1, 2],
      [-1, -2],
    ];
    for (var offset in offsets) {
      final r = row + offset[0], c = col + offset[1];
      if (isValidSquare(r, c) &&
          (board[r][c] == null || board[r][c]!.color != piece.color))
        moves.add([r, c]);
    }
    return moves;
  }

  List<List<int>> _getKingMoves(int row, int col, ChessPiece piece) {
    List<List<int>> moves = [];
    final offsets = [
      [1, 0],
      [-1, 0],
      [0, 1],
      [0, -1],
      [1, 1],
      [1, -1],
      [-1, 1],
      [-1, -1],
    ];
    for (var offset in offsets) {
      final r = row + offset[0], c = col + offset[1];
      if (isValidSquare(r, c) &&
          (board[r][c] == null || board[r][c]!.color != piece.color))
        moves.add([r, c]);
    }
    // Castling
    if (!piece.hasMoved && !isInCheck(piece.color)) {
      // Kingside
      if (board[row][7]?.type == PieceType.rook &&
          !board[row][7]!.hasMoved &&
          board[row][5] == null &&
          board[row][6] == null &&
          !_isSquareAttacked(row, 5, piece.color) &&
          !_isSquareAttacked(row, 6, piece.color)) {
        moves.add([row, 6]);
      }
      // Queenside
      if (board[row][0]?.type == PieceType.rook &&
          !board[row][0]!.hasMoved &&
          board[row][1] == null &&
          board[row][2] == null &&
          board[row][3] == null &&
          !_isSquareAttacked(row, 2, piece.color) &&
          !_isSquareAttacked(row, 3, piece.color)) {
        moves.add([row, 2]);
      }
    }
    return moves;
  }

  List<List<int>> _getSlidingMoves(
    int row,
    int col,
    ChessPiece piece,
    List<List<int>> directions,
  ) {
    List<List<int>> moves = [];
    for (var dir in directions) {
      int r = row + dir[0], c = col + dir[1];
      while (isValidSquare(r, c)) {
        if (board[r][c] == null) {
          moves.add([r, c]);
        } else {
          if (board[r][c]!.color != piece.color) moves.add([r, c]);
          break;
        }
        r += dir[0];
        c += dir[1];
      }
    }
    return moves;
  }

  bool _wouldBeInCheckAfterMove(
    int fromRow,
    int fromCol,
    int toRow,
    int toCol,
  ) {
    final piece = board[fromRow][fromCol]!;
    final captured = board[toRow][toCol];
    board[toRow][toCol] = piece;
    board[fromRow][fromCol] = null;
    final inCheck = isInCheck(piece.color);
    board[fromRow][fromCol] = piece;
    board[toRow][toCol] = captured;
    return inCheck;
  }

  bool isInCheck(PieceColor color) {
    final kingPos = _findKing(color);
    if (kingPos == null) {
      return true; // King is captured, which means it's a losing position
    }
    return _isSquareAttacked(kingPos[0], kingPos[1], color);
  }

  bool _isSquareAttacked(int row, int col, PieceColor kingColor) {
    final opponentColor = kingColor == PieceColor.white
        ? PieceColor.black
        : PieceColor.white;
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final piece = board[r][c];
        if (piece != null && piece.color == opponentColor) {
          // Get raw attacking moves, ignoring check validation to prevent infinite loops
          if (_getRawAttackingMoves(
            r,
            c,
            piece,
          ).any((move) => move[0] == row && move[1] == col))
            return true;
        }
      }
    }
    return false;
  }

  /// Calculates piece moves without validating for check, used for attack detection.
  List<List<int>> _getRawAttackingMoves(int row, int col, ChessPiece piece) {
    switch (piece.type) {
      case PieceType.pawn:
        List<List<int>> moves = [];
        final direction = piece.color == PieceColor.white ? -1 : 1;
        for (var dc in [-1, 1]) {
          if (isValidSquare(row + direction, col + dc)) {
            moves.add([row + direction, col + dc]);
          }
        }
        return moves;
      case PieceType.rook:
        return _getSlidingMoves(row, col, piece, [
          [1, 0],
          [-1, 0],
          [0, 1],
          [0, -1],
        ]);
      case PieceType.bishop:
        return _getSlidingMoves(row, col, piece, [
          [1, 1],
          [1, -1],
          [-1, 1],
          [-1, -1],
        ]);
      case PieceType.queen:
        return _getSlidingMoves(row, col, piece, [
          [1, 0],
          [-1, 0],
          [0, 1],
          [0, -1],
          [1, 1],
          [1, -1],
          [-1, 1],
          [-1, -1],
        ]);
      case PieceType.knight:
        return _getKnightMoves(row, col, piece);
      case PieceType
          .king: // King's raw moves do not include castling for attack checks
        List<List<int>> moves = [];
        final offsets = [
          [1, 0],
          [-1, 0],
          [0, 1],
          [0, -1],
          [1, 1],
          [1, -1],
          [-1, 1],
          [-1, -1],
        ];
        for (var offset in offsets) {
          final r = row + offset[0], c = col + offset[1];
          if (isValidSquare(r, c)) moves.add([r, c]);
        }
        return moves;
      default:
        return [];
    }
  }

  bool isCheckmate(PieceColor color) {
    if (!isInCheck(color)) return false;
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        if (board[r][c]?.color == color && getValidMoves(r, c).isNotEmpty)
          return false;
      }
    }
    return true;
  }

  bool isStalemate(PieceColor color) {
    if (isInCheck(color)) return false;
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        if (board[r][c]?.color == color && getValidMoves(r, c).isNotEmpty) {
          return false;
        }
      }
    }
    return true;
  }

  bool isInsufficientMaterial() {
    final pieces = board.expand((row) => row).whereType<ChessPiece>().toList();
    if (pieces.length <= 2) return true; // King vs King
    if (pieces.length == 3 &&
        pieces.any(
          (p) => p.type == PieceType.knight || p.type == PieceType.bishop,
        ))
      return true; // King & minor vs King
    // King & bishop vs King & bishop (same color squares) - too complex for this implementation
    return false;
  }

  List<int>? _findKing(PieceColor color) {
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        if (board[r][c]?.type == PieceType.king && board[r][c]?.color == color)
          return [r, c];
      }
    }
    return null;
  }

  bool isValidSquare(int row, int col) =>
      row >= 0 && row < 8 && col >= 0 && col < 8;
}

//==============================================================================
// MAIN GAME WIDGET (UI)
//==============================================================================

class ChessGame extends StatefulWidget {
  const ChessGame({super.key});

  @override
  State<ChessGame> createState() => _ChessGameState();
}

class _ChessGameState extends State<ChessGame> {
  final ChessEngine _engine = ChessEngine();

  // UI State
  int? _selectedRow, _selectedCol;
  List<List<int>> _validMoves = [];
  bool _isPromotionDialogVisible = false;
  Move? _pendingPromotionMove;
  Move? _lastMove;
  bool _showHelp = false;
  bool _deployingBureaucrat = false;
  bool _isDragging = false; // **FIX**: New state to track dragging

  void _onSquareTapped(int row, int col) {
    if (_engine.isGameOver() || _isPromotionDialogVisible) return;

    if (_deployingBureaucrat) {
      if (_engine.board[row][col] == null) {
        setState(() {
          _lastMove = _engine.deployBureaucrat(row, col);
          _deployingBureaucrat = false;
        });
      } else {
        setState(() {
          _deployingBureaucrat = false;
        });
      }
      return;
    }

    if (_selectedRow != null && _selectedCol != null) {
      if (_validMoves.any((move) => move[0] == row && move[1] == col)) {
        _handleMove(_selectedRow!, _selectedCol!, row, col);
      } else {
        final piece = _engine.board[row][col];
        if (piece != null && piece.color == _engine.currentPlayer) {
          // If tapping another of your own pieces, select it instead
          setState(() {
            _selectedRow = row;
            _selectedCol = col;
            _validMoves = _engine.getValidMoves(row, col);
          });
        } else {
          // Deselect if tapping an empty or invalid square
          setState(() {
            _selectedRow = null;
            _selectedCol = null;
            _validMoves = [];
          });
        }
      }
    } else {
      final piece = _engine.board[row][col];
      if (piece != null && piece.color == _engine.currentPlayer) {
        setState(() {
          _selectedRow = row;
          _selectedCol = col;
          _validMoves = _engine.getValidMoves(row, col);
        });
      }
    }
  }

  void _onDragStarted(int row, int col) {
    if (_engine.isGameOver()) return;
    final piece = _engine.board[row][col];
    if (piece != null && piece.color == _engine.currentPlayer) {
      setState(() {
        _selectedRow = row;
        _selectedCol = col;
        _validMoves = _engine.getValidMoves(row, col);
        _isDragging = true; // **FIX**: Set dragging state to true
      });
    }
  }

  void _onDragEnd() {
    // **FIX**: Combined drag end logic for both drop and cancel
    if (_selectedRow != null && _selectedCol != null) {
      final move = _validMoves.firstWhere(
        (m) => m[0] == _selectedRow && m[1] == _selectedCol,
        orElse: () => [-1, -1],
      );
      if (move[0] != -1) {
        _handleMove(_selectedRow!, _selectedCol!, move[0], move[1]);
      }
    }
    setState(() {
      _selectedRow = null;
      _selectedCol = null;
      _validMoves = [];
      _isDragging = false; // **FIX**: Reset dragging state
    });
  }

  void _onDrop(int toRow, int toCol) {
    // **FIX**: Logic for when a piece is successfully dropped on a target
    if (_selectedRow != null && _selectedCol != null) {
      if (_validMoves.any((m) => m[0] == toRow && m[1] == toCol)) {
        _handleMove(_selectedRow!, _selectedCol!, toRow, toCol);
      }
    }
    setState(() {
      _selectedRow = null;
      _selectedCol = null;
      _validMoves = [];
      _isDragging = false; // **FIX**: Reset dragging state
    });
  }

  void _handleMove(int fromRow, int fromCol, int toRow, int toCol) {
    final piece = _engine.board[fromRow][fromCol]!;
    if (piece.type == PieceType.pawn && (toRow == 0 || toRow == 7)) {
      setState(() {
        _pendingPromotionMove = Move(
          fromRow,
          fromCol,
          toRow,
          toCol,
          piece: piece,
          pieceHadMoved: piece.hasMoved,
          fiftyMoveRuleCounter: _engine.fiftyMoveRuleCounter,
          capturedPiece: _engine.board[toRow][toCol],
          previousEnPassantCol: _engine.enPassantCol,
        );
        _isPromotionDialogVisible = true;
      });
    } else {
      _completeMove(fromRow, fromCol, toRow, toCol);
    }
  }

  void _completeMove(
    int fromRow,
    int fromCol,
    int toRow,
    int toCol, {
    PieceType? promotionChoice,
  }) {
    setState(() {
      _lastMove = _engine.makeMove(
        fromRow,
        fromCol,
        toRow,
        toCol,
        promotionChoice: promotionChoice,
      );
      _selectedRow = null;
      _selectedCol = null;
      _validMoves = [];
      _isPromotionDialogVisible = false;
      _pendingPromotionMove = null;
    });
  }

  void _resetGame() => setState(() {
    _engine.initializeBoard();
    _lastMove = null;
    _validMoves.clear();
    _selectedRow = null;
    _selectedCol = null;
    _deployingBureaucrat = false;
  });

  void _undoMove() => setState(() {
    _engine.undoMove();
    _lastMove = _engine.moveHistory.isNotEmpty
        ? _engine.moveHistory.last
        : null;
    _validMoves.clear();
    _selectedRow = null;
    _selectedCol = null;
    _deployingBureaucrat = false;
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Stack(
                  children: [
                    Column(
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 16),
                        if (_engine.gameStatus.isNotEmpty) _buildStatusBanner(),
                        if (_deployingBureaucrat) _buildDeploymentBanner(),
                        const SizedBox(height: 16),
                        _buildCapturedPieces(PieceColor.black),
                        const SizedBox(height: 8),
                        _buildChessBoard(),
                        const SizedBox(height: 8),
                        _buildCapturedPieces(PieceColor.white),
                        const SizedBox(height: 24),
                        _buildControls(),
                        if (_showHelp) _buildHelp(),
                        const SizedBox(height: 24),
                        _buildMoveHistory(),
                      ],
                    ),
                    if (_isPromotionDialogVisible) _buildPromotionDialog(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
              'Move ${(_engine.moveHistory.length / 2).ceil() + 1} • ${_engine.currentPlayer.name[0].toUpperCase()}${_engine.currentPlayer.name.substring(1)} to move',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
        IconButton(
          icon: Icon(
            _showHelp ? Icons.close : Icons.help_outline,
            color: Colors.blue.shade300,
          ),
          onPressed: () => setState(() => _showHelp = !_showHelp),
        ),
      ],
    );
  }

  Widget _buildStatusBanner() {
    final bool isCheck = _engine.gameStatus.contains('check');
    final bool isWin = _engine.gameStatus.contains('wins');
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
        _engine.gameStatus,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDeploymentBanner() {
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

  Widget _buildCapturedPieces(PieceColor color) {
    final pieces = color == PieceColor.white
        ? _engine.whiteCaptured
        : _engine.blackCaptured;
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

  Widget _buildChessBoard() {
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
                    return _buildSquare(row, col);
                  },
                  itemCount: 64,
                  physics: const NeverScrollableScrollPhysics(),
                ),
                ..._buildPieces(squareSize),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildPieces(double squareSize) {
    final List<Widget> pieceWidgets = [];
    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        final piece = _engine.board[row][col];
        if (piece != null) {
          pieceWidgets.add(
            AnimatedPositioned(
              key: ValueKey(piece.id),
              duration: const Duration(milliseconds: 150),
              left: col * squareSize,
              top: row * squareSize,
              width: squareSize,
              height: squareSize,
              child: _buildPiece(piece, row, col, squareSize),
            ),
          );
        }
      }
    }
    return pieceWidgets;
  }

  Widget _buildPiece(ChessPiece piece, int row, int col, double size) {
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

    final isSelectedPiece =
        _isDragging && row == _selectedRow && col == _selectedCol;

    final draggable = Draggable<Map<String, int>>(
      data: {'row': row, 'col': col},
      feedback: SizedBox(width: size, height: size, child: pieceUI),
      childWhenDragging: Container(),
      onDragStarted: () => _onDragStarted(row, col),
      onDraggableCanceled: (_, __) => _onDragEnd(),
      onDragEnd: (_) => _onDragEnd(),
      child: GestureDetector(
        onTap: () => _onSquareTapped(row, col),
        child: pieceUI,
      ),
    );

    // **FIX**: Wrap pieces in IgnorePointer during a drag, unless it's the piece being dragged.
    if (_isDragging && !isSelectedPiece) {
      return IgnorePointer(child: draggable);
    }

    return draggable;
  }

  Widget _buildSquare(int row, int col) {
    final isLight = (row + col) % 2 == 0;
    final isSelected = _selectedRow == row && _selectedCol == col;
    final isValidMove = _validMoves.any(
      (move) => move[0] == row && move[1] == col,
    );
    final isLastMoveSquare =
        _lastMove != null &&
        ((_lastMove!.fromRow == row && _lastMove!.fromCol == col) ||
            (_lastMove!.toRow == row && _lastMove!.toCol == col));

    Color squareColor = isLight
        ? const Color(0xFFF0D9B5)
        : const Color(0xFFB58863);
    if (isLastMoveSquare)
      squareColor = isLight ? const Color(0xFFCBC09A) : const Color(0xFFAAA27A);

    return DragTarget<Map<String, int>>(
      onWillAccept: (data) =>
          _validMoves.any((move) => move[0] == row && move[1] == col),
      onAccept: (data) => _onDrop(row, col),
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          onTap: () => _onSquareTapped(row, col),
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
                      color: _engine.board[row][col] == null
                          ? Colors.green.withOpacity(0.4)
                          : Colors.red.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    margin: EdgeInsets.all(
                      _engine.board[row][col] == null ? 18 : 4,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: _resetGame,
          icon: const Icon(Icons.refresh),
          label: const Text('New Game'),
        ),
        ElevatedButton.icon(
          onPressed: _engine.moveHistory.isNotEmpty ? _undoMove : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange.shade700,
          ),
          icon: const Icon(Icons.undo),
          label: const Text('Undo'),
        ),
        if (_engine.canDeployBureaucrat() && !_deployingBureaucrat)
          ElevatedButton.icon(
            onPressed: () => setState(() => _deployingBureaucrat = true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade700,
            ),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Deploy Bureaucrat'),
          ),
      ],
    );
  }

  Widget _buildPromotionDialog() {
    final color = _pendingPromotionMove!.piece.color;
    final promotionPieces = [
      PieceType.queen,
      PieceType.rook,
      PieceType.bishop,
      PieceType.knight,
    ];
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade700),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Promote Pawn To:",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: promotionPieces.map((type) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: GestureDetector(
                        onTap: () => _completeMove(
                          _pendingPromotionMove!.fromRow,
                          _pendingPromotionMove!.fromCol,
                          _pendingPromotionMove!.toRow,
                          _pendingPromotionMove!.toCol,
                          promotionChoice: type,
                        ),
                        child: Text(
                          ChessPiece(type, color).symbol,
                          style: const TextStyle(fontSize: 48),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoveHistory() {
    if (_engine.moveHistory.isEmpty) return const SizedBox.shrink();
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
              itemCount: (_engine.moveHistory.length / 2).ceil(),
              itemBuilder: (context, index) {
                final whiteMove = _engine.moveHistory[index * 2];
                final blackMove = index * 2 + 1 < _engine.moveHistory.length
                    ? _engine.moveHistory[index * 2 + 1]
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
                      Expanded(child: Text(_formatMove(whiteMove))),
                      if (blackMove != null)
                        Expanded(child: Text(_formatMove(blackMove)))
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

  String _formatMove(Move move) {
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

  Widget _buildHelp() {
    return Container(
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
            'How to Play',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade300,
            ),
          ),
          const SizedBox(height: 12),
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
