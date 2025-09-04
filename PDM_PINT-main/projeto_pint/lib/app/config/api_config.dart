class ApiConfig {
  // URLs de desenvolvimento e produção
  static const String _localBaseUrl = 'http://192.168.1.68:3000';
  static const String _productionBaseUrl = 'https://pint-pdm.onrender.com';
  
  // Configuração automática de ambiente
  // Para build web (produção), usar URL do Render
  // Para desenvolvimento mobile, usar URL local
  static String get baseUrl {
    const bool isProduction = bool.fromEnvironment('dart.vm.product');
    return isProduction ? _productionBaseUrl : _localBaseUrl;
  }
  
  // Endpoints específicos
  static String get authUrl => '$baseUrl/utilizadores';
  static String get cursosUrl => '$baseUrl/cursos';
  static String get notificacoesUrl => '$baseUrl/notificacoes';
  static String get comentariosUrl => '$baseUrl/comentarios';
  static String get favoritosUrl => '$baseUrl/favoritos';
  static String get inscricoesUrl => '$baseUrl/inscricoes';
  static String get forumUrl => '$baseUrl/forum';
  static String get projetosUrl => '$baseUrl/projetos';
  static String get likesForumUrl => '$baseUrl/likes_forum';
  static String get respostasUrl => '$baseUrl/respostas';
  static String get denunciaUrl => '$baseUrl/denuncia';
  static String get fcmTokenUrl => '$baseUrl/fcm-token';
  static String get forumPedidosUrl => '$baseUrl/forum-pedidos';
  static String get permissoesUrl => '$baseUrl/permissoes';
  static String get healthUrl => '$baseUrl/health';
  
  // Configurações de timeout
  static const Duration timeout = Duration(seconds: 15);
  static const Duration shortTimeout = Duration(seconds: 8);
  
  // Headers padrão
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  // Método para obter headers com token
  static Map<String, String> getAuthHeaders(String token) {
    return {
      ...headers,
      'Authorization': 'Bearer $token',
    };
  }
}
