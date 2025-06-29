import '../json_craft_function.dart';

class JsonCraftIfFunction extends JsonCraftFunction {
  @override
  RegExp get regex => RegExp(r'\{\{#if:[^}]+\}\}');

  @override
  Map<String, dynamic> call(
    String key,
    dynamic value,
    GetValueFromPathFunction getValue,
    ReplaceRecursiveFunction replaceRecursive,
  ) {
    if (_evaluateConditional(key, getValue)) {
      final cleanKey = clearKey(key);
      return {
        cleanKey: replaceRecursive(value),
      };
    }
    return {};
  }

  bool _evaluateConditional(
    String key,
    dynamic Function(String value) getValue,
  ) {
    final regex = RegExp(r'\{\{#if:([^}]+)\}\}');
    final match = regex.firstMatch(key);

    if (match == null) return true;

    final condition = match.group(1)!;

    // Verifica se há negação (!)
    bool isNegated = false;
    String actualCondition = condition;

    if (condition.startsWith('!')) {
      isNegated = true;
      actualCondition = condition.substring(1); // Remove o !
    }

    try {
      final value = getValue(actualCondition);

      // Avalia o valor
      bool result;
      if (value == null) {
        result = false;
      } else if (value is bool) {
        result = value;
      } else if (value is String) {
        result = value.isNotEmpty;
      } else if (value is List) {
        result = value.isNotEmpty;
      } else if (value is Map) {
        result = value.isNotEmpty;
      } else if (value is num) {
        result = value != 0;
      } else {
        result = true;
      }

      // Aplica negação se necessário
      return isNegated ? !result : result;
    } catch (e) {
      // Se não conseguir acessar o valor, retorna false (ou true se negado)
      return isNegated ? true : false;
    }
  }
}
