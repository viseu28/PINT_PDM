// Teste da API para verificar se as datas de submissão estão sendo retornadas
const http = require('http');

function testarAPIQuizzes() {
  const options = {
    hostname: '192.168.1.68',
    port: 3000,
    path: '/quizzes/curso/3/8', // Curso 3, Utilizador 8
    method: 'GET',
    headers: {
      'Content-Type': 'application/json'
    }
  };

  const req = http.request(options, (res) => {
    let data = '';
    res.on('data', (chunk) => {
      data += chunk;
    });
    
    res.on('end', () => {
      try {
        const response = JSON.parse(data);
        
        console.log('📡 TESTE DA API - DATAS DE SUBMISSÃO');
        console.log('====================================');
        console.log(`Status: ${res.statusCode}`);
        console.log(`Success: ${response.success}`);
        
        if (response.success && response.data) {
          console.log(`\n📋 Quizzes encontrados: ${response.data.length}`);
          
          response.data.forEach((quiz, index) => {
            console.log(`\n${index + 1}. Quiz: "${quiz.titulo}"`);
            console.log(`   ID: ${quiz.id}`);
            console.log(`   Completo: ${quiz.completo}`);
            console.log(`   Nota: ${quiz.pontuacao}/20`);
            console.log(`   Tentativa: ${quiz.tentativa}`);
            console.log(`   Data de Submissão: ${quiz.data_submissao}`);
          });
        } else {
          console.log('❌ Resposta da API sem dados válidos');
        }
        
      } catch (e) {
        console.log('❌ Erro ao parsear resposta:', e.message);
        console.log('Resposta bruta:', data);
      }
    });
  });

  req.on('error', (e) => {
    console.log('❌ Erro na requisição:', e.message);
  });

  req.end();
}

testarAPIQuizzes();
