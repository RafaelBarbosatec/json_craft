import '../json_craft_function.dart';

class JsonCraftMapFunction extends JsonCraftFunction {
  @override
  RegExp get regex => RegExp(r'\{\{#map:[^}]+\}\}');

  @override
  Map<String, dynamic> call(
    String key,
    value,
    dynamic Function(String value) getValue,
    ReplaceRecursiveFunction replaceRecursive,
  ) {
    final cleanKey = clearKey(key);

    final regex = RegExp(r'\{\{#map:([^}]+)\}\}');
    final match = regex.firstMatch(key);

    if (match == null) {
      throw Exception('Invalid map syntax: $key');
    }

    final path = match.group(1)!;
    final items = getValue(path);

    if (items is! List) {
      throw Exception('Path does not point to a list: $path');
    }

    final result = items.map((item) {
      return replaceRecursive(
        value,
        extraContext: {'item': item},
      );
    }).toList();

    return {cleanKey: result};
  }
}
