/*
Vou explicar exatamente como o modelo organiza os dados vindos da base de dados.

Como funciona o fluxo dos dados:
1. Dados "crus" da Base de Dados
Quando fazes uma consulta à base de dados ou API, os dados chegam assim (formato JSON):

{
  "idutilizador": 123,
  "nome": "Francisco Silva",
  "email": "francisco@exemplo.com",
  "data_nascimento": "1990-05-15",
  "morada": "Rua das Flores, 45",
  "pontos": 250
}


2. O Modelo "Limpa" e Organiza
O UserModel pega nesses dados "crus" e transforma-os numa estrutura limpa e organizda:  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['idutilizador'] ?? json['id'] ?? 0,
      nome: json['nome'] ?? '',
      email: json['email'] ?? '',
      dataNascimento: json['datanascimento'] ?? json['data_nascimento'], // Aceita ambos os formatos
      morada: json['morada'],
      pontos: json['pontos'] ?? 0,
    );
  }


3. O que o Modelo faz de "limpeza":
A. Trata dados em falta:
Se a base de dados não tem pontos, o modelo usa 0 por defeito
Se não tem nome, usa uma string vazia em vez de quebrar a aplicação

B. Padroniza nomes:
Base de dados usa idutilizador → Modelo usa id (mais simples)
Base de dados usa data_nascimento → Modelo usa dataNascimento (estilo Dart)

C. Adiciona funcionalidades extra:

String get iniciais {
  if (nome.isEmpty) return '?';
  final parts = nome.split(' ');
  if (parts.length >= 2) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  return nome[0].toUpperCase();
}

Esta função pega no nome "Francisco Silva" e calcula automaticamente "FS" para mostrar no avatar.

4. Exemplo Prático:
Sem modelo (dados crus):

// Código confuso e propenso a erros
final nome = dadosDaBD['nome'] ?? 'Sem nome';
final pontos = dadosDaBD['pontos'] ?? 0;
final iniciais = nome.isNotEmpty ? nome[0] : '?';


Com modelo (dados organizados):

// Código limpo e seguro
final user = UserModel.fromJson(dadosDaBD);
final nome = user.nome;        // Sempre existe
final pontos = user.pontos;    // Sempre existe
final iniciais = user.iniciais; // Calculado automaticamente


5. Vantagens da Organização:
Segurança:
Nunca tens erros de "campo não existe"
Valores por defeito garantidos
Consistência:
Todos os utilizadores têm a mesma estrutura
Fácil de trabalhar em qualquer parte da aplicação
Manutenção:
Se a base de dados mudar, só mudas o modelo
O resto da aplicação continua a funcionar
Funcionalidades extra:
O modelo pode calcular coisas (como iniciais)
Pode validar dados antes de os guardar
Resumo:
SIM! O modelo organiza os dados depois de os ir buscar à base de dados. É como um "tradutor" que:

Recebe dados desorganizados da base de dados
Limpa e valida esses dados
Organiza numa estrutura consistente
Adiciona funcionalidades úteis
Entrega dados prontos a usar na interface
É como receber ingredientes soltos e transformá-los numa receita organizada!


NÃO se pode usar o mesmo modelo que esta na api-node porque:

Linguagens diferentes (JavaScript vs Dart)
Frameworks diferentes (Sequelize vs Flutter)
Objetivos diferentes (BD vs UI)
Segurança (backend tem dados sensíveis, frontend não)
Funcionalidades específicas de cada plataforma
*/


class UserModel {
  final int id;
  final String nome;
  final String email;
  final String? dataNascimento;
  final String? morada;
  final int pontos;
  final bool temQueAlterarPassword;

  UserModel({
    required this.id,
    required this.nome,
    required this.email,
    this.dataNascimento,
    this.morada,
    this.pontos = 0,
    this.temQueAlterarPassword = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['idutilizador'] ?? json['id'] ?? 0,
      nome: json['nome'] ?? '',
      email: json['email'] ?? '',
      dataNascimento: json['data_nascimento'],
      morada: json['morada'],
      pontos: json['pontos'] ?? 0,
      temQueAlterarPassword: json['temquealterarpassword'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idutilizador': id,
      'nome': nome,
      'email': email,
      'data_nascimento': dataNascimento,
      'morada': morada,
      'pontos': pontos,
      'temquealterarpassword': temQueAlterarPassword,
    };
  }

  String get iniciais {
    if (nome.isEmpty) return '?';
    final parts = nome.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return nome[0].toUpperCase();
  }
}
