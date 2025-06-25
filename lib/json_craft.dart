import 'dart:convert';

import 'json_craft_formatter.dart';

export 'json_craft_formatter.dart';

class JsonCraft {
  List<JsonCraftFormatter> _formatters = [];

  JsonCraft({
    List<JsonCraftFormatter>? formatters,
  }) {
    _formatters = [...DefaultJsonCraftFormatter.defaultFormatters];
    if (formatters != null) {
      _formatters.addAll(formatters);
    }
  }

  String process(String jsonString, Map<String, dynamic> data) {
    // Converte a string JSON para um objeto Dart (Map ou List)
    final decodedJson = json.decode(jsonString);

    // Recursivamente substitui os placeholders
    final processedJson = _replacePlaceholdersRecursive(decodedJson, data);

    // Converte o objeto Dart de volta para uma string JSON
    return json.encode(processedJson);
  }

  // Função recursiva para percorrer o objeto JSON e substituir os placeholders
  dynamic _replacePlaceholdersRecursive(dynamic data, Map<String, dynamic> context) {
    if (data is String) {
      // Verifica se a string é um placeholder completo (ex: "{{products}}")
      if (_isCompletePlaceholder(data)) {
        return _getPlaceholderValue(data, context);
      } else {
        // Se for uma string com placeholders misturados, tenta substituir os placeholders
        return _replaceStringPlaceholders(data, context);
      }
    } else if (data is Map) {
      // Se for um mapa, itera sobre as chaves e valores
      final newMap = <String, dynamic>{};
      data.forEach((key, value) {
        final processedKey = key as String;

        // Verifica se a chave tem uma condicional
        if (_hasConditional(processedKey)) {
          // Avalia a condicional
          if (_evaluateConditional(processedKey, context)) {
            // Remove a condicional da chave e adiciona ao mapa
            final cleanKey = _removeConditional(processedKey);
            newMap[cleanKey] = _replacePlaceholdersRecursive(value, context);
          }
          // Se a condicional for falsa, não adiciona a propriedade
        } else {
          // Chave normal, processa normalmente
          newMap[processedKey] = _replacePlaceholdersRecursive(value, context);
        }
      });
      return newMap;
    } else if (data is List) {
      // Se for uma lista, itera sobre os elementos
      return data.map((item) => _replacePlaceholdersRecursive(item, context)).toList();
    }
    // Se não for string, map ou list, retorna o próprio dado
    return data;
  }

  // Verifica se a chave tem uma condicional ({{#if:condition}})
  bool _hasConditional(String key) {
    return key.contains(RegExp(r'\{\{#if:[^}]+\}\}'));
  }

  // Avalia se a condicional é verdadeira
  bool _evaluateConditional(String key, Map<String, dynamic> context) {
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
      final value = _getValueFromPath(actualCondition, context);

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

  // Remove a condicional da chave
  String _removeConditional(String key) {
    final regex = RegExp(r'\{\{#if:[^}]+\}\}');
    return key.replaceAll(regex, '').trim();
  }

  // Obtém um valor seguindo um caminho (path) no contexto
  dynamic _getValueFromPath(String path, Map<String, dynamic> context) {
    final parts = path.split('.');
    dynamic currentValue = context;

    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (currentValue is Map<String, dynamic> && currentValue.containsKey(part)) {
        currentValue = currentValue[part];
      } else if (currentValue is List) {
        final index = int.tryParse(part);
        if (index != null && index >= 0 && index < currentValue.length) {
          currentValue = currentValue[index];
        } else {
          throw Exception('Path not found: $path');
        }
      } else {
        throw Exception('Path not found: $path');
      }
    }

    return currentValue ?? '';
  }

  // Verifica se a string é um placeholder completo
  bool _isCompletePlaceholder(String text) {
    final regex = RegExp(r'^\{\{([^}]+)\}\}$');
    return regex.hasMatch(text);
  }

  // Obtém o valor do placeholder preservando o tipo original
  dynamic _getPlaceholderValue(String text, Map<String, dynamic> context) {
    final regex = RegExp(r'^\{\{([^}]+)\}\}$');
    final match = regex.firstMatch(text);

    if (match == null) {
      throw Exception('Invalid placeholder: $text');
    }

    final placeholder = match.group(1)!;

    // Verifica se há formatadores (pipe |)
    final parts = placeholder.split('|');
    final fieldPath = parts[0].trim();
    final formatters = parts.skip(1).map((f) => f.trim()).toList();

    final fieldParts = fieldPath.split('.');
    dynamic currentValue = context;

    for (var i = 0; i < fieldParts.length; i++) {
      final part = fieldParts[i];
      if (currentValue is Map<String, dynamic> && currentValue.containsKey(part)) {
        currentValue = currentValue[part];
      } else if (currentValue is List) {
        // Tenta converter a parte para um índice numérico
        final index = int.tryParse(part);
        if (index != null && index >= 0 && index < currentValue.length) {
          currentValue = currentValue[index];
        } else {
          // Índice inválido ou fora dos limites
          throw Exception('Placeholder not found: $text');
        }
      } else {
        // Se a chave não for encontrada ou o tipo não for Map nem List
        throw Exception('Placeholder not found: $text');
      }
    }

    // Se há formatadores, aplica eles (resultado será sempre string)
    if (formatters.isNotEmpty) {
      String result = currentValue?.toString() ?? '';
      for (final formatter in formatters) {
        result = _applyFormatter(result, formatter, context);
      }
      return result;
    }

    // Se não há formatadores, retorna o valor original preservando o tipo
    return currentValue;
  }

// Função para substituir placeholders em uma única string
  String _replaceStringPlaceholders(String text, Map<String, dynamic> context) {
    // Expressão regular para encontrar "{{alguma.chave | formatador}}"
    // Agora também captura formatadores opcionais
    final regex = RegExp(r'\{\{([^}]+)\}\}');

    return text.replaceAllMapped(regex, (match) {
      final placeholder = match.group(1); // Ex: "data.name | pascalCase"
      if (placeholder == null) {
        throw Exception('Placeholder not found: ${match.group(0)!}');
      }

      // Verifica se há formatadores (pipe |)
      final parts = placeholder.split('|');
      final fieldPath = parts[0].trim(); // Ex: "data.name"
      final formatters =
          parts.skip(1).map((f) => f.trim()).toList(); // Ex: ["pascalCase", "upperCase"]

      // Obter o valor do campo
      final currentValue = _getValueFromPath(fieldPath, context)?.toString();

      if (currentValue == null) {
        throw Exception('Placeholder not found: ${match.group(0)!}');
      }

      String result = currentValue;

      // Aplicar formatadores em sequência
      for (final formatter in formatters) {
        result = _applyFormatter(result, formatter, context);
      }

      return result;
    });
  }

  // Aplica um formatador específico ao valor
  String _applyFormatter(String value, String formatter, Map<String, dynamic> context) {
    // Verifica se o formatador tem parâmetros (ex: "truncate(50)")

    String? parameter;
    final formatterParts = formatter.split('(');
    final formatterName = formatterParts[0];
    if (formatter.contains('(') && formatter.contains(')')) {
      parameter = formatterParts[1].replaceAll(')', '');
    }

    // Procura o formatador na lista de formatadores disponíveis
    final targetFormatter = _formatters.firstWhere(
      (f) => f.name == formatterName,
      orElse: () => JsonCraftFormatter(
        name: 'identity',
        formatter: (value, param, getValue) => value, // Retorna valor original se não encontrar
      ),
    );

    // Aplica o formatador encontrado
    return targetFormatter.format(
      value,
      parameter,
      (value) => _getValueFromPath(value, context) ?? value,
    );
  }
}
