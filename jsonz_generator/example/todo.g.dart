// GENERATED CODE - DO NOT MODIFY BY HAND

part of jsonz_generator.example.todo;

// **************************************************************************
// Generator: JsonzGenerator
// **************************************************************************

class TodoSerializer {
  static Todo parseString(String string) {
    var tokens = new JsonLexer(string).tokens;
    return parseTokens(tokens);
  }

  static Todo parseTokens(Queue<Token> tokens) {
    var firstToken = tokens.removeFirst();
    if (firstToken.type != TokenType.BEGIN_OBJECT) {
      return null;
    }
    var model = new Todo();
    var parsedText = false;
    var parsedCompleted = false;
    while (tokens.isNotEmpty) {
      var parsed = false;
      var token = tokens.removeFirst();
      if (token.valueType == ValueType.STRING) {
        if (token.value == 'text') {
          if (tokens.first.type != TokenType.NAME_SEPARATOR) {
            throw new FormatException('Expected ":", found ' +
                tokens.first.type.toString() +
                ' (' +
                tokens.first.value +
                ')  instead.');
          }
          tokens.removeFirst();
          token = tokens.removeFirst();
          if (token.valueType == ValueType.STRING) {
            model.text = token.value;
            parsedText = true;
            parsed = true;
          } else
            throw new FormatException('Expected string, found ' +
                token.valueType.toString() +
                ' (' +
                token.value +
                ')  instead.');
        } else if (token.value == 'completed') {
          if (tokens.first.type != TokenType.NAME_SEPARATOR) {
            throw new FormatException('Expected ":", found ' +
                tokens.first.type.toString() +
                ' (' +
                tokens.first.value +
                ')  instead.');
          }
          tokens.removeFirst();
          token = tokens.removeFirst();
          if (token.valueType == ValueType.BOOL) {
            model.completed = token.value == 'true';
            parsedCompleted = true;
            parsed = true;
          } else
            throw new FormatException('Expected boolean, found ' +
                token.valueType.toString() +
                ' (' +
                token.value +
                ')  instead.');
        } else {
          throw new FormatException('Unrecognized key ' + token.value + '.');
        }
        if (parsed) {
          token = tokens.removeFirst();
          if (token.type == TokenType.END_OBJECT) {
            break;
          } else if (token.type != TokenType.VALUE_SEPARATOR) {
            throw new FormatException('Expected ",", found ' +
                token.type.toString() +
                ' (' +
                token.value +
                ')  instead.');
          }
        }
      } else {
        throw new FormatException('Expected a string, found ' +
            token.valueType.toString() +
            ' (' +
            token.value +
            ')  instead.');
      }
    }
    if (!(parsedText)) {
      throw new FormatException('Missing required key "text".');
    }
    if (!(parsedCompleted)) {
      throw new FormatException('Missing required key "completed".');
    }
    return model;
  }
}
