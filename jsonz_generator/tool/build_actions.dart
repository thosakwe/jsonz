import 'package:build_runner/build_runner.dart';
import 'package:jsonz_generator/jsonz_generator.dart';
import 'package:source_gen/source_gen.dart';

final List<BuildAction> buildActions = [
  new BuildAction(
    new PartBuilder([
      new JsonzGenerator(),
    ]),
    'jsonz_generator',
    inputs: const [
      'example/*.dart',
    ],
  )
];
