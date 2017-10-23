library jsonz;
import 'dart:collection';
import 'package:json_lexer/json_lexer.dart';

class Serialize {
  final String format;
  const Serialize._(this.format);
}

const Serialize json = const Serialize._('JSON');

class JsonParser {

}