typedef JsonCraftFormatterFunction = dynamic Function(String value, String? param);

class JsonCraftFormatter {
  final String name;
  final JsonCraftFormatterFunction formatter;
  JsonCraftFormatter({
    required this.name,
    required this.formatter,
  });

  dynamic format(String value, String? param) {
    return formatter(value, param);
  }
}

abstract class DefaultJsonCraftFormatter {
  static List<JsonCraftFormatter> get defaultFormatters => [
        titleCase,
        lowerCase,
        pascalCase,
        camelCase,
        snakeCase,
        kebabCase,
        sentenceCase,
        upperCase,
        capitalize,
        truncate,
      ];

  static JsonCraftFormatter get titleCase => JsonCraftFormatter(
        name: 'titleCase',
        formatter: (value, param) {
          // Se a string for apenas espaços em branco, preserva como está
          if (value.trim().isEmpty) {
            return value;
          }

          return value
              .split(RegExp(r'[\s_-]+'))
              .where((word) => word.isNotEmpty) // Remove palavras vazias
              .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
              .join(' ');
        },
      );

  static JsonCraftFormatter get lowerCase => JsonCraftFormatter(
        name: 'lowerCase',
        formatter: (value, param) {
          return value.toLowerCase();
        },
      );

  static JsonCraftFormatter get upperCase => JsonCraftFormatter(
        name: 'upperCase',
        formatter: (value, param) {
          return value.toUpperCase();
        },
      );

  static JsonCraftFormatter get sentenceCase => JsonCraftFormatter(
        name: 'sentenceCase',
        formatter: (value, param) {
          if (value.isEmpty) return value;
          return value[0].toUpperCase() + value.substring(1).toLowerCase();
        },
      );

  static JsonCraftFormatter get capitalize => JsonCraftFormatter(
        name: 'capitalize',
        formatter: (value, param) {
          if (value.isEmpty) return value;
          return value[0].toUpperCase() + value.substring(1);
        },
      );

  static JsonCraftFormatter get pascalCase => JsonCraftFormatter(
        name: 'pascalCase',
        formatter: (value, param) {
          return value
              .split(RegExp(r'[\s_-]+'))
              .map((word) =>
                  word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1).toLowerCase())
              .join('');
        },
      );

  static JsonCraftFormatter get camelCase => JsonCraftFormatter(
        name: 'camelCase',
        formatter: (value, param) {
          final pascalCaseR = pascalCase.formatter(value, param);
          return pascalCaseR.isEmpty ? '' : pascalCaseR[0].toLowerCase() + pascalCaseR.substring(1);
        },
      );

  static JsonCraftFormatter get snakeCase => JsonCraftFormatter(
        name: 'snakeCase',
        formatter: (value, param) {
          // Primeiro converte espaços e hífens para underscore
          String result = value.replaceAll(RegExp(r'[\s-]+'), '_');

          // Depois adiciona underscore antes de letras maiúsculas
          result = result.replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (match) {
            return '${match.group(1)}_${match.group(2)}';
          });

          return result.toLowerCase().replaceAll(RegExp(r'^_+'), '').replaceAll(RegExp(r'_+'), '_');
        },
      );

  static JsonCraftFormatter get kebabCase => JsonCraftFormatter(
        name: 'kebabCase',
        formatter: (value, param) {
          // Primeiro converte espaços e underscores para hífen
          String result = value.replaceAll(RegExp(r'[\s_]+'), '-');

          // Depois adiciona hífen antes de letras maiúsculas
          result = result.replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (match) {
            return '${match.group(1)}-${match.group(2)}';
          });

          return result.toLowerCase().replaceAll(RegExp(r'^-+'), '').replaceAll(RegExp(r'-+'), '-');
        },
      );

  static JsonCraftFormatter get truncate => JsonCraftFormatter(
        name: 'truncate',
        formatter: (value, param) {
          final length = param != null ? int.tryParse(param) ?? 100 : 100;
          if (value.length <= length) return value;
          return '${value.substring(0, length)}...';
        },
      );
}
