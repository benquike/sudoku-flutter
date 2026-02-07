abstract class Input extends Object {}

abstract class Output extends Object {}

abstract class Predictor<I extends Input, O extends Object> {
  Future<O> predict(I input);
}
