// Teste final para verificar se as notas estão corretas na API
const http = require('http');

function testarNotasAPI() {
  const options = {
    hostname: '192.168.1.68',
    port: 3000,
    path: '/quizzes/curso/3/8',
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
        
        console.log('📊 TESTE DAS NOTAS CORRIGIDAS');
        console.log('==============================');
        
        response.data.forEach((quiz, index) => {
          console.log(`\n📋 Quiz ${index + 1}: "${quiz.titulo}"`);
          console.log(`   Total de perguntas: ${quiz.total_perguntas}`);
          console.log(`   Completo: ${quiz.completo ? 'Sim' : 'Não'}`);
          
          if (quiz.completo && quiz.pontuacao !== null) {
            console.log(`   ✅ Pontuação: ${quiz.pontuacao}%`);
            
            // Verificar se a pontuação faz sentido (deve ser entre 0-100%)
            if (quiz.pontuacao >= 0 && quiz.pontuacao <= 100) {
              console.log(`   🎯 Nota CORRETA!`);
            } else {
              console.log(`   ❌ Nota incorreta! (${quiz.pontuacao}%)`);
            }
          } else {
            console.log(`   ⏳ Ainda não completado`);
          }
        });
        
      } catch (e) {
        console.log('❌ Erro ao parsear resposta:', e.message);
      }
    });
  });

  req.on('error', (e) => {
    console.error(`❌ Erro na requisição: ${e.message}`);
  });

  req.end();
}

console.log('🧪 Testando notas corrigidas na API...\n');
setTimeout(testarNotasAPI, 1000); // Aguardar 1 segundo para o servidor estar pronto
