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
