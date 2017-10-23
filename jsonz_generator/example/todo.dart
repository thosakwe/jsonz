library jsonz_generator.example.todo;

import 'dart:collection';
import 'package:json_lexer/json_lexer.dart';
import 'package:jsonz/jsonz.dart';
part 'todo.g.dart';

void main() {
  var todo = TodoSerializer.parseString('{"text":"Clean your room!","completed":false}');
  print('Text: ${todo.text}');
  print('Completed: ${todo.completed}');
}

@json
class Todo {
  String text;
  bool completed;
}