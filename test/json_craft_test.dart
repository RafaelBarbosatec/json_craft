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

     test('deve processar data dentro de data', () {
      // Arrange
      final dataWithNull = {
        "data": {
          "user": {"name": '{{translate.tratamento}} Rafael'}
        },
        "translate": {
          "tratamento": "Sr."
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
      expect(processedMap['title'], equals('Welcome, Sr. Rafael!'));
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

  group('JsonCraft - Dot Notation (Implicit Iterator)', () {
    test('should iterate over primitive array with dot notation', () {
      // Arrange
      final jsonTemplate = '''
      {
        "{{#map:data.tags}}tagList": {
          "value": "{{.}}"
        }
      }
      ''';

      final testData = {
        "data": {
          "tags": ["JavaScript", "Dart", "Flutter"]
        }
      };

      // Act
      final processedJson = JsonCraft().process(jsonTemplate, testData);
      final processedMap = json.decode(processedJson) as Map<String, dynamic>;

      // Assert
      expect(processedMap['tagList'], isA<List>());
      expect(processedMap['tagList'].length, equals(3));
      expect(processedMap['tagList'][0], equals({'value': 'JavaScript'}));
      expect(processedMap['tagList'][1], equals({'value': 'Dart'}));
      expect(processedMap['tagList'][2], equals({'value': 'Flutter'}));
    });

    test('should apply formatters to dot notation', () {
      // Arrange
      final jsonTemplate = '''
      {
        "{{#map:data.tags}}tagList": {
          "original": "{{.}}",
          "uppercase": "{{. | upperCase}}",
          "titleCase": "{{. | titleCase}}"
        }
      }
      ''';

      final testData = {
        "data": {
          "tags": ["javascript", "dart"]
        }
      };

      // Act
      final processedJson = JsonCraft().process(jsonTemplate, testData);
      final processedMap = json.decode(processedJson) as Map<String, dynamic>;

      // Assert
      expect(processedMap['tagList'][0]['original'], equals('javascript'));
      expect(processedMap['tagList'][0]['uppercase'], equals('JAVASCRIPT'));
      expect(processedMap['tagList'][0]['titleCase'], equals('Javascript'));
    });

    test('should work with numbers in primitive array', () {
      // Arrange
      final jsonTemplate = '''
      {
        "{{#map:data.numbers}}numberList": {
          "value": "{{.}}"
        }
      }
      ''';

      final testData = {
        "data": {
          "numbers": [1, 2, 3, 4, 5]
        }
      };

      // Act
      final processedJson = JsonCraft().process(jsonTemplate, testData);
      final processedMap = json.decode(processedJson) as Map<String, dynamic>;

      // Assert
      expect(processedMap['numberList'].length, equals(5));
      // When using {{.}} with complete placeholder, type is preserved
      expect(processedMap['numberList'][0]['value'], equals(1));
      expect(processedMap['numberList'][2]['value'], equals(3));
    });

    test('should still work with object arrays using item notation', () {
      // Arrange
      final jsonTemplate = '''
      {
        "{{#map:data.users}}userList": {
          "name": "{{item.name}}",
          "age": "{{item.age}}"
        }
      }
      ''';

      final testData = {
        "data": {
          "users": [
            {"name": "Alice", "age": 30},
            {"name": "Bob", "age": 25}
          ]
        }
      };

      // Act
      final processedJson = JsonCraft().process(jsonTemplate, testData);
      final processedMap = json.decode(processedJson) as Map<String, dynamic>;

      // Assert
      expect(processedMap['userList'].length, equals(2));
      expect(processedMap['userList'][0]['name'], equals('Alice'));
      expect(processedMap['userList'][1]['age'], equals(25));
    });

    test('should support dot notation in mixed context with other placeholders', () {
      // Arrange
      final jsonTemplate = '''
      {
        "title": "{{translate.tags}}",
        "{{#map:data.tags}}tagList": {
          "tag": "{{.}}",
          "prefix": "{{translate.tagPrefix}}"
        }
      }
      ''';

      final testData = {
        "translate": {
          "tags": "Available Tags",
          "tagPrefix": "Tag:"
        },
        "data": {
          "tags": ["React", "Vue"]
        }
      };

      // Act
      final processedJson = JsonCraft().process(jsonTemplate, testData);
      final processedMap = json.decode(processedJson) as Map<String, dynamic>;

      // Assert
      expect(processedMap['title'], equals('Available Tags'));
      expect(processedMap['tagList'][0]['tag'], equals('React'));
      expect(processedMap['tagList'][0]['prefix'], equals('Tag:'));
      expect(processedMap['tagList'][1]['tag'], equals('Vue'));
    });
  });

  group('JsonCraft - Comments', () {
    test('should remove single-line comments from template', () {
      // Arrange
      final jsonTemplate = '''
      {
        "name": "{{data.name}}",
        {{! This is a comment that should be removed }}
        "age": "{{data.age}}"
      }
      ''';

      final testData = {
        "data": {"name": "John", "age": 30}
      };

      // Act
      final processedJson = JsonCraft().process(jsonTemplate, testData);
      final processedMap = json.decode(processedJson) as Map<String, dynamic>;

      // Assert
      expect(processedMap['name'], equals('John'));
      expect(processedMap['age'], equals(30));
    });

    test('should remove multi-line comments from template', () {
      // Arrange
      final jsonTemplate = '''
      {
        "title": "{{data.title}}",
        {{!
          This is a multi-line comment
          that spans multiple lines
          and should be completely removed
        }}
        "description": "{{data.description}}"
      }
      ''';

      final testData = {
        "data": {"title": "Hello", "description": "World"}
      };

      // Act
      final processedJson = JsonCraft().process(jsonTemplate, testData);
      final processedMap = json.decode(processedJson) as Map<String, dynamic>;

      // Assert
      expect(processedMap['title'], equals('Hello'));
      expect(processedMap['description'], equals('World'));
    });

    test('should remove multiple comments from template', () {
      // Arrange
      final jsonTemplate = '''
      {
        {{! First comment }}
        "field1": "{{data.field1}}",
        {{! Second comment }}
        "field2": "{{data.field2}}",
        {{! Third comment }}
        "field3": "{{data.field3}}"
      }
      ''';

      final testData = {
        "data": {"field1": "A", "field2": "B", "field3": "C"}
      };

      // Act
      final processedJson = JsonCraft().process(jsonTemplate, testData);
      final processedMap = json.decode(processedJson) as Map<String, dynamic>;

      // Assert
      expect(processedMap['field1'], equals('A'));
      expect(processedMap['field2'], equals('B'));
      expect(processedMap['field3'], equals('C'));
    });

    test('should handle comments mixed with placeholders', () {
      // Arrange
      final jsonTemplate = '''
      {
        "user": {
          {{! User name field }}
          "name": "{{data.user.name}}",
          {{! User email - this is important }}
          "email": "{{data.user.email}}"
        },
        {{! Product section }}
        "products": "{{data.products}}"
      }
      ''';

      final testData = {
        "data": {
          "user": {"name": "Alice", "email": "alice@test.com"},
          "products": ["Item1", "Item2"]
        }
      };

      // Act
      final processedJson = JsonCraft().process(jsonTemplate, testData);
      final processedMap = json.decode(processedJson) as Map<String, dynamic>;

      // Assert
      expect(processedMap['user']['name'], equals('Alice'));
      expect(processedMap['user']['email'], equals('alice@test.com'));
      expect(processedMap['products'], isA<List>());
    });

    test('should not confuse comments with regular placeholders', () {
      // Arrange
      final jsonTemplate = '''
      {
        {{! This is a comment }}
        "data": "{{data.value}}",
        "exclamation": "{{data.exclamation}}"
      }
      ''';

      final testData = {
        "data": {"value": "test", "exclamation": "Hello!"}
      };

      // Act
      final processedJson = JsonCraft().process(jsonTemplate, testData);
      final processedMap = json.decode(processedJson) as Map<String, dynamic>;

      // Assert
      expect(processedMap['data'], equals('test'));
      expect(processedMap['exclamation'], equals('Hello!'));
    });
  });

  group('JsonCraft - Context Change (With)', () {
    test('should change context with {{#with}} for simple object', () {
      // Arrange
      final jsonTemplate = '''
      {
        "{{#with:data.user}}profile": {
          "name": "{{name}}",
          "email": "{{email}}",
          "age": "{{age}}"
        }
      }
      ''';

      final testData = {
        "data": {
          "user": {
            "name": "John Doe",
            "email": "john@example.com",
            "age": 30
          }
        }
      };

      // Act
      final processedJson = JsonCraft().process(jsonTemplate, testData);
      final processedMap = json.decode(processedJson) as Map<String, dynamic>;

      // Assert
      expect(processedMap['profile']['name'], equals('John Doe'));
      expect(processedMap['profile']['email'], equals('john@example.com'));
      expect(processedMap['profile']['age'], equals(30));
    });

    test('should apply formatters within context change', () {
      // Arrange
      final jsonTemplate = '''
      {
        "{{#with:data.user}}formattedProfile": {
          "upperName": "{{name | upperCase}}",
          "titleName": "{{name | titleCase}}",
          "truncatedBio": "{{bio | truncate:20}}"
        }
      }
      ''';

      final testData = {
        "data": {
          "user": {
            "name": "john doe",
            "bio": "This is a very long biography that needs to be truncated"
          }
        }
      };

      // Act
      final processedJson = JsonCraft().process(jsonTemplate, testData);
      final processedMap = json.decode(processedJson) as Map<String, dynamic>;

      // Assert
      expect(processedMap['formattedProfile']['upperName'], equals('JOHN DOE'));
      expect(processedMap['formattedProfile']['titleName'], equals('John Doe'));
      expect(processedMap['formattedProfile']['truncatedBio'],
          startsWith('This is a very long')); // Truncate adds ...
    });

    test('should support nested context change', () {
      // Arrange
      final jsonTemplate = '''
      {
        "{{#with:data.user}}userInfo": {
          "name": "{{name}}",
          "{{#with:address}}location": {
            "city": "{{city}}",
            "country": "{{country}}"
          }
        }
      }
      ''';

      final testData = {
        "data": {
          "user": {
            "name": "Alice",
            "address": {"city": "São Paulo", "country": "Brazil"}
          }
        }
      };

      // Act
      final processedJson = JsonCraft().process(jsonTemplate, testData);
      final processedMap = json.decode(processedJson) as Map<String, dynamic>;

      // Assert
      expect(processedMap['userInfo']['name'], equals('Alice'));
      expect(processedMap['userInfo']['location']['city'], equals('São Paulo'));
      expect(
          processedMap['userInfo']['location']['country'], equals('Brazil'));
    });

    test('should access parent context when field not found in with context',
        () {
      // Arrange
      final jsonTemplate = '''
      {
        "appName": "{{app.name}}",
        "{{#with:data.user}}userInfo": {
          "userName": "{{name}}",
          "appName": "{{app.name}}"
        }
      }
      ''';

      final testData = {
        "app": {"name": "MyApp"},
        "data": {
          "user": {"name": "Bob"}
        }
      };

      // Act
      final processedJson = JsonCraft().process(jsonTemplate, testData);
      final processedMap = json.decode(processedJson) as Map<String, dynamic>;

      // Assert
      expect(processedMap['appName'], equals('MyApp'));
      expect(processedMap['userInfo']['userName'], equals('Bob'));
      expect(processedMap['userInfo']['appName'],
          equals('MyApp')); // Falls back to parent context
    });

    test('should work with multiple separate with blocks', () {
      // Arrange
      final jsonTemplate = '''
      {
        "{{#with:data.customer}}customerData": {
          "name": "{{name}}",
          "email": "{{email}}"
        },
        "{{#with:data.manager}}managerData": {
          "name": "{{name}}",
          "email": "{{email}}"
        }
      }
      ''';

      final testData = {
        "data": {
          "customer": {"name": "Customer One", "email": "customer@test.com"},
          "manager": {"name": "Manager One", "email": "manager@test.com"}
        }
      };

      // Act
      final processedJson = JsonCraft().process(jsonTemplate, testData);
      final processedMap = json.decode(processedJson) as Map<String, dynamic>;

      // Assert
      expect(processedMap['customerData']['name'], equals('Customer One'));
      expect(
          processedMap['customerData']['email'], equals('customer@test.com'));
      expect(processedMap['managerData']['name'], equals('Manager One'));
      expect(processedMap['managerData']['email'], equals('manager@test.com'));
    });

    test('should combine with and if conditionals', () {
      // Arrange
      final jsonTemplate = '''
      {
        "{{#with:data.user}}userProfile": {
          "name": "{{name}}",
          "{{#if:isPremium}}premiumBadge": "VIP Member",
          "{{#if:!isGuest}}accountType": "Registered"
        }
      }
      ''';

      final testData = {
        "data": {
          "user": {"name": "Premium User", "isPremium": true, "isGuest": false}
        }
      };

      // Act
      final processedJson = JsonCraft().process(jsonTemplate, testData);
      final processedMap = json.decode(processedJson) as Map<String, dynamic>;

      // Assert
      expect(processedMap['userProfile']['name'], equals('Premium User'));
      expect(processedMap['userProfile']['premiumBadge'], equals('VIP Member'));
      expect(processedMap['userProfile']['accountType'], equals('Registered'));
    });

    test('should throw exception if with path not found', () {
      // Arrange
      final jsonTemplate = '''
      {
        "{{#with:data.nonExistent}}profile": {
          "name": "{{name}}"
        }
      }
      ''';

      final testData = {
        "data": {"user": {"name": "John"}}
      };

      // Act & Assert
      expect(
        () => JsonCraft().process(jsonTemplate, testData),
        throwsA(isA<Exception>()),
      );
    });

    test('should throw exception if with context is not a Map', () {
      // Arrange
      final jsonTemplate = '''
      {
        "{{#with:data.tags}}profile": {
          "value": "{{name}}"
        }
      }
      ''';

      final testData = {
        "data": {
          "tags": ["tag1", "tag2"]
        }
      };

      // Act & Assert
      expect(
        () => JsonCraft().process(jsonTemplate, testData),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('JsonCraft - Dynamic Partials', () {
    test('should resolve dynamic partial from data', () {
      // Arrange
      final mainTemplate = json.encode({
        'title': '{{title}}',
        'content': '{{#include:*data.templateType}}'
      });

      final userTemplate = json.encode({
        'userInfo': 'User: {{data.name}}'
      });

      final adminTemplate = json.encode({
        'adminInfo': 'Admin: {{data.name}}'
      });

      final templates = {
        'userTemplate': userTemplate,
        'adminTemplate': adminTemplate,
      };

      // Act - User scenario
      final userData = {
        'title': 'User Page',
        'data': {'templateType': 'userTemplate', 'name': 'John'}
      };
      final userResult = JsonCraft().process(mainTemplate, userData, templates: templates);
      final userMap = json.decode(userResult) as Map<String, dynamic>;

      // Act - Admin scenario
      final adminData = {
        'title': 'Admin Page',
        'data': {'templateType': 'adminTemplate', 'name': 'Alice'}
      };
      final adminResult = JsonCraft().process(mainTemplate, adminData, templates: templates);
      final adminMap = json.decode(adminResult) as Map<String, dynamic>;

      // Assert
      expect(userMap['title'], equals('User Page'));
      expect(userMap['content']['userInfo'], equals('User: John'));

      expect(adminMap['title'], equals('Admin Page'));
      expect(adminMap['content']['adminInfo'], equals('Admin: Alice'));
    });

    test('should work with dynamic partials in map iteration', () {
      // Arrange
      final mainTemplate = json.encode({
        '{{#map:data.widgets}}widgetList': '{{#include:*item.type}}'
      });

      final buttonWidget = json.encode({
        'button': '{{item.label}}'
      });

      final textWidget = json.encode({
        'text': '{{item.content}}'
      });

      final templates = {
        'buttonWidget': buttonWidget,
        'textWidget': textWidget,
      };

      final data = {
        'data': {
          'widgets': [
            {'type': 'buttonWidget', 'label': 'Click Me'},
            {'type': 'textWidget', 'content': 'Hello World'},
            {'type': 'buttonWidget', 'label': 'Submit'},
          ]
        }
      };

      // Act
      final result = JsonCraft().process(mainTemplate, data, templates: templates);
      final resultMap = json.decode(result) as Map<String, dynamic>;

      // Assert
      expect(resultMap['widgetList'], isA<List>());
      expect(resultMap['widgetList'].length, equals(3));
      expect(resultMap['widgetList'][0]['button'], equals('Click Me'));
      expect(resultMap['widgetList'][1]['text'], equals('Hello World'));
      expect(resultMap['widgetList'][2]['button'], equals('Submit'));
    });

    test('should support nested paths for dynamic partial resolution', () {
      // Arrange
      final mainTemplate = json.encode({
        'content': '{{#include:*config.theme.templateName}}'
      });

      final darkTheme = json.encode({
        'theme': 'dark',
        'background': '#000'
      });

      final templates = {'darkTheme': darkTheme};

      final data = {
        'config': {
          'theme': {
            'templateName': 'darkTheme'
          }
        }
      };

      // Act
      final result = JsonCraft().process(mainTemplate, data, templates: templates);
      final resultMap = json.decode(result) as Map<String, dynamic>;

      // Assert
      expect(resultMap['content']['theme'], equals('dark'));
      expect(resultMap['content']['background'], equals('#000'));
    });

    test('should throw exception when dynamic partial path not found', () {
      // Arrange
      final mainTemplate = json.encode({
        'content': '{{#include:*data.nonExistent}}'
      });

      final templates = {'someTemplate': '{}'};
      final data = {'data': {}};

      // Act & Assert
      expect(
        () => JsonCraft().process(mainTemplate, data, templates: templates),
        throwsA(isA<Exception>()),
      );
    });

    test('should throw exception when resolved template does not exist', () {
      // Arrange
      final mainTemplate = json.encode({
        'content': '{{#include:*data.templateType}}'
      });

      final templates = {'existingTemplate': '{}'};
      final data = {
        'data': {'templateType': 'nonExistentTemplate'}
      };

      // Act & Assert
      expect(
        () => JsonCraft().process(mainTemplate, data, templates: templates),
        throwsA(isA<Exception>()),
      );
    });

    test('should work with dynamic partials and with context change', () {
      // Arrange
      final mainTemplate = json.encode({
        '{{#with:data.user}}userCard': '{{#include:*cardType}}'
      });

      final premiumCard = json.encode({
        'name': '{{name}}',
        'badge': 'Premium Member'
      });

      final basicCard = json.encode({
        'name': '{{name}}',
        'badge': 'Basic Member'
      });

      final templates = {
        'premiumCard': premiumCard,
        'basicCard': basicCard,
      };

      final data = {
        'data': {
          'user': {
            'name': 'John Doe',
            'cardType': 'premiumCard'
          }
        }
      };

      // Act
      final result = JsonCraft().process(mainTemplate, data, templates: templates);
      final resultMap = json.decode(result) as Map<String, dynamic>;

      // Assert
      expect(resultMap['userCard']['name'], equals('John Doe'));
      expect(resultMap['userCard']['badge'], equals('Premium Member'));
    });
  });

  group('JsonCraft process with template inclusion', () {
    test('should include and process templates correctly', () {
      final jsonCraft = JsonCraft();

      final mainTemplate = json.encode(
          {'title': '{{title}}', 'content': '{{#include:subTemplate}}'});

      final subTemplate =
          json.encode({'subtitle': '{{translate.welcome}} {{subtitle}}', 'details': '{{details}}'});

      final templates = {'subTemplate': subTemplate};

      final data = {
        'translate': {'welcome': 'Bem vindo'},
        'title': 'Main Title',
        'subtitle': 'Sub Title',
        'details': 'Some details here.'
      };

      final result =
          jsonCraft.process(mainTemplate, data, templates: templates);

      final expected = json.encode({
        'title': 'Main Title',
        'content': {'subtitle': 'Bem vindo Sub Title', 'details': 'Some details here.'}
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
