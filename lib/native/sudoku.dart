import 'package:sudoku_dart/sudoku_dart.dart' as sd;

class SudokuHelper {
  static final SudokuHelper _instance = SudokuHelper._internal();

  SudokuHelper._internal();

  static get instance {
    return _instance;
  }

  factory SudokuHelper() {
    return _instance;
  }

  List<int> solve(List<int> puzzle) {
    final solvedSudoku = sd.Sudoku(puzzle).solution;
    if (solvedSudoku == null) {
      throw Exception("Sudoku cannot be solved.");
    }
    return solvedSudoku;
  }

  List<int> generate(int level) {
    sd.Level difficulty;
    switch (level) {
      case 0:
        difficulty = sd.Level.easy;
        break;
      case 1:
        difficulty = sd.Level.medium;
        break;
      case 2:
        difficulty = sd.Level.hard;
        break;
      case 3:
      case 4:
      case 5:
        difficulty = sd.Level.expert;
        break;
      default:
        difficulty = sd.Level.medium; // Default to medium if level is unknown or unsupported
    }
    final generatedSudoku = sd.Sudoku.generate(difficulty);
    return generatedSudoku.puzzle;
  }
}
