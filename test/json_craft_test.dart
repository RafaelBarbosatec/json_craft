import 'dart:convert';

import 'package:json_craft/json_craft.dart';
import 'package:test/test.dart';

void main() {
  group('JsonCraft', () {
    late Map<String, dynamic> testData;

    setUp(() {
      testData = {
        "data": {
          "user": {"name": "João", "email": "joao@example.com"},
          "notifications": 5,
          "products": [
            {"name": "Laptop", "price": 1200.00},
            {"name": "Mouse", "price": 25.00}
          ],
          "address": {"city": "São Paulo"},
        },
        "someOtherValue": "ignored"
      };
    });

    test('deve processar template JSON com placeholders válidos corretamente',
        () {
      // Arrange
      final jsonTemplate = '''
      {
        "title": "Welcome, {{data.user.name}}!",
        "message": "Your email is {{data.user.email}} and you have {{data.notifications}} new notifications.",
        "items": [
          {
            "id": 1,
            "name": "{{data.products.0.name}}",
            "price": "{{data.products.0.price}}"
          },
          {
            "id": 2,
            "name": "{{data.products.1.name}}",
            "price": "{{data.products.1.price}}"
          }
        ],
        "nestedData": {
          "city": "{{data.address.city}}"
        },
        "description": "This is a simple description."
      }
      ''';

      // Act
      final processedJson = JsonCraft().process(jsonTemplate, testData);
      final processedMap = json.decode(processedJson) as Map<String, dynamic>;

      // Assert
      expect(processedMap['title'], equals('Welcome, João!'));
      expect(
          processedMap['message'],
          equals(
              'Your email is joao@example.com and you have 5 new notifications.'));
      expect(
          processedMap['description'], equals('This is a simple description.'));

      // Verificar items array - agora preserva tipos originais para placeholders completos
      final items = processedMap['items'] as List;
      expect(items[0]['name'], equals('Laptop'));
      expect(items[0]['price'], equals(1200.0)); // Número, não string
      expect(items[1]['name'], equals('Mouse'));
      expect(items[1]['price'], equals(25.0)); // Número, não string

      // Verificar nested data
      final nestedData = processedMap['nestedData'] as Map<String, dynamic>;
      expect(nestedData['city'], equals('São Paulo'));
    });

    test('deve lançar exceção quando placeholder não existe', () {
      // Arrange
      final jsonTemplateWithError = '''
      {
        "title": "Welcome, {{data.user.nonexistent}}!"
      }
      ''';

      // Act & Assert
      expect(
        () => JsonCraft().process(jsonTemplateWithError, testData),
        throwsA(isA<Exception>()),
      );
    });

    test('deve lançar exceção quando índice do array está fora dos limites',
        () {
      // Arrange
      final jsonTemplateWithInvalidIndex = '''
      {
        "invalidProduct": "{{data.products.10.name}}"
      }
      ''';

      // Act & Assert
      expect(
        () => JsonCraft().process(jsonTemplateWithInvalidIndex, testData),
        throwsA(isA<Exception>()),
      );
    });

    test('deve processar placeholder com valor nulo como string vazia', () {
      // Arrange
      final dataWithNull = {
        "data": {
          "user": {"name": null}
        }
      };

      final jsonTemplate = '''
      {
        "title": "Welcome, {{data.user.name}}!"
      }
      ''';

      // Act
      final processedJson = JsonCraft().process(jsonTemplate, dataWithNull);
      final processedMap = json.decode(processedJson) as Map<String, dynamic>;

      // Assert
      expect(processedMap['title'], equals('Welcome, !'));
    });

    test('deve preservar tipo original em placeholders completos', () {
      // Arrange
      final jsonTemplate = '''
      {
        "products": "{{data.products}}",
        "notifications": "{{data.notifications}}",
        "user": "{{data.user}}"
      }
      ''';

      // Act
      final processedJson = JsonCraft().process(jsonTemplate, testData);
      final processedMap = json.decode(processedJson) as Map<String, dynamic>;

      // Assert
      expect(processedMap['products'], isA<List>());
      expect(processedMap['notifications'], equals(5));
      expect(processedMap['user'], isA<Map<String, dynamic>>());

      // Verificar conteúdo da lista
      final products = processedMap['products'] as List;
      expect(products.length, equals(2));
      expect(products[0]['name'], equals('Laptop'));
    });
  });

  group('JsonCraft - Condicionais', () {
    late Map<String, dynamic> conditionalData;

    setUp(() {
      conditionalData = {
        "data": {
          "user": {"name": "João", "email": "joao@example.com"},
          "showEmail": true,
          "showAddress": false,
          "isVip": true,
          "hasDiscount": false,
          "notifications": 5,
          "emptyNotifications": 0,
          "products": [
            {"name": "Laptop", "price": 1200.00}
          ],
          "emptyProducts": [],
          "address": {"city": "São Paulo"},
          "description": "Cliente premium",
          "emptyDescription": "",
          "vipLevel": null
        }
      };
    });

    test('deve incluir propriedade quando condicional booleana for verdadeira',
        () {
      // Arrange
      final jsonTemplate = '''
      {
        "userName": "{{data.user.name}}",
        "{{#if:data.showEmail}}userEmail": "{{data.user.email}}",
        "{{#if:data.isVip}}vipStatus": "Cliente VIP"
      }
      ''';

      // Act
      final processedJson = JsonCraft().process(jsonTemplate, conditionalData);
      final processedMap = json.decode(processedJson) as Map<String, dynamic>;

      // Assert
      expect(processedMap['userName'], equals('João'));
      expect(processedMap['userEmail'], equals('joao@example.com'));
      expect(processedMap['vipStatus'], equals('Cliente VIP'));
    });

    test('deve excluir propriedade quando condicional booleana for falsa', () {
      // Arrange
      final jsonTemplate = '''
      {
        "userName": "{{data.user.name}}",
        "{{#if:data.showAddress}}address": "{{data.address.city}}",
        "{{#if:data.hasDiscount}}discount": "10%"
      }
      ''';

      // Act
      final processedJson = JsonCraft().process(jsonTemplate, conditionalData);
      final processedMap = json.decode(processedJson) as Map<String, dynamic>;

      // Assert
      expect(processedMap['userName'], equals('João'));
      expect(processedMap.containsKey('address'), isFalse);
      expect(processedMap.containsKey('discount'), isFalse);
    });

    test('deve excluir propriedade quando condicional not exist', () {
      // Arrange
      final jsonTemplate = '''
      {
        "userName": "{{data.user.name}}",
        "{{#if:data.products.5}}product 5": "{{data.products.5.name}}"
      }
      ''';

      // Act
      final processedJson = JsonCraft().process(jsonTemplate, conditionalData);
      final processedMap = json.decode(processedJson) as Map<String, dynamic>;

      // Assert
      expect(processedMap.containsKey('product 5'), isFalse);
      expect(processedMap.containsKey('userName'), isTrue);
    });

    test('deve avaliar condicionais numéricas corretamente', () {
      // Arrange
      final jsonTemplate = '''
      {
        "userName": "{{data.user.name}}",
        "{{#if:data.notifications}}hasNotifications": "Sim",
        "{{#if:data.emptyNotifications}}noNotifications": "Não"
      }
      ''';

      // Act
      final processedJson = JsonCraft().process(jsonTemplate, conditionalData);
      final processedMap = json.decode(processedJson) as Map<String, dynamic>;

      // Assert
      expect(processedMap['userName'], equals('João'));
      expect(processedMap['hasNotifications'], equals('Sim')); // 5 é truthy
      expect(processedMap.containsKey('noNotifications'), isFalse); // 0 é falsy
    });

    test('deve avaliar condicionais de lista corretamente', () {
      // Arrange
      final jsonTemplate = '''
      {
        "userName": "{{data.user.name}}",
        "{{#if:data.products}}productsAvailable": "{{data.products}}",
        "{{#if:data.emptyProducts}}noProducts": "Nenhum produto"
      }
      ''';

      // Act
      final processedJson = JsonCraft().process(jsonTemplate, conditionalData);
      final processedMap = json.decode(processedJson) as Map<String, dynamic>;

      // Assert
      expect(processedMap['userName'], equals('João'));
      expect(processedMap['productsAvailable'],
          isA<List>()); // Lista não vazia é truthy
      expect(processedMap.containsKey('noProducts'),
          isFalse); // Lista vazia é falsy
    });

    test('deve avaliar condicionais de string corretamente', () {
      // Arrange
      final jsonTemplate = '''
      {
        "userName": "{{data.user.name}}",
        "{{#if:data.description}}hasDescription": "{{data.description}}",
        "{{#if:data.emptyDescription}}noDescription": "Sem descrição"
      }
      ''';

      // Act
      final processedJson = JsonCraft().process(jsonTemplate, conditionalData);
      final processedMap = json.decode(processedJson) as Map<String, dynamic>;

      // Assert
      expect(processedMap['userName'], equals('João'));
      expect(processedMap['hasDescription'],
          equals('Cliente premium')); // String não vazia é truthy
      expect(processedMap.containsKey('noDescription'),
          isFalse); // String vazia é falsy
    });

    test('deve avaliar condicionais de valores nulos corretamente', () {
      // Arrange
      final jsonTemplate = '''
      {
        "userName": "{{data.user.name}}",
        "{{#if:data.vipLevel}}vipLevel": "{{data.vipLevel}}",
        "{{#if:data.nonExistentField}}nonExistent": "Não existe"
      }
      ''';

      // Act
      final processedJson = JsonCraft().process(jsonTemplate, conditionalData);
      final processedMap = json.decode(processedJson) as Map<String, dynamic>;

      // Assert
      expect(processedMap['userName'], equals('João'));
      expect(processedMap.containsKey('vipLevel'), isFalse); // null é falsy
      expect(processedMap.containsKey('nonExistent'),
          isFalse); // campo inexistente é falsy
    });

    test('deve processar condicionais aninhadas corretamente', () {
      // Arrange
      final jsonTemplate = '''
      {
        "userName": "{{data.user.name}}",
        "{{#if:data.isVip}}vipInfo": {
          "status": "VIP",
          "{{#if:data.showEmail}}email": "{{data.user.email}}",
          "{{#if:data.hasDiscount}}discount": "Disponível"
        }
      }
      ''';

      // Act
      final processedJson = JsonCraft().process(jsonTemplate, conditionalData);
      final processedMap = json.decode(processedJson) as Map<String, dynamic>;

      // Assert
      expect(processedMap['userName'], equals('João'));
      expect(processedMap.containsKey('vipInfo'), isTrue);

      final vipInfo = processedMap['vipInfo'] as Map<String, dynamic>;
      expect(vipInfo['status'], equals('VIP'));
      expect(vipInfo['email'], equals('joao@example.com'));
      expect(vipInfo.containsKey('discount'), isFalse);
    });

    test('deve processar negação em condicionais corretamente', () {
      // Arrange
      final dadosParaNegacao = {
        "data": {
          "user": {"name": "Carlos"},
          "isActive": true,
          "isInactive": false,
          "hasProducts": true,
          "hasNoProducts": false,
          "emptyList": [],
          "filledList": [1, 2, 3],
          "emptyString": "",
          "filledString": "conteúdo",
          "zeroValue": 0,
          "positiveValue": 5,
          "nullValue": null
        }
      };

      final jsonTemplate = '''
      {
        "userName": "{{data.user.name}}",
        "{{#if:!data.isActive}}notActive": "Usuário inativo",
        "{{#if:!data.isInactive}}isActive": "Usuário ativo",
        "{{#if:!data.emptyList}}noEmptyList": "Lista não está vazia",
        "{{#if:!data.filledList}}noFilledList": "Lista está vazia",
        "{{#if:!data.emptyString}}noEmptyString": "String não está vazia",
        "{{#if:!data.filledString}}noFilledString": "String está vazia",
        "{{#if:!data.zeroValue}}notZero": "Valor não é zero",
        "{{#if:!data.positiveValue}}notPositive": "Valor não é positivo",
        "{{#if:!data.nullValue}}notNull": "Valor não é nulo",
        "{{#if:!data.nonExistentField}}notExists": "Campo não existe"
      }
      ''';

      // Act
      final processedJson = JsonCraft().process(jsonTemplate, dadosParaNegacao);
      final processedMap = json.decode(processedJson) as Map<String, dynamic>;

      // Assert
      expect(processedMap['userName'], equals('Carlos'));

      // Negação de valores truthy deve resultar em false (propriedade não incluída)
      expect(processedMap.containsKey('notActive'), isFalse); // !true = false
      expect(processedMap.containsKey('noFilledList'),
          isFalse); // ![1,2,3] = false
      expect(processedMap.containsKey('noFilledString'),
          isFalse); // !"conteúdo" = false
      expect(processedMap.containsKey('notPositive'), isFalse); // !5 = false

      // Negação de valores falsy deve resultar em true (propriedade incluída)
      expect(
          processedMap['isActive'], equals('Usuário ativo')); // !false = true
      expect(processedMap['noEmptyList'],
          equals('Lista não está vazia')); // ![] = true
      expect(processedMap['noEmptyString'],
          equals('String não está vazia')); // !"" = true
      expect(processedMap['notZero'], equals('Valor não é zero')); // !0 = true
      expect(
          processedMap['notNull'], equals('Valor não é nulo')); // !null = true
      expect(processedMap['notExists'],
          equals('Campo não existe')); // !undefined = true
    });

    test('deve processar negação com condicionais aninhadas', () {
      // Arrange
      final dadosAninhados = {
        "data": {
          "user": {"name": "Diana"},
          "showProfile": false,
          "hideProfile": true,
          "settings": {"notifications": false, "privacy": true}
        }
      };

      final jsonTemplate = '''
      {
        "userName": "{{data.user.name}}",
        "{{#if:!data.showProfile}}hiddenProfile": {
          "message": "Perfil oculto",
          "{{#if:!data.settings.notifications}}noNotifications": "Notificações desabilitadas",
          "{{#if:!data.settings.privacy}}noPrivacy": "Privacidade desabilitada"
        },
        "{{#if:!data.hideProfile}}visibleProfile": {
          "message": "Perfil visível"
        }
      }
      ''';

      // Act
      final processedJson = JsonCraft().process(jsonTemplate, dadosAninhados);
      final processedMap = json.decode(processedJson) as Map<String, dynamic>;

      // Assert
      expect(processedMap['userName'], equals('Diana'));

      // !showProfile (false) = true, então hiddenProfile deve existir
      expect(processedMap.containsKey('hiddenProfile'), isTrue);
      final hiddenProfile =
          processedMap['hiddenProfile'] as Map<String, dynamic>;
      expect(hiddenProfile['message'], equals('Perfil oculto'));
      expect(hiddenProfile['noNotifications'],
          equals('Notificações desabilitadas')); // !false = true
      expect(hiddenProfile.containsKey('noPrivacy'), isFalse); // !true = false

      // !hideProfile (true) = false, então visibleProfile não deve existir
      expect(processedMap.containsKey('visibleProfile'), isFalse);
    });

    test('deve combinar negação com condicionais múltiplas', () {
      // Arrange
      final dadosMultiplos = {
        "data": {
          "user": {"name": "Eduardo"},
          "isGuest": false,
          "hasPermissions": true,
          "isBlocked": false
        }
      };

      final jsonTemplate = '''
      {
        "userName": "{{data.user.name}}",
        "{{#if:!data.isGuest}} {{#if:data.hasPermissions}} {{#if:!data.isBlocked}} fullAccess": "Acesso completo liberado"
      }
      ''';

      // Act
      final processedJson = JsonCraft().process(jsonTemplate, dadosMultiplos);
      final processedMap = json.decode(processedJson) as Map<String, dynamic>;

      // Assert
      expect(processedMap['userName'], equals('Eduardo'));
      // !isGuest (false) = true && hasPermissions (true) = true && !isBlocked (false) = true
      // true && true && true = true
      expect(processedMap['fullAccess'], equals('Acesso completo liberado'));
    });

    test('deve tratar valores vazios como falsy corretamente', () {
      // Arrange
      final dadosComValoresVazios = {
        "data": {
          "user": {"name": "Pedro"},
          "emptyString": "", // String vazia → falsy
          "emptyList": [], // Lista vazia → falsy
          "emptyObject": {}, // Objeto vazio → falsy
          "nonEmptyString": "texto", // String não vazia → truthy
          "nonEmptyList": [1, 2], // Lista não vazia → truthy
          "nonEmptyObject": {"key": "value"} // Objeto não vazio → truthy
        }
      };

      final jsonTemplate = '''
      {
        "userName": "{{data.user.name}}",
        "{{#if:data.emptyString}}hasEmptyString": "Não deve aparecer",
        "{{#if:data.emptyList}}hasEmptyList": "Não deve aparecer",
        "{{#if:data.emptyObject}}hasEmptyObject": "Não deve aparecer",
        "{{#if:data.nonEmptyString}}hasNonEmptyString": "Deve aparecer",
        "{{#if:data.nonEmptyList}}hasNonEmptyList": "Deve aparecer",
        "{{#if:data.nonEmptyObject}}hasNonEmptyObject": "Deve aparecer"
      }
      ''';

      // Act
      final processedJson =
          JsonCraft().process(jsonTemplate, dadosComValoresVazios);
      final processedMap = json.decode(processedJson) as Map<String, dynamic>;

      // Assert
      expect(processedMap['userName'], equals('Pedro'));

      // Valores vazios devem ser falsy (propriedades não incluídas)
      expect(processedMap.containsKey('hasEmptyString'), isFalse);
      expect(processedMap.containsKey('hasEmptyList'), isFalse);
      expect(processedMap.containsKey('hasEmptyObject'), isFalse);

      // Valores não vazios devem ser truthy (propriedades incluídas)
      expect(processedMap['hasNonEmptyString'], equals('Deve aparecer'));
      expect(processedMap['hasNonEmptyList'], equals('Deve aparecer'));
      expect(processedMap['hasNonEmptyObject'], equals('Deve aparecer'));
    });

    test('deve preservar tipos originais em condicionais com valores vazios',
        () {
      // Arrange
      final dadosComValoresVazios = {
        "data": {
          "user": {"name": "Ana"},
          "emptyList": [],
          "emptyObject": {},
          "filledList": [
            {"item": "test"}
          ],
          "filledObject": {"prop": "value"}
        }
      };

      final jsonTemplate = '''
      {
        "userName": "{{data.user.name}}",
        "{{#if:data.filledList}}listData": "{{data.filledList}}",
        "{{#if:data.filledObject}}objectData": "{{data.filledObject}}",
        "{{#if:data.emptyList}}emptyListData": "{{data.emptyList}}",
        "{{#if:data.emptyObject}}emptyObjectData": "{{data.emptyObject}}"
      }
      ''';

      // Act
      final processedJson =
          JsonCraft().process(jsonTemplate, dadosComValoresVazios);
      final processedMap = json.decode(processedJson) as Map<String, dynamic>;

      // Assert
      expect(processedMap['userName'], equals('Ana'));

      // Valores preenchidos devem aparecer com tipos preservados
      expect(processedMap['listData'], isA<List>());
      expect(processedMap['objectData'], isA<Map<String, dynamic>>());

      // Valores vazios não devem aparecer
      expect(processedMap.containsKey('emptyListData'), isFalse);
      expect(processedMap.containsKey('emptyObjectData'), isFalse);
    });
  });

  group('JsonCraft - Formatadores', () {
    late Map<String, dynamic> formatterData;

    setUp(() {
      formatterData = {
        "data": {
          "name": "joão silva santos",
          "title": "desenvolvedor flutter",
          "company": "tech_company-name",
          "description":
              "Este é um texto muito longo que precisa ser truncado porque tem mais de cinquenta caracteres e pode causar problemas de layout",
          "code": "user-profile",
          "upperText": "TEXTO EM MAIÚSCULAS",
          "mixedText": "tExTo MiStUrAdO",
          "emptyText": "",
          "products": ["Produto A", "Produto B"],
          "welcome": "Bem vindo {name}"
        }
      };
    });

    test('deve aplicar formatadores de caso corretamente', () {
      // Arrange
      final jsonTemplate = '''
      {
        "pascalCase": "{{data.name | pascalCase}}",
        "camelCase": "{{data.name | camelCase}}",
        "snakeCase": "{{data.title | snakeCase}}",
        "kebabCase": "{{data.title | kebabCase}}",
        "titleCase": "{{data.name | titleCase}}",
        "sentenceCase": "{{data.upperText | sentenceCase}}",
        "upperCase": "{{data.name | upperCase}}",
        "lowerCase": "{{data.upperText | lowerCase}}"
      }
      ''';

      // Act
      final processedJson = JsonCraft().process(jsonTemplate, formatterData);
      final processedMap = json.decode(processedJson) as Map<String, dynamic>;

      // Assert
      expect(processedMap['pascalCase'], equals('JoãoSilvaSantos'));
      expect(processedMap['camelCase'], equals('joãoSilvaSantos'));
      expect(processedMap['snakeCase'], equals('desenvolvedor_flutter'));
      expect(processedMap['kebabCase'], equals('desenvolvedor-flutter'));
      expect(processedMap['titleCase'], equals('João Silva Santos'));
      expect(processedMap['sentenceCase'], equals('Texto em maiúsculas'));
      expect(processedMap['upperCase'], equals('JOÃO SILVA SANTOS'));
      expect(processedMap['lowerCase'], equals('texto em maiúsculas'));
    });

    test('deve aplicar formatadores de texto corretamente', () {
      // Arrange
      final jsonTemplate = '''
      {
        "capitalize": "{{data.name | capitalize}}",
        "truncateDefault": "{{data.description | truncate}}",
        "truncateCustom": "{{data.description | truncate(30)}}",
        "truncateShort": "{{data.name | truncate(50)}}"
      }
      ''';

      // Act
      final processedJson = JsonCraft().process(jsonTemplate, formatterData);
      final processedMap = json.decode(processedJson) as Map<String, dynamic>;

      // Assert
      expect(processedMap['capitalize'], equals('João silva santos'));
      expect(processedMap['truncateDefault'], contains('...'));
      expect(
          processedMap['truncateDefault'].length, equals(103)); // 100 + "..."
      expect(processedMap['truncateCustom'],
          equals('Este é um texto muito longo qu...'));
      expect(processedMap['truncateShort'],
          equals('joão silva santos')); // Não trunca pois é menor que 50
    });

    test('deve encadear múltiplos formatadores corretamente', () {
      // Arrange
      final jsonTemplate = '''
      {
        "chainedCase": "{{data.mixedText | lowerCase | titleCase}}",
        "chainedTruncate": "{{data.description | lowerCase | capitalize | truncate(40)}}",
        "tripleChain": "{{data.company | upperCase | lowerCase | pascalCase}}"
      }
      ''';

      // Act
      final processedJson = JsonCraft().process(jsonTemplate, formatterData);
      final processedMap = json.decode(processedJson) as Map<String, dynamic>;

      // Assert
      expect(processedMap['chainedCase'], equals('Texto Misturado'));
      expect(processedMap['chainedTruncate'],
          equals('Este é um texto muito longo que precisa ...'));
      expect(processedMap['tripleChain'], equals('TechCompanyName'));
    });

    test('deve aplicar formatadores em placeholders completos', () {
      // Arrange
      final jsonTemplate = '''
      {
        "formattedName": "{{data.name | titleCase}}",
        "rawProducts": "{{data.products}}",
        "formattedProducts": "{{data.products | upperCase}}"
      }
      ''';

      // Act
      final processedJson = JsonCraft().process(jsonTemplate, formatterData);
      final processedMap = json.decode(processedJson) as Map<String, dynamic>;

      // Assert
      expect(processedMap['formattedName'],
          equals('João Silva Santos')); // String formatada
      expect(processedMap['rawProducts'],
          isA<List>()); // Lista original preservada
      expect(processedMap['formattedProducts'],
          equals('[PRODUTO A, PRODUTO B]')); // String formatada
    });

    test('deve tratar formatadores inexistentes graciosamente', () {
      // Arrange
      final jsonTemplate = '''
      {
        "validFormatter": "{{data.name | upperCase}}",
        "invalidFormatter": "{{data.name | nonExistentFormatter}}",
        "mixedFormatters": "{{data.name | upperCase | invalidFormatter | lowerCase}}"
      }
      ''';

      // Act
      final processedJson = JsonCraft().process(jsonTemplate, formatterData);
      final processedMap = json.decode(processedJson) as Map<String, dynamic>;

      // Assert
      expect(processedMap['validFormatter'], equals('JOÃO SILVA SANTOS'));
      expect(processedMap['invalidFormatter'],
          equals('joão silva santos')); // Valor original
      expect(processedMap['mixedFormatters'],
          equals('joão silva santos')); // Aplica só os válidos
    });

    test('deve aplicar formatadores em strings mistas', () {
      // Arrange
      final jsonTemplate = '''
      {
        "greeting": "Olá, {{data.name | titleCase}}!",
        "profile": "{{data.name | pascalCase}} trabalha como {{data.title | titleCase}}",
        "code": "ID: {{data.code | upperCase | snakeCase}}"
      }
      ''';

      // Act
      final processedJson = JsonCraft().process(jsonTemplate, formatterData);
      final processedMap = json.decode(processedJson) as Map<String, dynamic>;

      // Assert
      expect(processedMap['greeting'], equals('Olá, João Silva Santos!'));
      expect(processedMap['profile'],
          equals('JoãoSilvaSantos trabalha como Desenvolvedor Flutter'));
      expect(processedMap['code'], equals('ID: user_profile'));
    });

    test('deve tratar valores vazios e nulos nos formatadores', () {
      // Arrange
      final emptyData = {
        "data": {"emptyString": "", "nullValue": null, "spaceString": "   "}
      };

      final jsonTemplate = '''
      {
        "emptyFormatted": "{{data.emptyString | upperCase}}",
        "nullFormatted": "{{data.nullValue | titleCase}}",
        "spaceFormatted": "{{data.spaceString | titleCase}}"
      }
      ''';

      // Act
      final processedJson = JsonCraft().process(jsonTemplate, emptyData);
      final processedMap = json.decode(processedJson) as Map<String, dynamic>;

      // Assert
      expect(processedMap['emptyFormatted'], equals(''));
      expect(processedMap['nullFormatted'], equals(''));
      expect(processedMap['spaceFormatted'],
          equals('   ')); // Espaços são preservados
    });

    test('deve aplicar formatadores com condicionais', () {
      // Arrange
      final jsonTemplate = '''
      {
        "{{#if:data.name}}formattedName": "{{data.name | titleCase}}",
        "{{#if:!data.emptyText}}hasContent": "{{data.description | truncate(20)}}"
      }
      ''';

      // Act
      final processedJson = JsonCraft().process(jsonTemplate, formatterData);
      final processedMap = json.decode(processedJson) as Map<String, dynamic>;

      // Assert
      expect(processedMap['formattedName'], equals('João Silva Santos'));
      expect(processedMap['hasContent'], equals('Este é um texto muit...'));
    });

    test('deve aplicar formatadores de substituição corretamente', () {
      // Arrange
      final jsonTemplate = '''
      {
        "welcome": "{{data.welcome | replace(name:data.name) | titleCase}}"
      }
      ''';

      // Act
      final processedJson = JsonCraft().process(jsonTemplate, formatterData);
      final processedMap = json.decode(processedJson) as Map<String, dynamic>;

      // Assert
      expect(processedMap['welcome'], equals('Bem Vindo João Silva Santos'));
    });
  });

  test('deve processar map corretamente', () {
    // Arrange
    final jsonTemplate = '''
    {
      "{{#map:data.users}}users": {
        "title":"{{translate.welcome}} {{item.name}} - {{item.idade}}"
      }
    }
    ''';

    final testData = {
      "translate": {"welcome": "Bem vindo"},
      "data": {
        "users": [
          {"name": "Rafael", "idade": 32},
          {"name": "Ana", "idade": 35}
        ]
      }
    };

    // Act
    final processedJson = JsonCraft().process(jsonTemplate, testData);
    final processedMap = json.decode(processedJson) as Map<String, dynamic>;

    // Assert
    expect(processedMap['users'], isA<List>());
    expect(processedMap['users'].length, equals(2));
    expect(
      processedMap['users'][0],
      equals({'title': 'Bem vindo Rafael - 32'}),
    );
    expect(
      processedMap['users'][1],
      equals({'title': 'Bem vindo Ana - 35'}),
    );
  });

  group('JsonCraft process with template inclusion', () {
    test('should include and process templates correctly', () {
      final jsonCraft = JsonCraft();

      final mainTemplate = json.encode(
          {'title': '{{title}}', 'content': '{{#include:subTemplate}}'});

      final subTemplate =
          json.encode({'subtitle': '{{subtitle}}', 'details': '{{details}}'});

      final templates = {'subTemplate': subTemplate};

      final data = {
        'title': 'Main Title',
        'subtitle': 'Sub Title',
        'details': 'Some details here.'
      };

      final result =
          jsonCraft.process(mainTemplate, data, templates: templates);

      final expected = json.encode({
        'title': 'Main Title',
        'content': {'subtitle': 'Sub Title', 'details': 'Some details here.'}
      });

      expect(result, equals(expected));
    });

    test('should throw an exception if template is missing', () {
      final jsonCraft = JsonCraft();

      final mainTemplate = json.encode(
          {'title': '{{title}}', 'content': '{{#include:missingTemplate}}'});

      final data = {'title': 'Main Title'};

      expect(() => jsonCraft.process(mainTemplate, data, templates: {}),
          throwsException);
    });

    test('use map and templates', () {
      // Arrange
      final jsonTemplate = '''
    {
      "{{#map:data.users}}users": "{{#include:itemTemplate}}"
    }
    ''';

      final itemTemplate = json.encode(
          {"title": "{{translate.welcome}} {{item.name}} - {{item.idade}}"});

      final testData = {
        "translate": {"welcome": "Bem vindo"},
        "data": {
          "users": [
            {"name": "Rafael", "idade": 32},
            {"name": "Ana", "idade": 35}
          ]
        }
      };

      // Act
      final processedJson = JsonCraft().process(
        jsonTemplate,
        testData,
        templates: {
          'itemTemplate': itemTemplate,
        },
      );
      final processedMap = json.decode(processedJson) as Map<String, dynamic>;

      // Assert
      expect(processedMap['users'], isA<List>());
      expect(processedMap['users'].length, equals(2));
      expect(
          processedMap['users'][0], equals({'title': 'Bem vindo Rafael - 32'}));
      expect(processedMap['users'][1], equals({'title': 'Bem vindo Ana - 35'}));
    });
  });
}
