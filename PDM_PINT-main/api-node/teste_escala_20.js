// Teste para verificar notas na escala 0-20
const http = require('http');

function testarNotasEscala20() {
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
        
        console.log('📊 TESTE DAS NOTAS ESCALA 0-20');
        console.log('==============================');
        
        response.data.forEach((quiz, index) => {
          console.log(`\n📋 Quiz ${index + 1}: "${quiz.titulo}"`);
          console.log(`   Total de perguntas: ${quiz.total_perguntas}`);
          console.log(`   Completo: ${quiz.completo ? 'Sim' : 'Não'}`);
          
          if (quiz.completo && quiz.pontuacao !== null) {
            console.log(`   ✅ Nota: ${quiz.pontuacao}/20`);
            
            // Calcular que percentual isso representa
            const percentual = Math.round((quiz.pontuacao / 20) * 100);
            console.log(`   📊 Equivale a: ${percentual}%`);
            
            // Verificar faixa de qualidade
            if (quiz.pontuacao >= 16) {
              console.log(`   🟢 Excelente! (16-20)`);
            } else if (quiz.pontuacao >= 12) {
              console.log(`   🟡 Bom! (12-15)`);
            } else {
              console.log(`   🔴 Precisa melhorar (0-11)`);
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

console.log('🧪 Testando notas na escala 0-20...\n');
testarNotasEscala20();
