library jsonz_generator;

import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:code_builder/dart/core.dart';
import 'package:code_builder/code_builder.dart';
import 'package:code_builder/src/builders/statement/if.dart';
import 'package:jsonz/jsonz.dart';
import 'package:recase/recase.dart';
import 'package:source_gen/source_gen.dart';

class JsonzGenerator extends GeneratorForAnnotation<Serialize> {
  /// If `true` (default: `false`), then a cache will be used to improve performance.
  final bool cache;

  /// If `true` (default: `false`), then unrecognized keys will be ignored.
  final bool strict;

  JsonzGenerator({this.cache, this.strict: false});

  static ExpressionBuilder tokenType(String type) {
    return new TypeBuilder('TokenType').property(type);
  }

  static ExpressionBuilder valueType(String type) {
    return new TypeBuilder('ValueType').property(type);
  }

  static ExpressionBuilder expected(String type, ExpressionBuilder token,
      {bool value: false}) {
    return literal('Expected $type, found ') +
        token.property(value ? 'valueType' : 'type').invoke('toString', []) +
        literal(' (') +
        token.property('value') +
        literal(')  instead.');
  }

  @override
  Future<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    if (element is! ClassElement)
      throw 'Only classes are supported by package:jsonz.';
    var clazz =
        await generateJsonSerializerClass((element as ClassElement).type);
    return prettyToSource(clazz.buildAst());
  }

  ClassBuilder generateJsonSerializerClass(InterfaceType type) {
    var rc = new ReCase(type.name);
    var clazz = new ClassBuilder('${rc.pascalCase}Serializer');
    clazz.addMethod(generateParseStringMethod(type), asStatic: true);
    clazz.addMethod(generateParseTokensMethod(type), asStatic: true);

    if (cache == true) {
      // Add _cache
      clazz.addField(
        varField(
          '_cache',
          type: new TypeBuilder('Map', genericTypes: [
            lib$core.String,
            new TypeBuilder(type.name),
          ]),
          value: map({}),
        ),
        asStatic: true,
      );
    }

    return clazz;
  }

  MethodBuilder generateParseStringMethod(InterfaceType type) {
    var m = new MethodBuilder('parseString',
        returnType: new TypeBuilder(type.name));
    m.addPositional(parameter('string', [lib$core.String]));

    var meth = new MethodBuilder.closure();

    // var tokens = new JsonLexer('string').tokens;
    meth.addStatement(varField(
      'tokens',
      value: new TypeBuilder('JsonLexer').newInstance([
        reference('string'),
      ]).property('tokens'),
    ));

    // return parseTokens(tokens);
    meth.addStatement(
      reference('parseTokens').call([reference('tokens')]).asReturn(),
    );

    if (cache != true)
      return m;

    m.addStatement(reference('_cache').invoke('putIfAbsent', [
      reference('string'),
      meth,
    ]).asReturn());

    return m;
  }

  MethodBuilder generateParseTokensMethod(InterfaceType type) {
    var setters = type.accessors.where((a) => a.isSetter);

    if (setters.isEmpty)
      throw 'This class has no setters, and thus no JSON deserializer can be generated.';

    var meth = new MethodBuilder('parseTokens',
        returnType: new TypeBuilder(type.name));
    meth.addPositional(parameter('tokens', [
      new TypeBuilder('Queue', genericTypes: [
        new TypeBuilder('Token'),
      ]),
    ]));

    // Expect the first token to be '{'.
    var firstToken = reference('firstToken');
    var tokens = reference('tokens');
    meth.addStatement(varField(
      'firstToken',
      value: tokens.invoke('removeFirst', []),
    ));

    // Otherwise, return null.
    meth.addStatement(ifThen(
        firstToken.property('type').notEquals(tokenType('BEGIN_OBJECT')), [
      literal(null).asReturn(),
    ]));

    // Create a provisional instance of the class.
    var model = reference('model');
    meth.addStatement(varField(
      'model',
      value: new TypeBuilder(type.name).newInstance([]),
    ));

    if (strict == true) {
      // Each field MUST be parsed. Add a simple flag.

      for (var field in setters) {
        var rc = new ReCase(field.displayName);
        // var parsedFoo = false;
        meth.addStatement(varField(
          'parsed${rc.pascalCase}',
          value: literal(false),
        ));
      }
    }

    // while (tokens.isNotEmpty) { ... }
    var wh = new WhileStatementBuilder(false, tokens.property('isNotEmpty'));
    meth.addStatement(wh);

    // var parsed = false;
    var parsed = reference('parsed');
    wh.addStatement(varField('parsed', value: literal(false)));

    // var token = tokens.removeFirst();
    var token = reference('token');
    wh.addStatement(varField(
      'token',
      value: tokens.invoke('removeFirst', []),
    ));

    // Each property should attempt to parse itself, IF we found a string (potential key).
    var block = <ValidIfStatementMember>[];
    var elseIfs = <ValidIfStatementMember>[];

    for (var field in setters.skip(1)) {
      elseIfs.add(elseIf(
        parseProperty(field, model, token, tokens, parsed),
      ));
    }

    if (strict == true) {
      // In strict mode, throw on an unrecognized key.
      elseIfs.add(elseThen([
        lib$core.FormatException.newInstance([
          literal('Unrecognized key ') + token.property('value') + literal('.'),
        ]).asThrow(),
      ]));
    }

    // Create an `if` with the first setter.
    IfStatementBuilder propertyParsers = parseProperty(
      setters.first,
      model,
      token,
      tokens,
      parsed,
      elseIfs,
    );

    block.add(propertyParsers);

    // If we parsed something, expect either a "," or "}".
    block.add(ifThen(parsed, [
      /* pkg:json_lexer always emits an EOF last, so remove this for performance
      // REF#1
      // if (tokens.isEmpty) { ...}
      ifThen(tokens.property('isEmpty'), [
        lib$core.FormatException.newInstance([
          literal('Premature end-of-file; expected "," or "}".'),
        ]).asThrow(),
      ]),
      */

      // token = tokens.removeFirst();
      tokens.invoke('removeFirst', []).asAssign(token),

      // if (token.type == END_OBJECT) break;
      ifThen(token.property('type').equals(tokenType('END_OBJECT')), [
        breakStatement,

        // else if (token.type != VALUE_SEPARATOR) throw ...;
        elseIf(ifThen(
            token.property('type').notEquals(tokenType('VALUE_SEPARATOR')), [
          lib$core.FormatException.newInstance([
            expected('","', token),
          ]).asThrow(),
        ])),
      ]),
    ]));

    // If this is not a string, throw an error.
    block.add(elseThen([
      lib$core.FormatException.newInstance([
        expected('a string', token, value: true),
      ]).asThrow(),
    ]));

    // IF we found a string
    wh.addStatement(ifThen(
      token.property('valueType').equals(valueType('STRING')),
      block,
    ));

    if (strict == true) {
      for (var field in setters) {
        // if (!parsedFoo) { ...}
        var rc = new ReCase(field.displayName);
        meth.addStatement(ifThen(reference('parsed${rc.pascalCase}').negate(), [
          lib$core.FormatException.newInstance([
            literal('Missing required key "${rc.snakeCase}".'),
          ]).asThrow(),
        ]));
      }
    }

    // return model;
    meth.addStatement(model.asReturn());

    return meth;
  }

  IfStatementBuilder parseProperty(
      PropertyAccessorElement field,
      ExpressionBuilder model,
      ExpressionBuilder token,
      ExpressionBuilder tokens,
      ExpressionBuilder parsed,
      [Iterable<ValidIfStatementMember> elseIfs]) {
    var type = field.parameters.first.type;
    var rc = new ReCase(field.displayName);

    // if (token.value == "foo") { ... }
    var condition = token.property('value').equals(literal(rc.snakeCase));
    var predicate = <ValidIfStatementMember>[];

    // Naturally, expect the next token to be a ":".
    //
    // Throw an error otherwise.
    // if (tokens.first.type != TokenType.NAME_SEPARATOR) { throw ... }
    predicate.add(ifThen(
      tokens
          .property('first')
          .property('type')
          .notEquals(tokenType('NAME_SEPARATOR')),
      [
        lib$core.FormatException.newInstance([
          expected('":"', tokens.property('first')),
        ]).asThrow(),
      ],
    ));

    // If we found a ":", then move forward!
    predicate.add(tokens.invoke('removeFirst', []));

    /* Removed as optimization: search this for "REF#1" to find the explanation.
    // Check if this is the last token.
    predicate.add(ifThen(tokens.property('isEmpty'), [
      lib$core.FormatException.newInstance([
        literal('Premature end-of-file; expected a value after ":".'),
      ]).asThrow(),
    ]));
    */

    ExpressionBuilder parseCondition;
    List<ValidIfStatementMember> ifParsed;
    String expectedType;

    bool isPrimitive = true;

    if (const TypeChecker.fromRuntime(bool).isExactlyType(type)) {
      expectedType = 'boolean';
      parseCondition = token.property('valueType').equals(valueType('BOOL'));
      ifParsed = [
        // model.foo = token.value == 'true'
        token
            .property('value')
            .equals(literal('true'))
            .asAssign(model.property(field.displayName)),
      ];
    }

    // Strings
    else if (const TypeChecker.fromRuntime(String).isExactlyType(type)) {
      expectedType = 'string';
      parseCondition = token.property('valueType').equals(valueType('STRING'));
      ifParsed = [
        // model.foo = token.value
        token.property('value').asAssign(model.property(field.displayName)),
      ];
    }

    // Integers
    else if (const TypeChecker.fromRuntime(int).isExactlyType(type)) {
      expectedType = 'integer';
      parseCondition = token.property('valueType').equals(valueType('NUMBER'));
      ifParsed = [
        // var n = num.parse(token.value);
        varField(
          'n',
          value: lib$core.num.invoke('parse', [
            token.property('value'),
          ]),
        ),

        // if (n is! int) { ... }
        ifThen(reference('n').isInstanceOf(lib$core.int).negate(), [
          lib$core.FormatException.newInstance([
            literal('"${rc.snakeCase}" must be an integer.'),
          ]).asThrow(),
        ]),

        // model.foo = n
        token.property('value').asAssign(model.property(field.displayName)),
      ];
      // Ensure that the parsed number is an integer.
    }

    // Doubles or other numbers
    else if (const TypeChecker.fromRuntime(num).isAssignableFromType(type)) {
      expectedType = const TypeChecker.fromRuntime(double).isExactlyType(type)
          ? 'double'
          : 'number';
      parseCondition = token.property('valueType').equals(valueType('NUMBER'));
      var numType =
          expectedType == 'double' ? new TypeBuilder('double') : lib$core.num;

      ifParsed = [
        // model.foo = num.parse(token.value)
        numType.invoke('parse', [
          token.property('value'),
        ]).asAssign(model.property(field.displayName)),
      ];
    }

    // Dates
    else if (const TypeChecker.fromRuntime(DateTime).isExactlyType(type)) {
      expectedType = 'a string';
      parseCondition = token.property('valueType').equals(valueType('STRING'));
      ifParsed = [
        // model.foo = DateTime.parse(token.value)
        lib$core.DateTime.invoke('parse', [
          token.property('value'),
        ]).asAssign(model.property(field.displayName)),
      ];
    } else {
      // TODO: Lists
      // TODO: Map<String, dynamic> (or even validate the second type?)
      isPrimitive = false;

      // If the field's type is also serializable, invoke its serializer...
      var jsonAnnotation = const TypeChecker.fromRuntime(Serialize)
          .firstAnnotationOf(type.element);

      if (jsonAnnotation != null) {
        // Check if this is @json...
        var serializerName =
            new ConstantReader(jsonAnnotation).peek('format')?.stringValue;

        if (serializerName == json.format) {
          expectedType = type.name;
          var classRc = new ReCase(type.name);

          // var bar = BarSerializer.parseTokens(tokens);
          predicate.add(varField(
            field.displayName,
            value: new TypeBuilder('${classRc.pascalCase}Serializer')
                .invoke('parseTokens', [tokens]),
          ));

          // bar != null
          parseCondition =
              reference(field.displayName).notEquals(literal(null));

          ifParsed = [
            // model.bar = bar;
            reference(field.displayName)
                .asAssign(model.property(field.displayName)),
          ];
        }
      } else
        throw 'Unsupported field type: ${type.displayName}';
    }

    if (isPrimitive) {
      // Move onto the next token
      predicate.add(tokens.invoke('removeFirst', []).asAssign(token));
    }

    var ifParsedStmt = ifThen(parseCondition, ifParsed);
    predicate.add(ifParsedStmt);

    if (strict == true) {
      // parsedFoo = true;
      ifParsedStmt.addStatement(
          literal(true).asAssign(reference('parsed${rc.pascalCase}')));
    }

    ifParsedStmt.addStatement(literal(true).asAssign(parsed));

    // Throw correct syntax error
    ifParsedStmt.setElse(
      lib$core.FormatException.newInstance([
        expected(expectedType, token, value: true),
      ]).asThrow(),
    );

    predicate.addAll(elseIfs ?? []);
    return ifThen(condition, predicate);
  }
}
