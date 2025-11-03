import 'piece_model.dart';

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

  final List<bool> castlingRights; // [WK, WQ, BK, BQ]

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
        required this.castlingRights,
      });
}