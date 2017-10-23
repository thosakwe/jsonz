// GENERATED CODE - DO NOT MODIFY BY HAND

part of jsonz_generator.example.todo;

// **************************************************************************
// Generator: JsonzGenerator
// **************************************************************************

class TodoSerializer {
  static Map<String, Todo> _cache = {};

  static Todo parseString(String string) {
    return _cache.putIfAbsent(string, () {
      var tokens = new JsonLexer(string).tokens;
      return parseTokens(tokens);
    });
  }

  static Todo parseTokens(Queue<Token> tokens) {
    var firstToken = tokens.removeFirst();
    if (firstToken.type != TokenType.BEGIN_OBJECT) {
      return null;
    }
    var model = new Todo();
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
            parsed = true;
          } else
            throw new FormatException('Expected boolean, found ' +
                token.valueType.toString() +
                ' (' +
                token.value +
                ')  instead.');
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
    return model;
  }
}

class TodoListSerializer {
  static Map<String, TodoList> _cache = {};

  static TodoList parseString(String string) {
    return _cache.putIfAbsent(string, () {
      var tokens = new JsonLexer(string).tokens;
      return parseTokens(tokens);
    });
  }

  static TodoList parseTokens(Queue<Token> tokens) {
    var firstToken = tokens.removeFirst();
    if (firstToken.type != TokenType.BEGIN_OBJECT) {
      return null;
    }
    var model = new TodoList();
    while (tokens.isNotEmpty) {
      var parsed = false;
      var token = tokens.removeFirst();
      if (token.valueType == ValueType.STRING) {
        if (token.value == 'version') {
          if (tokens.first.type != TokenType.NAME_SEPARATOR) {
            throw new FormatException('Expected ":", found ' +
                tokens.first.type.toString() +
                ' (' +
                tokens.first.value +
                ')  instead.');
          }
          tokens.removeFirst();
          token = tokens.removeFirst();
          if (token.valueType == ValueType.NUMBER) {
            model.version = double.parse(token.value);
            parsed = true;
          } else
            throw new FormatException('Expected double, found ' +
                token.valueType.toString() +
                ' (' +
                token.value +
                ')  instead.');
        } else if (token.value == 'author') {
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
            model.author = token.value;
            parsed = true;
          } else
            throw new FormatException('Expected string, found ' +
                token.valueType.toString() +
                ' (' +
                token.value +
                ')  instead.');
        } else if (token.value == 'todo') {
          if (tokens.first.type != TokenType.NAME_SEPARATOR) {
            throw new FormatException('Expected ":", found ' +
                tokens.first.type.toString() +
                ' (' +
                tokens.first.value +
                ')  instead.');
          }
          tokens.removeFirst();
          var todo = TodoSerializer.parseTokens(tokens);
          if (todo != null) {
            model.todo = todo;
            parsed = true;
          } else
            throw new FormatException('Expected Todo, found ' +
                token.valueType.toString() +
                ' (' +
                token.value +
                ')  instead.');
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
    return model;
  }
}
