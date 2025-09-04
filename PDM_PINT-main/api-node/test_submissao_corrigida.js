const http = require('http');

function testarSubmissao() {
  console.log('🧪 Testando submissão de quiz corrigida...\n');
  
  // Simular as mesmas respostas que o usuário enviou
  const respostasUsuario = [
    {"resposta": "B", "pergunta_id": 0},  // B = índice 1
    {"resposta": "A", "pergunta_id": 1},  // A = índice 0  
    {"resposta": "A", "pergunta_id": 2}   // A = índice 0
  ];
  
  console.log('📝 Respostas enviadas:', respostasUsuario);
  
  const postData = JSON.stringify({
    id_utilizador: 8,  // Nome correto do parâmetro
    respostas: respostasUsuario
  });
  
  const options = {
    hostname: 'localhost',
    port: 3000,
    path: '/quizzes/19/submeter',  // Endpoint correto é 'submeter'
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(postData)
    }
  };
  
  const req = http.request(options, (res) => {
    let data = '';
    
    res.on('data', (chunk) => {
      data += chunk;
    });
    
    res.on('end', () => {
      try {
        const result = JSON.parse(data);
        console.log('\n📊 Resultado da submissão:', result);
        
        if (result.nota !== undefined) {
          console.log(`\n✅ Nota final: ${result.nota}/20`);
          console.log(`📈 Percentagem: ${(result.nota / 20 * 100).toFixed(1)}%`);
          
          // Verificar se o resultado está correto
          // Respostas corretas são todas 0, usuário respondeu [1,0,0], logo deveria ter 2/3 = 13.33/20
          const esperado = (2/3) * 20;
          console.log(`🎯 Nota esperada: ${esperado.toFixed(2)}/20`);
          
          if (Math.abs(result.nota - esperado) < 0.01) {
            console.log('🎉 SUCESSO! A correção funcionou!');
          } else {
            console.log('⚠️  A nota ainda não está correta...');
          }
        }
        
      } catch (error) {
        console.error('❌ Erro ao parsear resposta:', error.message);
        console.log('Raw response:', data);
      }
    });
  });
  
  req.on('error', (error) => {
    console.error('❌ Erro na requisição:', error.message, error.code);
  });
  
  req.write(postData);
  req.end();
}

testarSubmissao();
