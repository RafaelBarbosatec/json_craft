import 'dart:convert';

import 'package:json_craft/functions/json_craft_function.dart';

import 'json_craft_formatter.dart';

export 'json_craft_formatter.dart';

// Classe auxiliar para parsing otimizado de placeholders
class _PlaceholderParts {
  final String fieldPath;
  final List<String> formatters;

  const _PlaceholderParts(this.fieldPath, this.formatters);
}

class JsonCraft {
  // Cache estático de regex compiladas para melhor performance
  static final _completePlaceholderRegex = RegExp(r'^\{\{([^}]+)\}\}$');
  static final _placeholderRegex = RegExp(r'\{\{([^}]+)\}\}');
  static final _commentRegex = RegExp(r'\{\{!.*?\}\}', dotAll: true);
  static final _includeRegex = RegExp(r'^\{\{#include:(\*)?([^}]+)\}\}$');

  List<JsonCraftFormatter> _formatters = [];
  List<JsonCraftFunction> _functions = [];
  Map<String, JsonCraftFormatter> _formatterMap = {};

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
    // Construir map de formatadores para lookup O(1)
    _buildFormatterMap();
  }

  void _buildFormatterMap() {
    _formatterMap = {
      for (final formatter in _formatters) formatter.name: formatter
    };
  }

  String process(String jsonString, Map<String, dynamic> data,
      {Map<String, String>? templates}) {
    // Remove comments before processing
    final jsonWithoutComments = _removeComments(jsonString);

    // Convert JSON string to Dart object (Map or List)
    final decodedJson = json.decode(jsonWithoutComments);

    // Recursively replace placeholders
    final processedJson = _replacePlaceholdersRecursive(
      decodedJson,
      data,
      templates,
    );

    // Convert Dart object back to JSON string
    return json.encode(processedJson);
  }

  // Remove comments from JSON template string
  String _removeComments(String jsonString) {
    // Usa regex em cache para melhor performance
    return jsonString.replaceAll(_commentRegex, '');
  }

  // Recursive function to traverse JSON object and replace placeholders
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
            templates,
          ),
        );
      });
      return newMap;
    } else if (data is List) {
      // If it's a list, iterate over elements
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
    // If it's not string, map or list, return the data itself
    return data;
  }

  // Get value following a path in the context
  dynamic _getValueFromPath(String path, Map<String, dynamic> context) {
    // Handle implicit iterator (dot notation)
    if (path == '.') {
      // Return the current item if it exists in context
      if (context.containsKey('item')) {
        return context['item'];
      }
      return '';
    }

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

  // Check if the string is a complete placeholder
  bool _isCompletePlaceholder(String text) {
    return _completePlaceholderRegex.hasMatch(text);
  }

  // Get placeholder value preserving the original type
  dynamic _getPlaceholderValue(String text, Map<String, dynamic> context) {
    final match = _completePlaceholderRegex.firstMatch(text);

    if (match == null) {
      throw Exception('Invalid placeholder: $text');
    }

    final placeholder = match.group(1)!;

    // Parse placeholder de forma otimizada
    final parts = _parsePlaceholder(placeholder);
    final fieldPath = parts.fieldPath;
    final formatters = parts.formatters;

    dynamic currentValue = _getValueFromPath(fieldPath, context);

    if (currentValue == null) {
      throw Exception('Placeholder not found: $text');
    }

    // If there are formatters, apply them (result will always be string)
    if (formatters.isNotEmpty) {
      String result = currentValue?.toString() ?? '';
      for (final formatter in formatters) {
        result = _applyFormatter(result, formatter, context);
      }
      return result;
    }

    // If there are no formatters, return original value preserving type
    return currentValue;
  }

  // Classe auxiliar para parsing otimizado de placeholders
  _PlaceholderParts _parsePlaceholder(String placeholder) {
    final firstPipe = placeholder.indexOf('|');

    if (firstPipe == -1) {
      // Sem formatadores
      return _PlaceholderParts(placeholder.trim(), const []);
    }

    final fieldPath = placeholder.substring(0, firstPipe).trim();
    final formattersStr = placeholder.substring(firstPipe + 1);

    // Parsear formatadores de forma mais eficiente
    final formatters = <String>[];
    var start = 0;

    for (var i = 0; i < formattersStr.length; i++) {
      if (formattersStr[i] == '|' || i == formattersStr.length - 1) {
        final end = i == formattersStr.length - 1 ? i + 1 : i;
        final formatter = formattersStr.substring(start, end).trim();
        if (formatter.isNotEmpty) {
          formatters.add(formatter);
        }
        start = i + 1;
      }
    }

    return _PlaceholderParts(fieldPath, formatters);
  }

  // Function to replace placeholders in a single string
  String _replaceStringPlaceholders(String text, Map<String, dynamic> context) {
    return text.replaceAllMapped(_placeholderRegex, (match) {
      final placeholder = match.group(1); // e.g.: "data.name | pascalCase"
      if (placeholder == null) {
        throw Exception('Placeholder not found: ${match.group(0)!}');
      }

      // Parse placeholder de forma otimizada
      final parts = _parsePlaceholder(placeholder);
      final fieldPath = parts.fieldPath;
      final formatters = parts.formatters;

      // Get field value
      final currentValue = _getValueFromPath(fieldPath, context)?.toString();

      if (currentValue == null) {
        throw Exception('Placeholder not found: ${match.group(0)!}');
      }

      String result = currentValue;

      // Apply formatters in sequence
      for (final formatter in formatters) {
        result = _applyFormatter(result, formatter, context);
      }

      return result;
    });
  }

  // Apply a specific formatter to the value
  String _applyFormatter(
      String value, String formatter, Map<String, dynamic> context) {
    // Check if formatter has parameters (e.g.: "truncate(50)")
    String? parameter;
    final formatterParts = formatter.split('(');
    final formatterName = formatterParts[0];
    if (formatter.contains('(') && formatter.contains(')')) {
      parameter = formatterParts[1].replaceAll(')', '');
    }

    // Lookup O(1) usando map ao invés de firstWhere O(n)
    final targetFormatter = _formatterMap[formatterName] ??
        JsonCraftFormatter(
          name: 'identity',
          formatter: (value, param, getValue) => value,
        );

    // Apply the found formatter
    return targetFormatter.format(
      value,
      parameter,
      (value) => _getValueFromPath(value, context) ?? value,
    );
  }

  // Check if the key has an include ({{#include:id}} or {{#include:*path}})
  bool _isIncludePlaceholder(String text) {
    return _includeRegex.hasMatch(text);
  }

  // Get and process an included template
  dynamic _getIncludedTemplate(String text, Map<String, String>? templates,
      Map<String, dynamic> context) {
    if (templates == null) {
      throw Exception('Templates not provided for inclusion: $text');
    }

    final match = _includeRegex.firstMatch(text);

    if (match == null) {
      throw Exception('Invalid include syntax: $text');
    }

    final isDynamic = match.group(1) == '*';
    final templateIdOrPath = match.group(2)!;

    String templateId;

    if (isDynamic) {
      // Dynamic partial: resolve the template name from context
      final resolvedValue = _getValueFromPath(templateIdOrPath, context);

      if (resolvedValue == null || resolvedValue.toString().isEmpty) {
        throw Exception('Dynamic partial path resolved to null or empty: $templateIdOrPath');
      }

      templateId = resolvedValue.toString();
    } else {
      // Static partial: use the ID directly
      templateId = templateIdOrPath;
    }

    if (!templates.containsKey(templateId)) {
      throw Exception('Template not found: $templateId');
    }

    final templateString = templates[templateId]!;
    final decodedTemplate = json.decode(templateString);

    return _replacePlaceholdersRecursive(decodedTemplate, context, templates);
  }
}
