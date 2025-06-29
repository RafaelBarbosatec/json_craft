import 'src/if_function.dart';
import 'src/map_function.dart';

typedef ReplaceRecursiveFunction = dynamic Function(
  dynamic data, {
  Map<String, dynamic>? extraContext,
});

abstract class JsonCraftFunction {
  RegExp get regex;

  bool has(String key) {
    return key.contains(regex);
  }

  String clearKey(String key) {
    return key.replaceAll(regex, '').trim();
  }

  Map<String, dynamic> call(
    String key,
    dynamic value,
    dynamic Function(String value) getValue,
    ReplaceRecursiveFunction replaceRecursive,
  );
}

abstract class JsonCraftFunctionDetafult {
  static List<JsonCraftFunction> defaultFunctions = [
    JsonCraftIfFunction(),
    JsonCraftMapFunction(),
  ];
}

class JsonCraftEmptyFunction extends JsonCraftFunction {
  @override
  RegExp get regex => RegExp('');

  @override
  Map<String, dynamic> call(
    String key,
    dynamic value,
    dynamic Function(String value) getValue,
    ReplaceRecursiveFunction replaceRecursive,
  ) {
    return {key: replaceRecursive(value)};
  }
}
