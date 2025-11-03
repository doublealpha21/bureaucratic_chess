// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
//
// import 'core/theme/theme.dart';
// import 'features/chess_game/presentation/chess_screen.dart';
// import 'features/chess_game/presentation/view_model/chess_view_model.dart';
//
// void main() {
//   runApp(const BureaucratChessApp());
// }
//
// class BureaucratChessApp extends StatelessWidget {
//   const BureaucratChessApp({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider(
//       create: (_) => ChessViewModel(),
//       child: MaterialApp(
//         title: 'Bureaucrat Chess',
//         theme: AppTheme.darkTheme,
//         home: const ChessScreen(),
//         debugShowCheckedModeBanner: false,
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/theme.dart';
import 'features/chess_game/presentation/view_model/chess_view_model.dart';
import 'features/chess_game/presentation/chess_screen.dart';

void main() {
  runApp(const BureaucratChessApp());
}

class BureaucratChessApp extends StatelessWidget {
  const BureaucratChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChessViewModel(),
      child: MaterialApp(
        title: 'Bureaucrat Chess',
        theme: AppTheme.darkTheme,
        home: const ChessScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
