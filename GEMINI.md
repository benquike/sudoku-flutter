# Gemini Project Overview: Sudoku-Flutter

This document provides a comprehensive overview of the Sudoku-Flutter project, intended as a guide for AI agents and developers interacting with the codebase.

## Project Overview

This is a full-featured Sudoku game for mobile devices, built with Flutter. It has a clean, modern UI with animations and sound effects to enhance the user experience. The app supports localization for English, Chinese, and Japanese.

### Core Features:

*   **Classic Sudoku Gameplay**:
    *   Play Sudoku puzzles at various difficulty levels (Easy, Medium, Hard, etc.).
    *   The game board highlights the selected cell and its related row, column, and 3x3 box for better usability.
    *   It supports a "notes" feature, allowing players to pencil in candidate numbers in each cell.
    *   Players have a limited number of lives and hints.
*   **AI-Powered Sudoku Scanner**:
    *   The app can use the phone's camera to automatically recognize and digitize a Sudoku puzzle from a picture.
    *   It uses a two-stage machine learning pipeline:
        1.  A YOLOv8 model detects the Sudoku puzzle in the camera view.
        2.  Another YOLOv8 model recognizes the digits within the detected puzzle.
    *   The user is then presented with the recognized puzzle to confirm and start playing.
*   **Game State Management**:
    *   The app saves the game state, so players can pause and resume their games at any time.
    *   This includes the current puzzle, the player's progress, the timer, and the difficulty level.
*   **Performance**:
    *   It uses native code (`libsudoku.so` and `libsudoku.a`) for performance-critical operations like generating new Sudoku puzzles.
    *   It uses background isolates for puzzle generation to keep the UI responsive.
    *   It pre-loads the machine learning models into memory when the app starts to reduce the latency of the AI scanner.

### Technology Stack:

*   **Framework**: Flutter
*   **Language**: Dart
*   **State Management**: `scoped_model`
*   **Local Storage**: `hive`
*   **Machine Learning**: `tflite_flutter` for running TensorFlow Lite models (YOLOv8).
*   **Image Processing**: `opencv_dart` and `image` packages.
*   **Native Code**: C/C++ for Sudoku generation, accessed via `ffi`.
*   **Backend**: Firebase for analytics and crash reporting.

## Building and Running

### Prerequisites

*   Flutter SDK
*   Android SDK / Xcode for mobile development

### Commands

*   **Install dependencies**:
    ```bash
    flutter pub get
    ```
*   **Run the app**:
    ```bash
    flutter run
    ```
*   **Run tests**:
    ```bash
    flutter test
    ```
*   **Code Generation**: The project uses `build_runner` for code generation (e.g., for `hive`). If you change the state classes, you may need to run:
    ```bash
    flutter pub run build_runner build
    ```

## Development Conventions

*   **State Management**: The project uses the `scoped_model` package for state management. The main application state is encapsulated in the `SudokuState` class.
*   **Native Code**: Native code for Sudoku generation is written in C/C++ and located in the `src/` directory. Dart bindings are generated using `ffigen`.
*   **Machine Learning**: The app uses TensorFlow Lite models for AI features. The models are located in `assets/tf_model/`. The `Detector` classes in `lib/ml/` wrap the TFLite interpreter.
*   **UI**: The UI is built with a mix of Material and Cupertino widgets, with a focus on creating a clean and responsive user experience. The `flutter_animate` package is used for animations.
*   **Localization**: The app is localized using `flutter_localizations` and `.arb` files in `lib/l10n/`.
*   **File Structure**:
    *   `lib/page/`: Contains the different screens of the application.
    *   `lib/state/`: Contains the application's state management logic.
    -   `lib/ml/`: Contains the machine learning logic.
    -   `lib/native/`: Contains the FFI bindings to the native code.
    -   `assets/`: Contains all static assets like images, fonts, and ML models.

This `GEMINI.md` should provide a solid foundation for any future work on this project.
