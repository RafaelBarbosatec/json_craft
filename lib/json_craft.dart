import 'dart:convert';

import 'package:json_craft/functions/json_craft_function.dart';

import 'json_craft_formatter.dart';

export 'json_craft_formatter.dart';

class JsonCraft {
  List<JsonCraftFormatter> _formatters = [];
  List<JsonCraftFunction> _functions = [];

  JsonCraft({
    List<JsonCraftFormatter>? formatters,
    List<JsonCraftFunction>? functions,
  }) {
    _formatters = [...DefaultJsonCraftFormatter.defaultFormatters];
    _functions = [...JsonCraftFunctionDetafult.defaultFunctions];
    if (formatters != null) {
      _formatters.addAll(formatters);
    }
    if (functions != null) {
      _functions.addAll(functions);
    }
  }

  String process(String jsonString, Map<String, dynamic> data,
      {Map<String, String>? templates}) {
    // Converte a string JSON para um objeto Dart (Map ou List)
    final decodedJson = json.decode(jsonString);

    // Recursivamente substitui os placeholders
    final processedJson = _replacePlaceholdersRecursive(
      decodedJson,
      data,
      templates,
    );

    // Converte o objeto Dart de volta para uma string JSON
    return json.encode(processedJson);
  }

  // Função recursiva para percorrer o objeto JSON e substituir os placeholders
  dynamic _replacePlaceholdersRecursive(
    dynamic data,
    Map<String, dynamic> context,
    Map<String, String>? templates,
  ) {
    if (data is String) {
      if (_isCompletePlaceholder(data)) {
        if (_isIncludePlaceholder(data)) {
          return _getIncludedTemplate(data, templates, context);
        }
        return _getPlaceholderValue(data, context);
      } else {
        return _replaceStringPlaceholders(data, context);
      }
    } else if (data is Map) {
      final newMap = <String, dynamic>{};

      data.forEach((key, value) {
        final processedKey = key as String;

        final function = _functions.firstWhere(
          (element) => element.has(processedKey),
          orElse: () => JsonCraftEmptyFunction(),
        );
        newMap.addAll(
          function.call(
            key,
            value,
            (value) => _getValueFromPath(value, context),
            (data, {extraContext}) => _replacePlaceholdersRecursive(
              data,
              {
                ...context,
                ...extraContext ?? {},
              },
              templates,
            ),
          ),
        );
      });
      return newMap;
    } else if (data is List) {
      // Se for uma lista, itera sobre os elementos
      return data
          .map(
            (item) => _replacePlaceholdersRecursive(
              item,
              context,
              templates,
            ),
          )
          .toList();
    }
    // Se não for string, map ou list, retorna o próprio dado
    return data;
  }

  // Obtém um valor seguindo um caminho (path) no contexto
  dynamic _getValueFromPath(String path, Map<String, dynamic> context) {
    final parts = path.split('.');
    dynamic currentValue = context;

    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (currentValue is Map<String, dynamic> &&
          currentValue.containsKey(part)) {
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

    dynamic currentValue = _getValueFromPath(fieldPath, context);

    if (currentValue == null) {
      throw Exception('Placeholder not found: $text');
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
      final formatters = parts
          .skip(1)
          .map((f) => f.trim())
          .toList(); // Ex: ["pascalCase", "upperCase"]

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
  String _applyFormatter(
      String value, String formatter, Map<String, dynamic> context) {
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
        formatter: (value, param, getValue) =>
            value, // Retorna valor original se não encontrar
      ),
    );

    // Aplica o formatador encontrado
    return targetFormatter.format(
      value,
      parameter,
      (value) => _getValueFromPath(value, context) ?? value,
    );
  }

  // Verifica se a chave tem um include ({{#include:id}})
  bool _isIncludePlaceholder(String text) {
    final regex = RegExp(r'^\{\{#include:([^}]+)\}\}$');
    return regex.hasMatch(text);
  }

  // Obtém e processa um template incluído
  dynamic _getIncludedTemplate(String text, Map<String, String>? templates,
      Map<String, dynamic> context) {
    if (templates == null) {
      throw Exception('Templates not provided for inclusion: $text');
    }

    final regex = RegExp(r'^\{\{#include:([^}]+)\}\}$');
    final match = regex.firstMatch(text);

    if (match == null) {
      throw Exception('Invalid include syntax: $text');
    }

    final templateId = match.group(1)!;

    if (!templates.containsKey(templateId)) {
      throw Exception('Template not found: $templateId');
    }

    final templateString = templates[templateId]!;
    final decodedTemplate = json.decode(templateString);

    return _replacePlaceholdersRecursive(decodedTemplate, context, templates);
  }
}
