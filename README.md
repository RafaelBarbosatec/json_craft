# 🎯 JsonCraft

[![MIT Licence](https://badges.frapsoft.com/os/mit/mit.svg?v=103)](https://opensource.org/licenses/mit-license.php)
[![pub package](https://img.shields.io/pub/v/json_craft.svg)](https://pub.dev/packages/json_craft)
![GitHub stars](https://img.shields.io/github/stars/RafaelBarbosatec/json_craft?style=flat)
[![pub points](https://img.shields.io/pub/points/json_craft?logo=dart)](https://pub.dev/packages/json_craft/score)

Um sistema poderoso e flexível para geração dinâmica de JSON usando templates com interpolação de variáveis, condicionais e formatadores.

## ✨ Features

- 🔗 **Variable Interpolation**: Access nested data with `{{data.field}}`
- 🎛️ **Smart Conditionals**: Include/exclude properties based on conditions
- 🔄 **Chainable Formatters**: Transform data with pipe syntax
- 📦 **Type Preservation**: Maintains original types (arrays, objects, numbers)
- 🚫 **Negation**: Support for inverted conditions with `!`
- 🛡️ **Robust Handling**: Gracefully handles null and non-existent values
- 🏗️ **Extensible Architecture**: Plugin-based formatter system
- 💬 **Comments**: Document templates with `{{! comment }}` syntax
- 🔁 **Dot Notation**: Implicit iterator for primitive arrays with `{{.}}`
- 🔄 **Context Change**: Simplify templates with `{{#with:path}}`
- 🗺️ **Map Function**: Iterate over arrays to generate dynamic objects
- 📝 **Template Inclusion**: Modularize templates with `{{#include:id}}`
- 🎯 **Dynamic Partials**: Data-driven template selection with `{{#include:*path}}`

## 🚀 Instalação

```dart
import 'lib/json_craft.dart';

final processor = JsonCraft();
final resultado = processor.process(jsonTemplate, data);
```

## 📖 Guia de Uso

### 1. 🔗 Interpolação Básica

```dart
// Template
{
  "nome": "{{data.usuario.nome}}",
  "email": "{{data.usuario.email}}",
  "idade": "{{data.usuario.idade}}"
}

// Dados
{
  "data": {
    "usuario": {
      "nome": "João Silva",
      "email": "joao@email.com",
      "idade": 30
    }
  }
}

// Resultado
{
  "nome": "João Silva",
  "email": "joao@email.com", 
  "idade": 30
}
```

### 2. 🎛️ Condicionais

Use `{{#if:campo}}` para incluir propriedades condicionalmente:

```dart
// Template
{
  "nome": "{{data.nome}}",
  "{{#if:data.isVip}}beneficiosVip": ["Frete grátis", "Desconto especial"],
  "{{#if:data.temProdutos}}produtos": "{{data.produtos}}",
  "{{#if:!data.carrinhoVazio}}itensCarrinho": "{{data.carrinho}}"
}

// Dados
{
  "data": {
    "nome": "Ana",
    "isVip": true,
    "temProdutos": false,
    "carrinhoVazio": false,
    "carrinho": ["item1", "item2"]
  }
}

// Resultado
{
  "nome": "Ana",
  "beneficiosVip": ["Frete grátis", "Desconto especial"],
  "itensCarrinho": ["item1", "item2"]
}
```

#### 🔍 Avaliação de Condicionais

| Valor | `{{#if:campo}}` | `{{#if:!campo}}` |
|-------|-----------------|------------------|
| `true` | ✅ Inclui | ❌ Exclui |
| `false` | ❌ Exclui | ✅ Inclui |
| `""` (string vazia) | ❌ Exclui | ✅ Inclui |
| `[]` (array vazio) | ❌ Exclui | ✅ Inclui |
| `{}` (objeto vazio) | ❌ Exclui | ✅ Inclui |
| `null` | ❌ Exclui | ✅ Inclui |
| `0` | ❌ Exclui | ✅ Inclui |
| `"texto"` | ✅ Inclui | ❌ Exclui |
| `[1,2,3]` | ✅ Inclui | ❌ Exclui |
| `{"key":"value"}` | ✅ Inclui | ❌ Exclui |

### 3. 🔄 Formatadores

Use a sintaxe de pipe `|` para aplicar formatadores:

```dart
// Template
{
  "nomeFormatado": "{{data.nome | titleCase}}",
  "username": "{{data.nome | lowerCase | snakeCase}}",
  "resumo": "{{data.descricao | truncate:50}}"
}

// Dados
{
  "data": {
    "nome": "joão silva santos",
    "descricao": "Esta é uma descrição muito longa que precisa ser truncada..."
  }
}

// Resultado
{
  "nomeFormatado": "João Silva Santos",
  "username": "joão_silva_santos", 
  "resumo": "Esta é uma descrição muito longa que precisa ser tr..."
}
```

#### 📋 Formatadores Disponíveis

##### 🔤 Formatadores de Caso

| Formatador | Entrada | Saída | Descrição |
|------------|---------|-------|-----------|
| `pascalCase` | "joão silva" | "JoãoSilva" | PascalCase para classes |
| `camelCase` | "joão silva" | "joãoSilva" | camelCase para variáveis |
| `snakeCase` | "João Silva" | "joão_silva" | snake_case para APIs |
| `kebabCase` | "João Silva" | "joão-silva" | kebab-case para URLs |
| `titleCase` | "joão silva" | "João Silva" | Title Case para exibição |
| `sentenceCase` | "JOÃO SILVA" | "João silva" | Sentence case |
| `upperCase` | "joão" | "JOÃO" | MAIÚSCULAS |
| `lowerCase` | "JOÃO" | "joão" | minúsculas |
| `replace(name:data.name)` | "Bem vindo {name}" | "Bem vindo João Silva" | Substituição de valores |

##### ✏️ Formatadores de Texto

| Formatador | Entrada | Saída | Descrição |
|------------|---------|-------|-----------|
| `capitalize` | "joão silva" | "João silva" | Primeira letra maiúscula |
| `truncate` | "texto longo..." | "texto lon..." | Trunca em 100 chars (padrão) |
| `truncate:30` | "texto longo..." | "texto lon..." | Trunca em 30 chars |

### 4. 🔗 Encadeamento de Formatadores

Combine múltiplos formatadores em sequência:

```dart
// Template
{
  "processado": "{{data.texto | lowerCase | titleCase | truncate:20}}"
}

// Dados  
{
  "data": {
    "texto": "ESTE É UM TEXTO MUITO LONGO PARA DEMONSTRAÇÃO"
  }
}

// Resultado
{
  "processado": "Este É Um Texto Muit..."
}
```

### 5. 📦 Preservação de Tipos

```dart
// Template
{
  "produtosOriginais": "{{data.produtos}}",           // Mantém array
  "produtosFormatados": "{{data.produtos | upperCase}}", // Vira string
  "idadeOriginal": "{{data.idade}}",                  // Mantém número
  "idadeFormatada": "{{data.idade | upperCase}}"      // Vira string
}
```

### 6. 🏗️ Exemplo Completo

```dart
import 'dart:convert';
import 'lib/json_craft.dart';

void main() {
  final template = '''
  {
    "usuario": {
      "nome": "{{data.usuario.nomeCompleto | titleCase}}",
      "username": "{{data.usuario.nomeCompleto | lowerCase | snakeCase}}",
      "{{#if:data.usuario.isAdmin}}permissoes": "{{data.usuario.permissoes | upperCase}}"
    },
    "{{#if:data.produtos}}carrinho": {
      "total": "{{data.produtos.length}}",
      "primeiroProduto": "{{data.produtos.0.nome | titleCase}}",
      "resumo": "{{data.produtos.0.descricao | truncate:50}}"
    },
    "{{#if:!data.carrinhoVazio}}mensagem": "Carrinho vazio",
    "configuracoes": {
      "tema": "{{data.tema | capitalize}}",
      "idioma": "{{data.idioma | upperCase}}"
    }
  }
  ''';

  final dados = {
    "data": {
      "usuario": {
        "nomeCompleto": "maria silva santos",
        "isAdmin": true,
        "permissoes": "read write delete"
      },
      "produtos": [
        {
          "nome": "notebook gamer",
          "descricao": "Notebook para jogos com alta performance e qualidade excepcional"
        }
      ],
      "carrinhoVazio": false,
      "tema": "dark",
      "idioma": "pt-br"
    }
  };

  final processador = JsonCraft();
  final resultado = processador.process(template, dados);
  
  print(JsonEncoder.withIndent('  ').convert(json.decode(resultado)));
}
```

**Resultado:**
```json
{
  "usuario": {
    "nome": "Maria Silva Santos",
    "username": "maria_silva_santos",
    "permissoes": "READ WRITE DELETE"
  },
  "carrinho": {
    "total": 1,
    "primeiroProduto": "Notebook Gamer",
    "resumo": "Notebook para jogos com alta performance e qualid..."
  },
  "configuracoes": {
    "tema": "Dark",
    "idioma": "PT-BR"
  }
}
```

### 7. 💬 Comments

Use `{{! comment }}` to add comments to your templates that will be ignored during processing:

```dart
// Template
{
  {{! This is a single-line comment }}
  "name": "{{data.name}}",
  {{!
    This is a multi-line comment
    that can span multiple lines
    and will be completely removed
  }}
  "email": "{{data.email}}"
}

// Data
{
  "data": {
    "name": "John Doe",
    "email": "john@example.com"
  }
}

// Result
{
  "name": "John Doe",
  "email": "john@example.com"
}
```

#### 📝 Comment Features

- **Single-line comments**: `{{! This is a comment }}`
- **Multi-line comments**: Support comments that span multiple lines
- **Documentation**: Perfect for documenting complex templates
- **Clean output**: Comments are completely removed before processing

### 8. 🔁 Dot Notation (Implicit Iterator)

Use `{{.}}` to access the current item when iterating over arrays of primitives:

```dart
// Template
{
  "{{#map:data.tags}}tagList": {
    "value": "{{.}}",
    "uppercase": "{{. | upperCase}}"
  }
}

// Data
{
  "data": {
    "tags": ["javascript", "dart", "flutter"]
  }
}

// Result
{
  "tagList": [
    {"value": "javascript", "uppercase": "JAVASCRIPT"},
    {"value": "dart", "uppercase": "DART"},
    {"value": "flutter", "uppercase": "FLUTTER"}
  ]
}
```

#### 🔍 Dot Notation Features

- **Primitive arrays**: Works with arrays of strings, numbers, or booleans
- **Formatters**: Apply formatters to primitive values: `{{. | upperCase}}`
- **Backward compatible**: Existing `{{item.property}}` syntax still works for objects
- **Type preservation**: When used as complete placeholder, preserves number types

### 9. 🔄 Context Change (With)

Use `{{#with:path}}` to change the context and avoid repeating long paths:

```dart
// Template WITHOUT context change (repetitive)
{
  "userName": "{{data.user.name}}",
  "userEmail": "{{data.user.email}}",
  "userAge": "{{data.user.age}}",
  "userCity": "{{data.user.address.city}}"
}

// Template WITH context change (clean)
{
  "{{#with:data.user}}profile": {
    "userName": "{{name}}",
    "userEmail": "{{email}}",
    "userAge": "{{age}}",
    "userCity": "{{address.city}}"
  }
}

// Data
{
  "data": {
    "user": {
      "name": "John Doe",
      "email": "john@example.com",
      "age": 30,
      "address": {
        "city": "São Paulo"
      }
    }
  }
}

// Result
{
  "profile": {
    "userName": "John Doe",
    "userEmail": "john@example.com",
    "userAge": 30,
    "userCity": "São Paulo"
  }
}
```

#### 🎯 Context Change Features

- **Cleaner templates**: Avoid repeating long paths
- **Nested contexts**: Support for `{{#with}}` inside another `{{#with}}`
- **Parent context access**: Fields not found in new context fall back to parent
- **Works with formatters**: Apply formatters within the new context
- **Combines with other functions**: Use with `{{#if}}`, `{{#map}}`, etc.

#### Example: Nested Context

```dart
{
  "{{#with:data.company}}companyInfo": {
    "name": "{{name}}",
    "{{#with:employees.manager}}manager": {
      "name": "{{name}}",
      "{{#with:contact}}contact": {
        "email": "{{email}}",
        "phone": "{{phone}}"
      }
    }
  }
}
```

### 10. 🔄 Map

Use `{{#map:campo}}` para iterar sobre arrays e gerar objetos dinâmicos:

```dart
// Template
{
  "{{#map:data.usuarios}}usuarios": {
    "titulo": "{{translate.bemVindo}} {{item.nome}} - {{item.idade}}"
  }
}

// Dados
{
  "translate": {"bemVindo": "Bem vindo"},
  "data": {
    "usuarios": [
      {"nome": "Rafael", "idade": 32},
      {"nome": "Ana", "idade": 35}
    ]
  }
}

// Resultado
{
  "usuarios": [
    {"titulo": "Bem vindo Rafael - 32"},
    {"titulo": "Bem vindo Ana - 35"}
  ]
}
```

#### 🔍 Avaliação de Map

| Valor | `{{#map:campo}}` |
|-------|-----------------|
| `[]` (array vazio) | ❌ Exclui |
| `[1,2,3]` | ✅ Itera |

O `map` permite criar objetos dinâmicos baseados em arrays, com suporte a interpolação e formatadores.

### 8. 🎯 Dynamic Partials

Dynamic Partials allow you to choose which template to include **based on data**, making your templates truly data-driven!

#### Static Include (nome fixo)
```dart
{
  "content": "{{#include:userTemplate}}"  // Always uses "userTemplate"
}
```

#### Dynamic Include (nome vem dos dados)
```dart
// Template
{
  "card": "{{#include:*data.cardType}}"  // * indicates dynamic
}

// Data - Scenario 1
{
  "data": {
    "cardType": "userTemplate",
    "name": "John"
  }
}

// Data - Scenario 2
{
  "data": {
    "cardType": "adminTemplate",
    "name": "Alice"
  }
}
```

#### 🔥 Real-World Use Cases

**1. Multi-tenancy / White Label**
```dart
// Single template for all clients
{
  "branding": "{{#include:*client.themeTemplate}}"
}

// Each client can have different template
// Client A: themeTemplate = "clientA_theme"
// Client B: themeTemplate = "clientB_theme"
```

**2. Dynamic Components**
```dart
{
  "{{#map:data.widgets}}widgets": {
    "widget": "{{#include:*item.type}}"
  }
}

// Each widget uses its own template based on type
// buttonWidget, textWidget, imageWidget, etc.
```

**3. Dynamic Forms**
```dart
{
  "{{#map:data.fields}}formFields": {
    "field": "{{#include:*item.fieldType}}"
  }
}

// Different field types: inputField, selectField, checkboxField
```

#### 🎯 Benefits

- ✅ **Data-driven**: Template selection based on data
- ✅ **Zero conditionals**: No need for multiple `{{#if}}` statements
- ✅ **Scalable**: Add new templates without changing main template
- ✅ **Flexible**: Works with `{{#map}}`, `{{#with}}`, and all other features

### 9. 📦 Template Inclusion (Static)

Agora é possível incluir templates adicionais no processamento usando o placeholder especial `{{#include:id}}`. Isso permite modularizar e reutilizar partes do JSON.

#### Exemplo de Uso

```dart
// Template principal
{
  "titulo": "{{titulo}}",
  "conteudo": "{{#include:subTemplate}}"
}

// Template adicional
{
  "subtitulo": "{{subtitulo}}",
  "detalhes": "{{detalhes}}"
}

// Dados
{
  "titulo": "Título Principal",
  "subtitulo": "Subtítulo",
  "detalhes": "Alguns detalhes aqui."
}

// Resultado
{
  "titulo": "Título Principal",
  "conteudo": {
    "subtitulo": "Subtítulo",
    "detalhes": "Alguns detalhes aqui."
  }
}
```

#### Como Usar

Passe os templates adicionais como um mapa no método `process`:

```dart
final mainTemplate = json.encode({
  'titulo': '{{titulo}}',
  'conteudo': '{{#include:subTemplate}}'
});

final subTemplate = json.encode({
  'subtitulo': '{{subtitulo}}',
  'detalhes': '{{detalhes}}'
});

final templates = {
  'subTemplate': subTemplate
};

final data = {
  'titulo': 'Título Principal',
  'subtitulo': 'Subtítulo',
  'detalhes': 'Alguns detalhes aqui.'
};

final resultado = JsonCraft().process(mainTemplate, data, templates: templates);
print(resultado);
```

#### Tratamento de Erros

- **Template ausente**: Lança exceção se o template referenciado não for encontrado.
- **Placeholder inválido**: Lança exceção para sintaxe incorreta.

## 🎯 Casos de Uso

### 🏷️ Geração de Identificadores
```json
{
  "className": "{{data.nome | pascalCase}}",
  "variableName": "{{data.nome | camelCase}}",
  "apiEndpoint": "/{{data.nome | kebabCase}}",
  "dbField": "{{data.nome | snakeCase}}"
}
```

### 📄 Formatação de Conteúdo
```json
{
  "titulo": "{{data.artigo.titulo | titleCase}}",
  "resumo": "{{data.artigo.conteudo | truncate:150}}",
  "autor": "{{data.artigo.autor | titleCase}}",
  "tags": "{{data.artigo.tags | upperCase}}"
}
```

### 🔐 Configurações Condicionais
```json
{
  "{{#if:data.usuario.isPremium}}features": ["feature1", "feature2"],
  "{{#if:!data.usuario.isGuest}}profile": {
    "name": "{{data.usuario.nome | titleCase}}",
    "settings": "{{data.configuracoes}}"
  }
}
```

## 🏗️ Arquitetura Extensível

### Formatadores Customizados

Você pode criar seus próprios formatadores:

```dart
import 'lib/json_craft.dart';
import 'lib/json_craft_formatter.dart';

// Criar formatador customizado
final customFormatter = JsonCraftFormatter(
  name: 'reverse',
  formatter: (value, param) => value.split('').reversed.join(),
);

// Usar com formatadores customizados
final processor = JsonCraft(formatters: [customFormatter]);
final resultado = processor.process('{"reversed": "{{data.text | reverse}}"}', data);
```

### Sistema de Plugins

A arquitetura baseada em `JsonCraftFormatter` permite:
- ✅ **Formatadores customizados**
- ✅ **Extensibilidade fácil**
- ✅ **Reutilização de código**
- ✅ **Testes isolados**
- ✅ **Manutenibilidade**

## 🛡️ Tratamento de Erros

O sistema trata graciosamente:
- **Campos inexistentes**: Lança exceção com detalhes
- **Índices inválidos**: Lança exceção para arrays
- **Formatadores inexistentes**: Retorna valor original
- **Valores nulos**: Retorna string vazia
- **Condicionais inválidas**: Retorna `false`

## 🧪 Tests

Run tests to verify all functionalities:

```bash
flutter test
```

**Current coverage**: 55 tests passing ✅
- Basic and nested interpolation
- Conditionals and negation
- All formatters
- Formatter chaining
- Type preservation
- Edge cases and error handling
- Extensible formatter architecture
- Dot notation with primitive arrays
- Comments (single-line and multi-line)
- Context change with nested contexts
- Map function with arrays
- Template inclusion (static and dynamic)

## 📝 Licença

Este projeto está sob a licença MIT.

---

Criado com ❤️ usando Flutter e Dart