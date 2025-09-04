// Teste simples para o endpoint de quizzes
const http = require('http');

// Função para testar o endpoint
function testarQuizzes() {
  const options = {
    hostname: 'localhost',
    port: 3000,
    path: '/quizzes/curso/1/1', // Testando curso ID 1 para utilizador ID 1
    method: 'GET',
    headers: {
      'Content-Type': 'application/json'
    }
  };

  const req = http.request(options, (res) => {
    console.log(`Status: ${res.statusCode}`);
    console.log(`Headers: ${JSON.stringify(res.headers)}`);
    
    let data = '';
    res.on('data', (chunk) => {
      data += chunk;
    });
    
    res.on('end', () => {
      console.log('Resposta do servidor:');
      try {
        const response = JSON.parse(data);
        console.log(JSON.stringify(response, null, 2));
      } catch (e) {
        console.log('Resposta não é JSON válido:', data);
      }
    });
  });

  req.on('error', (e) => {
    console.error(`Erro na requisição: ${e.message}`);
  });

  req.end();
}

// Testar o endpoint
console.log('🧪 Testando endpoint de quizzes...');
testarQuizzes();
