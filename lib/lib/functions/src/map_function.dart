import '../json_craft_function.dart';

class JsonCraftMapFunction extends JsonCraftFunction {
  // Cache estático de regex para melhor performance
  static final _mapRegex = RegExp(r'\{\{#map:[^}]+\}\}');
  static final _pathRegex = RegExp(r'\{\{#map:([^}]+)\}\}');

  @override
  RegExp get regex => _mapRegex;

  @override
  Map<String, dynamic> call(
    String key,
    value,
    GetValueFromPathFunction getValue,
    ReplaceRecursiveFunction replaceRecursive,
    Map<String, String>? templates,
  ) {
    final cleanKey = clearKey(key);

    final match = _pathRegex.firstMatch(key);

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
