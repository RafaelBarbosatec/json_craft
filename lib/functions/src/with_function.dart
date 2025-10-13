import '../json_craft_function.dart';

class JsonCraftWithFunction extends JsonCraftFunction {
  @override
  RegExp get regex => RegExp(r'\{\{#with:[^}]+\}\}');

  @override
  Map<String, dynamic> call(
    String key,
    value,
    GetValueFromPathFunction getValue,
    ReplaceRecursiveFunction replaceRecursive,
    Map<String, String>? templates,
  ) {
    final cleanKey = clearKey(key);

    final regex = RegExp(r'\{\{#with:([^}]+)\}\}');
    final match = regex.firstMatch(key);

    if (match == null) {
      throw Exception('Invalid with syntax: $key');
    }

    final path = match.group(1)!;
    final contextValue = getValue(path);

    if (contextValue == null) {
      throw Exception('Path not found for with: $path');
    }

    // If contextValue is not a Map, we can't change context
    if (contextValue is! Map<String, dynamic>) {
      throw Exception('With requires a Map context, got: ${contextValue.runtimeType}');
    }

    // Process the value with the new context (merging with existing context)
    final result = replaceRecursive(
      value,
      extraContext: contextValue,
    );

    return {cleanKey: result};
  }
}
