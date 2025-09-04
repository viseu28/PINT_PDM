class ApiConfig {
  // Configurações de URL - ajuste conforme necessário:
  // - Para emulador Android: 10.0.2.2:3000
  // - Para dispositivo físico na mesma rede: IP da máquina (ex: 192.168.1.68:3000)
  // - Para teste local: localhost:3000
  static const String baseUrl = 'http://192.168.1.68:3000';
  
  // Endpoints específicos
  static const String authUrl = '$baseUrl/utilizadores';
  static const String cursosUrl = '$baseUrl/cursos';
  static const String notificacoesUrl = '$baseUrl/notificacoes';
  static const String comentariosUrl = '$baseUrl/comentarios';
  static const String favoritosUrl = '$baseUrl/favoritos';
  static const String inscricoesUrl = '$baseUrl/inscricoes';
  static const String forumUrl = '$baseUrl/forum';
  
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
