library jsonz_generator.example.todo;

import 'dart:collection';
import 'dart:convert';
import 'package:json_lexer/json_lexer.dart';
import 'package:jsonz/jsonz.dart';
import 'package:millisecond/millisecond.dart' as ms;
part 'todo.g.dart';

typedef TodoList _JsonCodec(String s);

const int iterations = 100000;
final String jsonString = JSON.encode({
  'version': 1.0,
  'author': 'Tobe O',
  'todo': {
    'text': 'Clean your room!',
    'completed': false,
  },
});

void main() {
  Map<String, _JsonCodec> codecs = {
    'jsonz': TodoListSerializer.parseString,
    'JSON.decode': (String s) {
      var map = JSON.decode(s), todoMap = map['todo'];
      return new TodoList()
        ..version = map['version']
        ..author = map['author']
        ..todo = (new Todo()
          ..text = todoMap['text']
          ..completed = todoMap['completed']);
    }
  };

  Map<String, int> averages = {};

  for (var key in codecs.keys) {
    var codec = codecs[key];
    int sum = 0;

    for (int i = 0; i < iterations; i++) {
      var sw = new Stopwatch()..start();
      var todoList = codec(jsonString);
      sw.stop();
      sum += sw.elapsedMicroseconds;

      if (i == 0) {
        print('=== Dump from $key ===');
        print('Version: ${todoList.version}');
        print('Author: ${todoList.author}');
        print('Text: ${todoList.todo.text}');
        print('Completed: ${todoList.todo.completed}');
      }
    }

    averages[key] = (sum / iterations).round();
  }

  print('=== RESULTS ===');
  print('Benchmarked: ${codecs.keys}');
  print('Ran $iterations iteration(s) for each');
  print('Average JSON -> todo list deserialization time:');

  for (var key in averages.keys) {
    var average = averages[key];
    print('* $key ≈ ' + average.toString() + 'us');
  }
}

@json
class Todo {
  String text;
  bool completed;
}

@json
class TodoList {
  double version;
  String author;
  Todo todo;
}
