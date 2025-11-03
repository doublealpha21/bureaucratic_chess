import 'package:bureaucratic_chess/features/chess_game/data/models/move_model.dart';
import 'package:bureaucratic_chess/features/chess_game/data/models/piece_model.dart';

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

  // --- MODIFICATION: Store castling rights ---
  bool whiteKingSideCastle = true;
  bool whiteQueenSideCastle = true;
  bool blackKingSideCastle = true;
  bool blackQueenSideCastle = true;

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

    // --- MODIFICATION: Reset castling rights ---
    whiteKingSideCastle = true;
    whiteQueenSideCastle = true;
    blackKingSideCastle = true;
    blackQueenSideCastle = true;

    _recordBoardState();
  }

  // --- NEW METHOD: Load a game state from a FEN string ---
  void loadFromFen(String fen) {
    initializeBoard(); // Start with a fresh state
    board = List.generate(8, (_) => List.filled(8, null));
    moveHistory.clear();
    boardStateHistory.clear();

    List<String> parts = fen.split(' ');

    // 1. Board position
    int row = 0, col = 0;
    for (var char in parts[0].runes) {
      if (char == 47) { // '/'
        row++;
        col = 0;
      } else if (char >= 49 && char <= 56) { // '1' to '8'
        col += (char - 48);
      } else {
        PieceType type;
        var pieceChar = String.fromCharCode(char).toLowerCase();
        switch (pieceChar) {
          case 'p': type = PieceType.pawn; break;
          case 'n': type = PieceType.knight; break;
          case 'b': type = PieceType.bishop; break;
          case 'r': type = PieceType.rook; break;
          case 'q': type = PieceType.queen; break;
          case 'k': type = PieceType.king; break;
          case 'b': type = PieceType.bureaucrat; break;
          default: type = PieceType.pawn; // Should not happen
        }
        var color = (char >= 65 && char <= 90) ? PieceColor.white : PieceColor.black;
        board[row][col] = ChessPiece(type, color, hasMoved: true); // Assume moved for simplicity
        col++;
      }
    }

    // 2. Current player
    currentPlayer = (parts[1] == 'w') ? PieceColor.white : PieceColor.black;

    // 3. Castling rights
    whiteKingSideCastle = parts[2].contains('K');
    whiteQueenSideCastle = parts[2].contains('Q');
    blackKingSideCastle = parts[2].contains('k');
    blackQueenSideCastle = parts[2].contains('q');

    // 4. En passant target
    if (parts[3] != '-') {
      enPassantCol = parts[3].codeUnitAt(0) - 'a'.codeUnitAt(0);
    } else {
      enPassantCol = null;
    }

    // 5. Fifty-move rule
    fiftyMoveRuleCounter = int.tryParse(parts[4]) ?? 0;

    // 6. Fullmove number (we track via moveHistory, but good to have)
    // We can't reconstruct moveHistory, so we'll just start from here.

    // Re-evaluate piece 'hasMoved' status based on castling rights
    if (board[7][4]?.type != PieceType.king) whiteKingSideCastle = whiteQueenSideCastle = false;
    if (board[7][0]?.type != PieceType.rook) whiteQueenSideCastle = false;
    if (board[7][7]?.type != PieceType.rook) whiteKingSideCastle = false;
    if (board[0][4]?.type != PieceType.king) blackKingSideCastle = blackQueenSideCastle = false;
    if (board[0][0]?.type != PieceType.rook) blackQueenSideCastle = false;
    if (board[0][7]?.type != PieceType.rook) blackKingSideCastle = false;

    if (board[7][4] != null) board[7][4]!.hasMoved = !(whiteKingSideCastle || whiteQueenSideCastle);
    if (board[7][0] != null) board[7][0]!.hasMoved = !whiteQueenSideCastle;
    if (board[7][7] != null) board[7][7]!.hasMoved = !whiteKingSideCastle;
    if (board[0][4] != null) board[0][4]!.hasMoved = !(blackKingSideCastle || blackQueenSideCastle);
    if (board[0][0] != null) board[0][0]!.hasMoved = !blackQueenSideCastle;
    if (board[0][7] != null) board[0][7]!.hasMoved = !blackKingSideCastle;

    // TODO: Need to track bureaucrat deployment status in FEN
    // For now, assume if one exists, it has been deployed.
    whiteBureaucratDeployed = board.expand((r) => r).any((p) => p?.type == PieceType.bureaucrat && p?.color == PieceColor.white);
    blackBureaucratDeployed = board.expand((r) => r).any((p) => p?.type == PieceType.bureaucrat && p?.color == PieceColor.black);

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

    // --- MODIFICATION: Update castling rights on move ---
    if (piece.type == PieceType.king) {
      if (piece.color == PieceColor.white) {
        whiteKingSideCastle = false;
        whiteQueenSideCastle = false;
      } else {
        blackKingSideCastle = false;
        blackQueenSideCastle = false;
      }
    }
    if (piece.type == PieceType.rook) {
      if (piece.color == PieceColor.white) {
        if (fromCol == 0) whiteQueenSideCastle = false;
        if (fromCol == 7) whiteKingSideCastle = false;
      } else {
        if (fromCol == 0) blackQueenSideCastle = false;
        if (fromCol == 7) blackKingSideCastle = false;
      }
    }
    // --- END MODIFICATION ---

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
      // --- MODIFICATION: Store castling state for undo ---
      castlingRights: [whiteKingSideCastle, whiteQueenSideCastle, blackKingSideCastle, blackQueenSideCastle],
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
      // --- MODIFICATION: Store castling state for undo ---
      castlingRights: [whiteKingSideCastle, whiteQueenSideCastle, blackKingSideCastle, blackQueenSideCastle],
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
    // --- MODIFICATION: Restore previous castling rights ---
    whiteKingSideCastle = lastMove.castlingRights[0];
    whiteQueenSideCastle = lastMove.castlingRights[1];
    blackKingSideCastle = lastMove.castlingRights[2];
    blackQueenSideCastle = lastMove.castlingRights[3];
    // --- END MODIFICATION ---

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
          if (board[lastMove.toRow][7] != null) {
            board[lastMove.toRow][7]!.hasMoved = false;
          }
        } else {
          // Queenside
          board[lastMove.toRow][0] = board[lastMove.toRow][3];
          board[lastMove.toRow][3] = null;
          if (board[lastMove.toRow][0] != null) {
            board[lastMove.toRow][0]!.hasMoved = false;
          }
        }
      }
    }

    enPassantCol = lastMove.previousEnPassantCol;
    updateGameStatus();
  }

  void resign() {
    if (isGameOver()) return;
    gameStatus = currentPlayer == PieceColor.white
        ? 'White resigns. Black wins!'
        : 'Black resigns. White wins!';
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

  // --- MODIFICATION: Now generates a full FEN string ---
  String getBoardFen() {
    String fen = '';
    // 1. Board state
    for (int r = 0; r < 8; r++) {
      int emptyCount = 0;
      for (int c = 0; c < 8; c++) {
        final piece = board[r][c];
        if (piece == null) {
          emptyCount++;
        } else {
          if (emptyCount > 0) {
            fen += emptyCount.toString();
            emptyCount = 0;
          }
          String pieceChar;
          switch (piece.type) {
            case PieceType.pawn: pieceChar = 'p'; break;
            case PieceType.knight: pieceChar = 'n'; break;
            case PieceType.bishop: pieceChar = 'b'; break;
            case PieceType.rook: pieceChar = 'r'; break;
            case PieceType.queen: pieceChar = 'q'; break;
            case PieceType.king: pieceChar = 'k'; break;
            case PieceType.bureaucrat: pieceChar = 'c'; break; // 'b' is bishop
          }
          fen += piece.color == PieceColor.white
              ? pieceChar.toUpperCase()
              : pieceChar;
        }
      }
      if (emptyCount > 0) fen += emptyCount.toString();
      if (r < 7) fen += '/';
    }

    // 2. Current player
    fen += ' ${currentPlayer == PieceColor.white ? 'w' : 'b'}';

    // 3. Castling rights
    String castling = '';
    if (whiteKingSideCastle) castling += 'K';
    if (whiteQueenSideCastle) castling += 'Q';
    if (blackKingSideCastle) castling += 'k';
    if (blackQueenSideCastle) castling += 'q';
    fen += ' ${castling.isEmpty ? '-' : castling}';

    // 4. En passant target
    if (enPassantCol != null) {
      int row = currentPlayer == PieceColor.white ? 2 : 5;
      fen += ' ${_getAlgebraic(row, enPassantCol!).toLowerCase()}';
    } else {
      fen += ' -';
    }

    // 5. Fifty-move rule
    fen += ' $fiftyMoveRuleCounter';

    // 6. Fullmove number
    fen += ' ${(moveHistory.length / 2).floor() + 1}';

    return fen;
  }

  String _getAlgebraic(int row, int col) {
    final files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    return '${files[col]}${8 - row}';
  }
  // --- END MODIFICATION ---

  void _recordBoardState() {
    // Only record the board part of the FEN for 3-fold repetition
    final fen = getBoardFen().split(' ')[0];
    boardStateHistory[fen] = (boardStateHistory[fen] ?? 0) + 1;
  }

  void _unrecordBoardState() {
    // Only record the board part of the FEN for 3-fold repetition
    final fen = getBoardFen().split(' ')[0];
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

    if (piece.type == PieceType.bureaucrat) {
      return moves; // Bureaucrat moves don't need check validation
    }
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
        if (target != null && target.color != piece.color) {
          moves.add([row + direction, col + dc]);
        }
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
          (board[r][c] == null || board[r][c]!.color != piece.color)) {
        moves.add([r, c]);
      }
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
          (board[r][c] == null || board[r][c]!.color != piece.color)) {
        moves.add([r, c]);
      }
    }
    // Castling
    if (!piece.hasMoved && !isInCheck(piece.color)) {
      // Kingside
      final canKingSide = piece.color == PieceColor.white ? whiteKingSideCastle : blackKingSideCastle;
      if (canKingSide &&
          board[row][5] == null &&
          board[row][6] == null &&
          !_isSquareAttacked(row, 5, piece.color) &&
          !_isSquareAttacked(row, 6, piece.color)) {
        moves.add([row, 6]);
      }
      // Queenside
      final canQueenSide = piece.color == PieceColor.white ? whiteQueenSideCastle : blackQueenSideCastle;
      if (canQueenSide &&
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
          ).any((move) => move[0] == row && move[1] == col)) {
            return true;
          }
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
        if (board[r][c]?.color == color && getValidMoves(r, c).isNotEmpty) {
          return false;
        }
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
        )) {
      return true; // King & minor vs King
    }
    // King & bishop vs King & bishop (same color squares) - too complex for this implementation
    return false;
  }

  List<int>? _findKing(PieceColor color) {
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        if (board[r][c]?.type == PieceType.king &&
            board[r][c]?.color == color) {
          return [r, c];
        }
      }
    }
    return null;
  }

  bool isValidSquare(int row, int col) =>
      row >= 0 && row < 8 && col >= 0 && col < 8;
}

// --- MODIFICATION: Need to update Move model ---
// In `move_model.dart`, add this field:
// final List<bool> castlingRights; // [WK, WQ, BK, BQ]
//
// And add it to the constructor:
// required this.castlingRights,