# jsonz
**EXPERIMENTAL**: High-performance JSON serialization via `package:source_gen`.

Currently only supports deserialization.

Check out `jsonz_generator/example/todo.dart` to run a benchmark against using `JSON.decode`,
for 10,000 iterations.

The `JsonzGenerator` has an optional `strict` mode that validates the input JSON string.
There is likely not much difference in performance when it is enabled, but if you are going
for the fastest possible, refrain from turning it on. By default, it is `false`.
