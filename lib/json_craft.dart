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
    // Regex to match {{! ... }} comments (including multiline)
    final commentRegex = RegExp(r'\{\{!.*?\}\}', dotAll: true);
    return jsonString.replaceAll(commentRegex, '');
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

  // Regular expression to find placeholders
  static final _placeholderRegex = RegExp(r'\{\{([^}]+)\}\}');

  // Get value following a path in the context
  dynamic _getValueFromPath(String path, Map<String, dynamic> context,
      {int depth = 0, int maxDepth = 2}) {
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

    // Process placeholders in string values (recursive, with depth limit)
    if (currentValue is String &&
        depth < maxDepth &&
        _placeholderRegex.hasMatch(currentValue)) {
      currentValue =
          _replaceStringPlaceholders(currentValue, context, depth: depth + 1);
    }

    return currentValue ?? '';
  }

  // Check if the string is a complete placeholder
  bool _isCompletePlaceholder(String text) {
    final regex = RegExp(r'^\{\{([^}]+)\}\}$');
    return regex.hasMatch(text);
  }

  // Get placeholder value preserving the original type
  dynamic _getPlaceholderValue(String text, Map<String, dynamic> context,
      {int depth = 0}) {
    final regex = RegExp(r'^\{\{([^}]+)\}\}$');
    final match = regex.firstMatch(text);

    if (match == null) {
      throw Exception('Invalid placeholder: $text');
    }

    final placeholder = match.group(1)!;

    // Check if there are formatters (pipe |)
    final parts = placeholder.split('|');
    final fieldPath = parts[0].trim();
    final formatters = parts.skip(1).map((f) => f.trim()).toList();

    dynamic currentValue = _getValueFromPath(fieldPath, context, depth: depth);

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

  // Function to replace placeholders in a single string
  String _replaceStringPlaceholders(String text, Map<String, dynamic> context,
      {int depth = 0}) {
    // Regular expression to find "{{some.key | formatter}}"
    // Also captures optional formatters
    final regex = RegExp(r'\{\{([^}]+)\}\}');

    return text.replaceAllMapped(regex, (match) {
      final placeholder = match.group(1); // e.g.: "data.name | pascalCase"
      if (placeholder == null) {
        throw Exception('Placeholder not found: ${match.group(0)!}');
      }

      // Check if there are formatters (pipe |)
      final parts = placeholder.split('|');
      final fieldPath = parts[0].trim(); // e.g.: "data.name"
      final formatters = parts
          .skip(1)
          .map((f) => f.trim())
          .toList(); // e.g.: ["pascalCase", "upperCase"]

      // Get field value (with recursive placeholder processing)
      final currentValue =
          _getValueFromPath(fieldPath, context, depth: depth)?.toString();

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

    // Search for formatter in available formatters list
    final targetFormatter = _formatters.firstWhere(
      (f) => f.name == formatterName,
      orElse: () => JsonCraftFormatter(
        name: 'identity',
        formatter: (value, param, getValue) =>
            value, // Return original value if not found
      ),
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
    final regex = RegExp(r'^\{\{#include:(\*)?([^}]+)\}\}$');
    return regex.hasMatch(text);
  }

  // Get and process an included template
  dynamic _getIncludedTemplate(String text, Map<String, String>? templates,
      Map<String, dynamic> context) {
    if (templates == null) {
      throw Exception('Templates not provided for inclusion: $text');
    }

    final regex = RegExp(r'^\{\{#include:(\*)?([^}]+)\}\}$');
    final match = regex.firstMatch(text);

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
