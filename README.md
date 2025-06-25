# 🎯 JsonCraft

[![MIT Licence](https://badges.frapsoft.com/os/mit/mit.svg?v=103)](https://opensource.org/licenses/mit-license.php)
[![pub package](https://img.shields.io/pub/v/json_craft.svg)](https://pub.dev/packages/json_craft)
![GitHub stars](https://img.shields.io/github/stars/RafaelBarbosatec/json_craft?style=flat)
[![pub points](https://img.shields.io/pub/points/json_craft?logo=dart)](https://pub.dev/packages/json_craft/score)

Um sistema poderoso e flexível para geração dinâmica de JSON usando templates com interpolação de variáveis, condicionais e formatadores.

## ✨ Características

- 🔗 **Interpolação de Variáveis**: Acesse dados aninhados com `{{data.campo}}`
- 🎛️ **Condicionais Inteligentes**: Inclua/exclua propriedades baseado em condições
- 🔄 **Formatadores Encadeáveis**: Transforme dados com sintaxe de pipe
- 📦 **Preservação de Tipos**: Mantém tipos originais (arrays, objetos, números)
- 🚫 **Negação**: Suporte a condições invertidas com `!`
- 🛡️ **Tratamento Robusto**: Lida graciosamente com valores nulos e inexistentes
- 🏗️ **Arquitetura Extensível**: Sistema de formatadores baseado em plugins

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

## 🧪 Testes

Execute os testes para verificar todas as funcionalidades:

```bash
flutter test
```

**Cobertura atual**: 25 testes passando ✅
- Interpolação básica e aninhada
- Condicionais e negação
- Todos os formatadores
- Encadeamento de formatadores
- Preservação de tipos
- Casos edge e tratamento de erros
- Arquitetura de formatadores extensível

## 📝 Licença

Este projeto está sob a licença MIT.

---

Criado com ❤️ usando Flutter e Dart